//
//  OnboardingViewModel.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import SwiftUI
import Observation

/// ViewModel for managing onboarding state
@Observable
@MainActor
final class OnboardingViewModel {
    // MARK: - Properties

    /// Current page index
    var currentPage: Int = 0

    /// Total number of onboarding pages
    let totalPages: Int = 3

    /// Whether onboarding has been completed (stored property for @Observable detection)
    private(set) var hasCompletedOnboarding: Bool = false

    // MARK: - Initialization

    init() {
        // Load initial state from UserDefaults
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
    }

    // MARK: - Computed Properties

    /// Whether we're on the last page
    var isLastPage: Bool {
        currentPage == totalPages - 1
    }

    /// Whether we're on the first page
    var isFirstPage: Bool {
        currentPage == 0
    }

    // MARK: - Actions

    /// Moves to the next page
    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }

    /// Moves to the previous page
    func previousPage() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }

    /// Skips onboarding and marks as complete
    func skip() {
        completeOnboarding()
    }

    /// Marks onboarding as complete
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
    }

    /// Resets onboarding (for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        currentPage = 0
    }
}
