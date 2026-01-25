//
//  AppNavigationState.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import SwiftUI
import UserNotifications

/// App-wide navigation state for handling deep links
@MainActor
@Observable
final class AppNavigationState {
    // MARK: - Deep Link Types

    enum DeepLink: Equatable {
        case today
        case settings
        case notificationSettings
    }

    // MARK: - Properties

    /// Pending deep link to be handled
    var pendingDeepLink: DeepLink?

    // MARK: - Methods

    /// Handles notification response and extracts deep link
    /// - Parameter response: The notification response from user interaction
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        guard let deepLink = response.notification.request.content.userInfo["deepLink"] as? String else {
            return
        }

        switch deepLink {
        case "monogrid://today":
            pendingDeepLink = .today
        case "monogrid://settings":
            pendingDeepLink = .settings
        case "monogrid://notification-settings":
            pendingDeepLink = .notificationSettings
        default:
            // Unknown deep link, ignore
            break
        }
    }

    /// Clears the pending deep link after it has been handled
    func clearDeepLink() {
        pendingDeepLink = nil
    }
}
