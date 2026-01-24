//
//  SyncStatusMonitor.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import Network
import Observation
import CloudKit
import SwiftUI

/// Monitors network connectivity, CloudKit availability, and sync status
@Observable
@MainActor
final class SyncStatusMonitor {
    // MARK: - Singleton

    static let shared = SyncStatusMonitor()

    // MARK: - Published Properties

    /// Network connection status
    private(set) var isConnected: Bool = true

    /// Pending changes exist
    private(set) var hasPendingChanges: Bool = false

    /// Currently syncing
    private(set) var isSyncing: Bool = false

    /// Sync error occurred
    private(set) var hasError: Bool = false

    /// Last error message
    private(set) var lastErrorMessage: String?

    /// iCloud account available
    private(set) var isCloudKitAvailable: Bool = false

    // MARK: - Persisted Properties

    /// Last sync date (App Group shared)
    var lastSyncDate: Date? {
        get { sharedDefaults?.object(forKey: Keys.lastSyncDate) as? Date }
        set { sharedDefaults?.set(newValue, forKey: Keys.lastSyncDate) }
    }

    // MARK: - Computed Properties

    /// Current sync status
    var syncStatus: SyncStatus {
        if !isCloudKitAvailable {
            return .unavailable
        } else if !isConnected {
            return .offline
        } else if hasError {
            return .error
        } else if isSyncing {
            return .syncing
        } else if hasPendingChanges {
            return .pending
        } else {
            return .synced
        }
    }

    /// Formatted last sync description
    var lastSyncDescription: String {
        guard let date = lastSyncDate else {
            return String(localized: "동기화되지 않음")
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Private Properties

    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.monogrid.syncmonitor")
    private var syncTimer: Timer?

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Constants.appGroupIdentifier)
    }

    private enum Keys {
        static let lastSyncDate = "lastSyncDate"
        static let syncErrorCount = "syncErrorCount"
    }

    // MARK: - Initialization

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
        Task {
            await checkCloudKitAvailability()
        }
    }

    deinit {
        monitor.cancel()
        // Note: syncTimer cleanup handled by Timer's invalidation on dealloc
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        // Network path monitoring
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasConnected = self?.isConnected ?? false
                self?.isConnected = path.status == .satisfied

                // Trigger sync when transitioning from offline to online
                if !wasConnected && path.status == .satisfied {
                    self?.triggerSync()
                }
            }
        }
        monitor.start(queue: monitorQueue)

        // Periodic sync check (every 5 minutes)
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPendingChanges()
            }
        }
    }

    /// Check CloudKit account availability
    func checkCloudKitAvailability() async {
        guard Constants.isCloudKitSyncEnabled else {
            isCloudKitAvailable = false
            return
        }

        do {
            let status = try await CKContainer(
                identifier: Constants.cloudKitContainerIdentifier
            ).accountStatus()

            await MainActor.run {
                self.isCloudKitAvailable = (status == .available)
            }
        } catch {
            await MainActor.run {
                self.isCloudKitAvailable = false
            }
        }
    }

    // MARK: - Status Update Methods

    /// Mark sync as completed
    func markSyncCompleted() {
        lastSyncDate = Date()
        hasPendingChanges = false
        isSyncing = false
        hasError = false
        lastErrorMessage = nil
    }

    /// Mark pending changes exist
    func markPendingChanges() {
        hasPendingChanges = true
    }

    /// Mark sync started
    func markSyncStarted() {
        isSyncing = true
        hasError = false
    }

    /// Mark sync error
    func markSyncError(_ message: String) {
        isSyncing = false
        hasError = true
        lastErrorMessage = message
    }

    /// Clear error state
    func clearError() {
        hasError = false
        lastErrorMessage = nil
    }

    // MARK: - Sync Trigger

    /// Trigger manual sync
    func triggerSync() {
        guard isConnected && isCloudKitAvailable else { return }

        Task.detached {
            await SyncEngine.shared.processQueue()
        }
    }

    // MARK: - Private Methods

    private func checkPendingChanges() {
        Task.detached { [weak self] in
            let count = await SyncQueue.shared.pendingCount
            await MainActor.run {
                self?.hasPendingChanges = count > 0
            }
        }
    }
}

// MARK: - Sync Status Enum (Enhanced)

enum SyncStatus: Equatable {
    case synced      // Sync completed
    case syncing     // Sync in progress
    case pending     // Pending changes
    case offline     // No network
    case error       // Sync error
    case unavailable // iCloud not available

    var description: String {
        switch self {
        case .synced:
            return String(localized: "동기화됨")
        case .syncing:
            return String(localized: "동기화 중...")
        case .pending:
            return String(localized: "동기화 대기 중")
        case .offline:
            return String(localized: "오프라인")
        case .error:
            return String(localized: "동기화 오류")
        case .unavailable:
            return String(localized: "iCloud 사용 불가")
        }
    }

    var iconName: String {
        switch self {
        case .synced:
            return "checkmark.icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .pending:
            return "arrow.clockwise.icloud"
        case .offline:
            return "icloud.slash"
        case .error:
            return "exclamationmark.icloud"
        case .unavailable:
            return "icloud.slash"
        }
    }

    var color: Color {
        switch self {
        case .synced:
            return .green
        case .syncing, .pending:
            return .blue
        case .offline:
            return .gray
        case .error, .unavailable:
            return .red
        }
    }

    /// Whether user can trigger manual sync
    var canTriggerSync: Bool {
        switch self {
        case .pending, .error:
            return true
        default:
            return false
        }
    }
}
