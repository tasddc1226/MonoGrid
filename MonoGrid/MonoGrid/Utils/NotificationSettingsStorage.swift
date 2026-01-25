//
//  NotificationSettingsStorage.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import Foundation

/// Storage for notification settings using UserDefaults
/// Device-specific settings, not synced with iCloud
final class NotificationSettingsStorage {
    // MARK: - Singleton

    static let shared = NotificationSettingsStorage()

    // MARK: - Properties

    private let defaults: UserDefaults

    private enum Keys {
        static let isEnabled = "notification.isEnabled"
        static let scheduledHour = "notification.scheduledHour"
        static let scheduledMinute = "notification.scheduledMinute"
        static let hasRequestedPermission = "notification.hasRequestedPermission"
    }

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    // MARK: - Properties

    /// Whether notifications are enabled
    var isEnabled: Bool {
        get { defaults.bool(forKey: Keys.isEnabled) }
        set { defaults.set(newValue, forKey: Keys.isEnabled) }
    }

    /// Scheduled notification hour (0-23)
    /// Default: 20 (8:00 PM)
    var scheduledHour: Int {
        get {
            let hour = defaults.integer(forKey: Keys.scheduledHour)
            // Check if key exists to distinguish between explicit 0 and default
            return hour == 0 && !defaults.contains(key: Keys.scheduledHour) ? 20 : hour
        }
        set { defaults.set(newValue, forKey: Keys.scheduledHour) }
    }

    /// Scheduled notification minute (0-59)
    /// Default: 0
    var scheduledMinute: Int {
        get { defaults.integer(forKey: Keys.scheduledMinute) }
        set { defaults.set(newValue, forKey: Keys.scheduledMinute) }
    }

    /// Whether permission has been requested at least once
    var hasRequestedPermission: Bool {
        get { defaults.bool(forKey: Keys.hasRequestedPermission) }
        set { defaults.set(newValue, forKey: Keys.hasRequestedPermission) }
    }

    // MARK: - Convenience Properties

    /// Scheduled time as Date (for TimePicker binding)
    var scheduledTime: Date {
        get {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = scheduledHour
            components.minute = scheduledMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            scheduledHour = components.hour ?? 20
            scheduledMinute = components.minute ?? 0
        }
    }

    /// Formatted time string for display
    var formattedTime: String {
        scheduledTime.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - UserDefaults Extension

private extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
