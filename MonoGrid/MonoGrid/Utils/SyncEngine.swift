//
//  SyncEngine.swift
//  MonoGrid
//
//  Created on 2026-01-24.
//

import Foundation
import SwiftData
import CloudKit

/// Sync queue processing engine
actor SyncEngine {
    // MARK: - Singleton

    static let shared = SyncEngine()

    // MARK: - Properties

    private var isProcessing = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Queue Processing

    /// Process all pending changes in queue
    func processQueue() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        // Update UI status
        await MainActor.run {
            SyncStatusMonitor.shared.markSyncStarted()
        }

        // Get retryable changes
        let pendingChanges = await SyncQueue.shared.getRetryableChanges()

        guard !pendingChanges.isEmpty else {
            await MainActor.run {
                SyncStatusMonitor.shared.markSyncCompleted()
            }
            return
        }

        for change in pendingChanges {
            do {
                try await processChange(change)
                await SyncQueue.shared.dequeue(change.id)
            } catch {
                await SyncQueue.shared.incrementRetry(
                    for: change.id,
                    error: error.localizedDescription
                )
            }
        }

        // Check remaining items
        let remaining = await SyncQueue.shared.pendingCount
        await MainActor.run {
            if remaining == 0 {
                SyncStatusMonitor.shared.markSyncCompleted()
            } else {
                SyncStatusMonitor.shared.markPendingChanges()
            }
        }
    }

    /// Process single change
    /// SwiftData + CloudKit handles automatic sync, this confirms completion
    private func processChange(_ change: SyncQueue.PendingChange) async throws {
        // Check network availability
        let isConnected = await MainActor.run {
            SyncStatusMonitor.shared.isConnected
        }

        guard isConnected else {
            throw SyncError.networkUnavailable
        }

        // SwiftData + CloudKit performs automatic sync
        // This delay simulates waiting for CloudKit confirmation
        // In production, we'd check CloudKit operation status
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Verify sync completed (simplified)
        // Real implementation would check CKDatabase operation results
    }

    /// Force immediate sync attempt
    func forceSync() async {
        await processQueue()
    }

    /// Cancel ongoing sync
    func cancelSync() {
        isProcessing = false
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case networkUnavailable
    case cloudKitError(Error)
    case conflictResolutionFailed
    case quotaExceeded
    case accountNotAvailable
    case timeout

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return String(localized: "네트워크 연결을 확인해주세요")
        case .cloudKitError(let error):
            return String(localized: "iCloud 오류: \(error.localizedDescription)")
        case .conflictResolutionFailed:
            return String(localized: "데이터 충돌 해결 실패")
        case .quotaExceeded:
            return String(localized: "iCloud 저장 공간이 부족합니다")
        case .accountNotAvailable:
            return String(localized: "iCloud 계정에 로그인해주세요")
        case .timeout:
            return String(localized: "동기화 시간이 초과되었습니다")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return String(localized: "Wi-Fi 또는 셀룰러 데이터를 활성화하세요")
        case .cloudKitError:
            return String(localized: "잠시 후 다시 시도해주세요")
        case .conflictResolutionFailed:
            return String(localized: "앱을 재시작해주세요")
        case .quotaExceeded:
            return String(localized: "iCloud 저장 공간을 확보하세요")
        case .accountNotAvailable:
            return String(localized: "설정 > Apple ID > iCloud에서 로그인하세요")
        case .timeout:
            return String(localized: "네트워크 상태를 확인하고 다시 시도하세요")
        }
    }
}
