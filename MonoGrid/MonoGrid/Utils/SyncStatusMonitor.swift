//
//  SyncStatusMonitor.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import Network
import Observation

/// Monitors network connectivity and sync status
@Observable
final class SyncStatusMonitor {
    // MARK: - Singleton

    static let shared = SyncStatusMonitor()

    // MARK: - Properties

    /// Whether the device is connected to the network
    private(set) var isConnected: Bool = true

    /// Last successful sync date
    var lastSyncDate: Date? {
        get {
            UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.lastSyncDate) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.UserDefaultsKeys.lastSyncDate)
        }
    }

    /// Whether there are pending changes to sync
    private(set) var hasPendingChanges: Bool = false

    /// Current sync status
    var syncStatus: SyncStatus {
        if !isConnected {
            return .offline
        } else if hasPendingChanges {
            return .syncing
        } else {
            return .synced
        }
    }

    // MARK: - Private

    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.monogrid.syncmonitor")

    // MARK: - Initialization

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Methods

    /// Marks that a sync has completed
    func markSyncCompleted() {
        lastSyncDate = Date()
        hasPendingChanges = false
    }

    /// Marks that there are changes waiting to sync
    func markPendingChanges() {
        hasPendingChanges = true
    }

    /// Returns a formatted string for the last sync time
    var lastSyncDescription: String {
        guard let date = lastSyncDate else {
            return String(localized: "동기화되지 않음")
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sync Status Enum

enum SyncStatus {
    case synced
    case syncing
    case offline
    case error

    var description: String {
        switch self {
        case .synced:
            return String(localized: "동기화됨")
        case .syncing:
            return String(localized: "동기화 중...")
        case .offline:
            return String(localized: "오프라인")
        case .error:
            return String(localized: "동기화 오류")
        }
    }

    var iconName: String {
        switch self {
        case .synced:
            return "checkmark.icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .offline:
            return "icloud.slash"
        case .error:
            return "exclamationmark.icloud"
        }
    }

    var color: String {
        switch self {
        case .synced:
            return "green"
        case .syncing:
            return "blue"
        case .offline:
            return "gray"
        case .error:
            return "red"
        }
    }
}
