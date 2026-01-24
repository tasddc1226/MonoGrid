//
//  SyncQueue.swift
//  MonoGrid
//
//  Created on 2026-01-24.
//

import Foundation

/// Thread-safe queue for tracking offline changes and managing sync retries
actor SyncQueue {
    // MARK: - Singleton

    static let shared = SyncQueue()

    // MARK: - Types

    struct PendingChange: Codable, Identifiable {
        let id: UUID
        let entityType: EntityType
        let entityId: UUID
        let changeType: ChangeType
        let timestamp: Date
        var retryCount: Int
        var lastError: String?

        enum EntityType: String, Codable {
            case habit
            case habitLog
        }

        enum ChangeType: String, Codable {
            case insert
            case update
            case delete
        }
    }

    // MARK: - Properties

    /// Pending changes list
    private var pendingChanges: [PendingChange] = []

    /// Maximum retry count
    private let maxRetryCount = 5

    /// UserDefaults storage key
    private let storageKey = "com.monogrid.syncqueue.pending"

    // MARK: - Initialization

    private init() {
        loadFromStorage()
    }

    // MARK: - Retry Interval

    /// Exponential backoff retry interval
    /// 1s, 2s, 4s, 8s, 16s...
    private func retryInterval(for retryCount: Int) -> TimeInterval {
        pow(2.0, Double(retryCount))
    }

    // MARK: - Queue Operations

    /// Add change to queue
    /// Replaces existing change for same entity (keeps latest only)
    func enqueue(_ change: PendingChange) {
        // Remove previous changes for same entity
        pendingChanges.removeAll {
            $0.entityType == change.entityType &&
            $0.entityId == change.entityId
        }

        pendingChanges.append(change)
        saveToStorage()

        // Update sync status
        Task { @MainActor in
            SyncStatusMonitor.shared.markPendingChanges()
        }
    }

    /// Remove successfully synced item
    func dequeue(_ changeId: UUID) {
        pendingChanges.removeAll { $0.id == changeId }
        saveToStorage()

        // Mark sync completed if queue is empty
        if pendingChanges.isEmpty {
            Task { @MainActor in
                SyncStatusMonitor.shared.markSyncCompleted()
            }
        }
    }

    /// Increment retry count for failed sync
    func incrementRetry(for changeId: UUID, error: String) {
        if let index = pendingChanges.firstIndex(where: { $0.id == changeId }) {
            pendingChanges[index].retryCount += 1
            pendingChanges[index].lastError = error

            // Remove if max retries exceeded (log permanent failure)
            if pendingChanges[index].retryCount >= maxRetryCount {
                logPermanentFailure(pendingChanges[index])
                pendingChanges.remove(at: index)
            }

            saveToStorage()
        }
    }

    /// Get all pending changes sorted by timestamp
    func getPendingChanges() -> [PendingChange] {
        pendingChanges.sorted { $0.timestamp < $1.timestamp }
    }

    /// Get changes ready for retry (based on backoff interval)
    func getRetryableChanges() -> [PendingChange] {
        let now = Date()
        return pendingChanges.filter { change in
            let interval = retryInterval(for: change.retryCount)
            let nextRetryDate = change.timestamp.addingTimeInterval(interval)
            return now >= nextRetryDate
        }.sorted { $0.timestamp < $1.timestamp }
    }

    /// Pending changes count
    var pendingCount: Int {
        pendingChanges.count
    }

    /// Check if queue is empty
    var isEmpty: Bool {
        pendingChanges.isEmpty
    }

    // MARK: - Persistence

    private func saveToStorage() {
        if let data = try? JSONEncoder().encode(pendingChanges) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let changes = try? JSONDecoder().decode([PendingChange].self, from: data) {
            pendingChanges = changes
        }
    }

    /// Clear all pending changes (for testing/reset)
    func clearAll() {
        pendingChanges.removeAll()
        saveToStorage()
    }

    // MARK: - Logging

    private func logPermanentFailure(_ change: PendingChange) {
        // Log permanent sync failure for analytics
        print("⚠️ Sync permanently failed for \(change.entityType.rawValue) \(change.entityId)")
        print("   Last error: \(change.lastError ?? "unknown")")
        // TODO: Send analytics event
    }
}

// MARK: - Convenience Factory Methods

extension SyncQueue.PendingChange {
    /// Create insert change
    static func insert(entityType: EntityType, entityId: UUID) -> Self {
        Self(
            id: UUID(),
            entityType: entityType,
            entityId: entityId,
            changeType: .insert,
            timestamp: Date(),
            retryCount: 0,
            lastError: nil
        )
    }

    /// Create update change
    static func update(entityType: EntityType, entityId: UUID) -> Self {
        Self(
            id: UUID(),
            entityType: entityType,
            entityId: entityId,
            changeType: .update,
            timestamp: Date(),
            retryCount: 0,
            lastError: nil
        )
    }

    /// Create delete change
    static func delete(entityType: EntityType, entityId: UUID) -> Self {
        Self(
            id: UUID(),
            entityType: entityType,
            entityId: entityId,
            changeType: .delete,
            timestamp: Date(),
            retryCount: 0,
            lastError: nil
        )
    }
}
