//
//  HabitViewModel+Review.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import Foundation

/// Extension for integrating app review requests with habit completion
extension HabitViewModel {
    /// Called when a habit checkbox is completed
    /// Checks for milestone streaks and triggers review request if appropriate
    /// - Parameter habit: The habit that was just completed
    func onHabitCheckCompleted(_ habit: Habit, repository: HabitRepository) async {
        // Only trigger on completion, not on uncomplete
        guard habit.isCompleted(on: Date()) else { return }

        // Get current streak from repository
        guard let streak = try? await repository.getCurrentStreak() else {
            return
        }

        // Check if streak is a milestone and trigger review
        AppReviewManager.shared.checkMilestoneAndRequestReview(currentStreak: streak)
    }
}
