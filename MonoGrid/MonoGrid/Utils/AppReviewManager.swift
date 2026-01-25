//
//  AppReviewManager.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import StoreKit
import SwiftUI
import UIKit

/// Manager for app store review requests
/// Follows Apple guidelines using SKStoreReviewController
@MainActor
final class AppReviewManager: ObservableObject {
    // MARK: - Singleton

    static let shared = AppReviewManager()

    // MARK: - Dependencies

    private let storage: ReviewSettingsStorage

    // MARK: - Published State

    /// Whether pre-confirmation dialog is showing
    @Published var showingPreConfirmation = false

    /// Current milestone being triggered
    @Published private(set) var currentMilestone: Int = 0

    /// Whether transition view is showing (after positive response)
    @Published var showingTransition = false

    // MARK: - Constants

    /// Valid streak milestones that trigger review requests
    private let reviewMilestones: Set<Int> = [7, 14, 30]

    /// Minimum days since install before showing review request
    private let minimumDaysSinceInstall = 3

    /// Delay before showing pre-confirmation dialog (seconds)
    private let preConfirmationDelay: TimeInterval = 1.5

    /// Delay before calling system review after positive response (seconds)
    private let systemReviewDelay: TimeInterval = 1.5

    /// App Store App ID (replace with actual ID when published)
    private let appStoreId = "6740199481"

    // MARK: - Initialization

    private init(storage: ReviewSettingsStorage = .shared) {
        self.storage = storage
        ensureInstallDateRecorded()
    }

    /// For testing with dependency injection
    init(storage: ReviewSettingsStorage, forTesting: Bool) {
        self.storage = storage
        ensureInstallDateRecorded()
    }

    // MARK: - Public Interface

    /// Checks milestone achievement and initiates review request flow if conditions are met
    /// - Parameter currentStreak: The user's current streak count
    func checkMilestoneAndRequestReview(currentStreak: Int) {
        // Only trigger on valid milestones
        guard reviewMilestones.contains(currentStreak),
              canRequestReview(forMilestone: currentStreak) else {
            return
        }

        // Delay before showing dialog (after celebration animation)
        Task {
            try? await Task.sleep(nanoseconds: UInt64(preConfirmationDelay * 1_000_000_000))
            await showPreConfirmation(milestone: currentStreak)
        }
    }

    /// Checks if review can be requested for a specific milestone
    /// - Parameter milestone: The milestone to check
    /// - Returns: Whether review request is allowed
    func canRequestReview(forMilestone milestone: Int) -> Bool {
        // Condition 1: Minimum 3 days since install
        guard storage.daysSinceInstall >= minimumDaysSinceInstall else {
            return false
        }

        // Condition 2: Milestone not already triggered
        guard !storage.triggeredMilestones.contains(milestone) else {
            return false
        }

        return true
    }

    /// Shows the pre-confirmation dialog
    /// - Parameter milestone: The achieved milestone
    func showPreConfirmation(milestone: Int) async {
        currentMilestone = milestone
        showingPreConfirmation = true
    }

    /// Handles positive response from user ("네, 좋아요!")
    func handlePositiveResponse() {
        showingPreConfirmation = false
        showingTransition = true

        // Record milestone and increment count
        storage.recordTriggeredMilestone(currentMilestone)
        storage.incrementRequestCount()

        // Delay before system review
        Task {
            try? await Task.sleep(nanoseconds: UInt64(systemReviewDelay * 1_000_000_000))
            await requestSystemReview()
            showingTransition = false
        }
    }

    /// Handles negative response from user ("아니요")
    func handleNegativeResponse() {
        // Record milestone to prevent re-triggering
        storage.recordTriggeredMilestone(currentMilestone)
        showingPreConfirmation = false
        currentMilestone = 0
    }

    /// Requests system review using SKStoreReviewController
    func requestSystemReview() async {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        SKStoreReviewController.requestReview(in: windowScene)
    }

    /// Opens App Store review page directly (for settings screen button)
    func openAppStoreReviewPage() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appStoreId)?action=write-review") else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    /// Checks if App Store review page can be opened
    func canOpenAppStoreReviewPage() -> Bool {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appStoreId)?action=write-review") else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - Private Methods

    private func ensureInstallDateRecorded() {
        storage.recordInstallDate()
    }
}
