//
//  NotificationManager.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import UserNotifications
import SwiftUI
import UIKit

/// Message content for push notifications
struct NotificationMessage {
    let title: String
    let body: String
    let badgeCount: Int
}

/// Manager for local push notifications
/// Follows existing singleton pattern (HapticManager, ThemeManager)
@MainActor
final class NotificationManager: ObservableObject {
    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Properties

    private let center = UNUserNotificationCenter.current()
    private let storage = NotificationSettingsStorage.shared

    // MARK: - Published State

    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isScheduled: Bool = false

    // MARK: - Constants

    private enum NotificationID {
        static let dailyReminder = "com.monogrid.dailyReminder"
    }

    // MARK: - Initialization

    private init() {
        Task { await refreshPermissionStatus() }
    }

    // For testing purposes
    init(center: UNUserNotificationCenter, storage: NotificationSettingsStorage) {
        // This initializer allows dependency injection for testing
        Task { await refreshPermissionStatus() }
    }

    // MARK: - Permission

    /// Requests notification permission from the user
    /// - Returns: true if permission was granted
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await refreshPermissionStatus()
            storage.hasRequestedPermission = true

            // Auto-enable notifications when permission is granted
            if granted {
                storage.isEnabled = true
            }

            return granted
        } catch {
            print("알림 권한 요청 실패: \(error)")
            return false
        }
    }

    /// Refreshes the current permission status from the system
    func refreshPermissionStatus() async {
        let settings = await center.notificationSettings()
        permissionStatus = settings.authorizationStatus
    }

    // MARK: - Scheduling

    /// Schedules a daily notification at the specified time
    /// - Parameters:
    ///   - hour: Hour to send notification (0-23)
    ///   - minute: Minute to send notification (0-59)
    ///   - message: Notification content
    func scheduleDailyNotification(
        hour: Int,
        minute: Int,
        message: NotificationMessage
    ) async throws {
        // Cancel existing notification first
        center.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.dailyReminder]
        )

        // Create content
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.badge = NSNumber(value: message.badgeCount)
        content.userInfo = ["deepLink": "monogrid://today"]

        // Create trigger (daily repeat)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        // Create request
        let request = UNNotificationRequest(
            identifier: NotificationID.dailyReminder,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
        isScheduled = true
    }

    /// Cancels all scheduled notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        isScheduled = false
    }

    /// Clears the app badge count
    func clearBadge() async {
        if #available(iOS 16.0, *) {
            try? await center.setBadgeCount(0)
        } else {
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }

    // MARK: - Utility

    /// Checks if notification permission is granted
    var isPermissionGranted: Bool {
        permissionStatus == .authorized
    }

    /// Checks if permission was denied
    var isPermissionDenied: Bool {
        permissionStatus == .denied
    }
}
