//
//  FirstSyncHandler.swift
//  MonoGrid
//
//  Created on 2026-01-24.
//

import Foundation
import SwiftData

/// Handles first-time sync logic when user logs into iCloud
@MainActor
final class FirstSyncHandler {
    // MARK: - Singleton

    static let shared = FirstSyncHandler()

    // MARK: - Keys

    private enum Keys {
        static let hasCompletedFirstSync = "hasCompletedFirstSync"
        static let firstSyncTimestamp = "firstSyncTimestamp"
        static let lastKnownAccountID = "lastKnownAccountID"
    }

    // MARK: - Properties

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Constants.appGroupIdentifier)
    }

    /// Whether first sync has been completed
    var hasCompletedFirstSync: Bool {
        get { sharedDefaults?.bool(forKey: Keys.hasCompletedFirstSync) ?? false }
        set { sharedDefaults?.set(newValue, forKey: Keys.hasCompletedFirstSync) }
    }

    /// Timestamp of first sync
    var firstSyncTimestamp: Date? {
        get { sharedDefaults?.object(forKey: Keys.firstSyncTimestamp) as? Date }
        set { sharedDefaults?.set(newValue, forKey: Keys.firstSyncTimestamp) }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - First Sync Handling

    /// Handle first sync when iCloud becomes available
    /// - Returns: Result of the first sync operation
    @discardableResult
    func handleFirstSync() async -> FirstSyncResult {
        // Already completed first sync
        if hasCompletedFirstSync {
            return .alreadyCompleted
        }

        // Check if we have local data
        let hasLocalData = await checkLocalDataExists()

        // Check CloudKit availability
        guard SyncStatusMonitor.shared.isCloudKitAvailable else {
            return .cloudUnavailable
        }

        // Determine sync strategy based on local data
        if hasLocalData {
            // Local data exists - need to decide merge strategy
            // For now, we'll upload local data (local wins)
            await performMerge(strategy: .keepLocal)
            return .uploadedToCloud
        } else {
            // No local data - fresh start or download from cloud
            await performMerge(strategy: .downloadFromCloud)
            return .downloadedFromCloud
        }
    }

    /// Perform merge with specified strategy
    /// - Parameter strategy: The merge strategy to use
    func performMerge(strategy: MergeStrategy) async {
        SyncStatusMonitor.shared.markSyncStarted()

        do {
            switch strategy {
            case .keepLocal:
                // Push all local changes to cloud
                await uploadLocalData()

            case .keepCloud:
                // This would download cloud data and replace local
                // SwiftData + CloudKit handles this automatically
                break

            case .downloadFromCloud:
                // Wait for CloudKit to push data
                // SwiftData + CloudKit handles this automatically
                break

            case .mergeAll:
                // Use conflict resolver for each entity
                // This is handled by CloudKitConflictResolver
                await uploadLocalData()
            }

            // Mark first sync as complete
            hasCompletedFirstSync = true
            firstSyncTimestamp = Date()

            SyncStatusMonitor.shared.markSyncCompleted()

        } catch {
            SyncStatusMonitor.shared.markSyncError(
                String(localized: "첫 동기화 실패: \(error.localizedDescription)")
            )
        }
    }

    /// Reset first sync state (for testing or account switch)
    func resetFirstSyncState() {
        hasCompletedFirstSync = false
        firstSyncTimestamp = nil
        sharedDefaults?.removeObject(forKey: Keys.lastKnownAccountID)
    }

    // MARK: - Private Methods

    /// Check if local data exists
    private func checkLocalDataExists() async -> Bool {
        guard let context = SharedModelContainer.getSharedContext() else {
            return false
        }

        do {
            let descriptor = FetchDescriptor<Habit>()
            let habits = try context.fetch(descriptor)
            return !habits.isEmpty
        } catch {
            return false
        }
    }

    /// Upload local data to cloud via SyncQueue
    private func uploadLocalData() async {
        guard let context = SharedModelContainer.getSharedContext() else {
            return
        }

        do {
            // Enqueue all habits
            let habitDescriptor = FetchDescriptor<Habit>()
            let habits = try context.fetch(habitDescriptor)

            for habit in habits {
                let change = SyncQueue.PendingChange(
                    id: UUID(),
                    entityType: .habit,
                    entityId: habit.id,
                    changeType: .insert,
                    timestamp: Date(),
                    retryCount: 0
                )
                await SyncQueue.shared.enqueue(change)
            }

            // Enqueue all habit logs
            let logDescriptor = FetchDescriptor<HabitLog>()
            let logs = try context.fetch(logDescriptor)

            for log in logs {
                let change = SyncQueue.PendingChange(
                    id: UUID(),
                    entityType: .habitLog,
                    entityId: log.id,
                    changeType: .insert,
                    timestamp: Date(),
                    retryCount: 0
                )
                await SyncQueue.shared.enqueue(change)
            }

            // Process the queue
            await SyncEngine.shared.processQueue()

        } catch {
            // Error handled by SyncEngine
        }
    }
}

// MARK: - First Sync Result

/// Result of first sync operation
enum FirstSyncResult {
    /// First sync was already completed
    case alreadyCompleted

    /// Fresh start - no data anywhere
    case freshStart

    /// Downloaded data from cloud
    case downloadedFromCloud

    /// Uploaded local data to cloud
    case uploadedToCloud

    /// Merge was required and completed
    case mergeCompleted

    /// CloudKit is unavailable
    case cloudUnavailable

    var description: String {
        switch self {
        case .alreadyCompleted:
            return String(localized: "이미 동기화됨")
        case .freshStart:
            return String(localized: "새로 시작")
        case .downloadedFromCloud:
            return String(localized: "클라우드에서 다운로드됨")
        case .uploadedToCloud:
            return String(localized: "클라우드로 업로드됨")
        case .mergeCompleted:
            return String(localized: "데이터 병합 완료")
        case .cloudUnavailable:
            return String(localized: "클라우드 사용 불가")
        }
    }
}

// MARK: - Merge Strategy

/// Strategy for handling data merge during first sync
enum MergeStrategy {
    /// Keep local data, upload to cloud
    case keepLocal

    /// Keep cloud data, replace local
    case keepCloud

    /// Download from cloud (no local data)
    case downloadFromCloud

    /// Merge both using conflict resolution
    case mergeAll

    var description: String {
        switch self {
        case .keepLocal:
            return String(localized: "로컬 데이터 유지")
        case .keepCloud:
            return String(localized: "클라우드 데이터 유지")
        case .downloadFromCloud:
            return String(localized: "클라우드에서 다운로드")
        case .mergeAll:
            return String(localized: "모든 데이터 병합")
        }
    }
}
