//
//  CloudKitAccountObserver.swift
//  MonoGrid
//
//  Created on 2026-01-24.
//

import Foundation
import CloudKit
import Combine

/// Observes iCloud account changes and handles login/logout events
@MainActor
final class CloudKitAccountObserver: ObservableObject {
    // MARK: - Singleton

    static let shared = CloudKitAccountObserver()

    // MARK: - Published Properties

    /// Current iCloud account status
    @Published private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

    /// Show alert when account changed
    @Published var showAccountChangedAlert: Bool = false

    /// Alert message
    @Published var accountAlertMessage: String = ""

    // MARK: - Private Properties

    private var previousAccountStatus: CKAccountStatus = .couldNotDetermine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupObserver()
        Task {
            await checkAccountStatus()
        }
    }

    // MARK: - Setup

    private func setupObserver() {
        // Observe iCloud account changes
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleAccountChange()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Account Status

    /// Check current iCloud account status
    func checkAccountStatus() async {
        guard Constants.isCloudKitSyncEnabled else {
            accountStatus = .noAccount
            return
        }

        do {
            let status = try await CKContainer(
                identifier: Constants.cloudKitContainerIdentifier
            ).accountStatus()

            previousAccountStatus = accountStatus
            accountStatus = status

            // Update sync monitor
            await SyncStatusMonitor.shared.checkCloudKitAvailability()
        } catch {
            accountStatus = .couldNotDetermine
        }
    }

    // MARK: - Account Change Handling

    /// Handle iCloud account change notification
    private func handleAccountChange() async {
        let oldStatus = accountStatus
        await checkAccountStatus()
        let newStatus = accountStatus

        // Detect meaningful transitions
        if oldStatus == .available && newStatus != .available {
            // User logged out
            handleLogout()
        } else if oldStatus != .available && newStatus == .available {
            // User logged in or switched accounts
            handleNewLogin()
        }
    }

    /// Handle user logout from iCloud
    private func handleLogout() {
        accountAlertMessage = String(localized: "iCloud에서 로그아웃되었습니다. 동기화가 일시 중지됩니다.")
        showAccountChangedAlert = true

        // Clear sync state
        SyncStatusMonitor.shared.clearError()
    }

    /// Handle new iCloud login
    private func handleNewLogin() {
        accountAlertMessage = String(localized: "iCloud에 로그인되었습니다. 데이터를 동기화합니다.")
        showAccountChangedAlert = true

        // Trigger first sync check
        Task {
            await FirstSyncHandler.shared.handleFirstSync()
        }
    }

    // MARK: - Helpers

    /// Human-readable account status description
    var accountStatusDescription: String {
        switch accountStatus {
        case .available:
            return String(localized: "사용 가능")
        case .noAccount:
            return String(localized: "로그인 필요")
        case .restricted:
            return String(localized: "제한됨")
        case .couldNotDetermine:
            return String(localized: "확인 중...")
        case .temporarilyUnavailable:
            return String(localized: "일시적으로 사용 불가")
        @unknown default:
            return String(localized: "알 수 없음")
        }
    }

    /// Whether iCloud is available
    var isAvailable: Bool {
        accountStatus == .available
    }
}
