//
//  ReviewSettingsStorage.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import Foundation

/// Storage for app review request tracking data
/// Uses UserDefaults for local persistence (device-specific, not synced)
final class ReviewSettingsStorage {
    // MARK: - Singleton

    static let shared = ReviewSettingsStorage()

    // MARK: - Keys

    private enum Keys {
        static let installDate = "review_installDate"
        static let requestCount = "review_requestCount"
        static let lastRequestDate = "review_lastRequestDate"
        static let triggeredMilestones = "review_triggeredMilestones"
    }

    // MARK: - UserDefaults

    private let defaults: UserDefaults

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Install Date

    /// App install date (first recorded)
    var installDate: Date? {
        defaults.object(forKey: Keys.installDate) as? Date
    }

    /// Days elapsed since app install
    var daysSinceInstall: Int {
        guard let installDate = installDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
    }

    /// Records install date (only if not already set)
    func recordInstallDate() {
        if installDate == nil {
            defaults.set(Date(), forKey: Keys.installDate)
        }
    }

    // MARK: - Request Count

    /// Total review request count
    var requestCount: Int {
        defaults.integer(forKey: Keys.requestCount)
    }

    /// Increments request count and updates last request date
    func incrementRequestCount() {
        defaults.set(requestCount + 1, forKey: Keys.requestCount)
        defaults.set(Date(), forKey: Keys.lastRequestDate)
    }

    // MARK: - Last Request Date

    /// Last review request date
    var lastRequestDate: Date? {
        defaults.object(forKey: Keys.lastRequestDate) as? Date
    }

    // MARK: - Triggered Milestones

    /// Set of milestones that have triggered review requests
    var triggeredMilestones: Set<Int> {
        let array = defaults.array(forKey: Keys.triggeredMilestones) as? [Int] ?? []
        return Set(array)
    }

    /// Records a triggered milestone to prevent duplicate requests
    func recordTriggeredMilestone(_ milestone: Int) {
        var milestones = triggeredMilestones
        milestones.insert(milestone)
        defaults.set(Array(milestones), forKey: Keys.triggeredMilestones)
    }

    // MARK: - Reset (for testing)

    /// Resets all review data (primarily for testing purposes)
    func reset() {
        defaults.removeObject(forKey: Keys.installDate)
        defaults.removeObject(forKey: Keys.requestCount)
        defaults.removeObject(forKey: Keys.lastRequestDate)
        defaults.removeObject(forKey: Keys.triggeredMilestones)
    }
}
