//
//  HabitViewModel.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import SwiftUI
import Observation

/// Main ViewModel for managing habits and their logs
@Observable
@MainActor
final class HabitViewModel {
    // MARK: - Properties

    /// All habits
    private(set) var habits: [Habit] = []

    /// Loading state
    private(set) var isLoading: Bool = false

    /// Error message
    var errorMessage: String?

    /// Show error alert
    var showError: Bool = false

    /// Show notification permission sheet (triggered on first habit creation)
    var showNotificationPermission: Bool = false

    /// Repository for data operations
    private let repository: HabitRepository

    // MARK: - Computed Properties

    /// Returns whether user can add more habits
    var canAddHabit: Bool {
        habits.count < Constants.maxHabitCount
    }

    /// Returns the count of habits completed today
    var todayCompletedCount: Int {
        habits.filter { $0.isCompleted(on: Date()) }.count
    }

    /// Returns the count of remaining habits for today
    var todayRemainingCount: Int {
        habits.count - todayCompletedCount
    }

    // MARK: - Initialization

    init(repository: HabitRepository) {
        self.repository = repository
    }

    // MARK: - Habit Operations

    /// Loads all habits from the repository
    func loadHabits() async {
        isLoading = true
        defer { isLoading = false }

        do {
            habits = try await repository.fetchHabits()
        } catch {
            handleError(error)
        }
    }

    /// Creates a new habit with the given properties
    func createHabit(title: String, colorHex: String, iconSymbol: String) async throws -> Habit {
        // Validate
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HabitError.invalidData
        }

        guard canAddHabit else {
            throw HabitError.maxLimitReached
        }

        // Check if this is the first habit (for notification permission trigger)
        let isFirstHabit = habits.isEmpty

        let habit = Habit(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            iconSymbol: iconSymbol,
            orderIndex: habits.count
        )

        try await repository.saveHabit(habit)
        await loadHabits()

        // Trigger notification permission sheet on first habit creation
        if isFirstHabit && !NotificationSettingsStorage.shared.hasRequestedPermission {
            showNotificationPermission = true
        }

        return habit
    }

    /// Updates an existing habit
    func updateHabit(_ habit: Habit, title: String? = nil, colorHex: String? = nil, iconSymbol: String? = nil) async throws {
        if let title = title {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw HabitError.invalidData
            }
            habit.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let colorHex = colorHex {
            habit.colorHex = colorHex
        }

        if let iconSymbol = iconSymbol {
            habit.iconSymbol = iconSymbol
        }

        habit.updatedAt = Date()

        try await repository.saveHabit(habit)
        await loadHabits()
    }

    /// Deletes a habit
    func deleteHabit(_ habit: Habit) async throws {
        try await repository.deleteHabit(habit)
        await loadHabits()
    }

    /// Reorders habits based on the new order
    func reorderHabits(from source: IndexSet, to destination: Int) async {
        var reorderedHabits = habits
        reorderedHabits.move(fromOffsets: source, toOffset: destination)

        do {
            try await repository.updateHabitOrder(reorderedHabits)
            await loadHabits()
        } catch {
            handleError(error)
        }
    }

    // MARK: - Log Operations

    /// Toggles the completion status for a habit on a specific date
    func toggleHabit(_ habit: Habit, on date: Date = Date()) async {
        do {
            try await repository.toggleLog(for: habit.id, on: date)
            await loadHabits()

            // Check for review milestone after successful toggle (only for today)
            if Calendar.current.isDateInToday(date) {
                await onHabitCheckCompleted(habit, repository: repository)
            }
        } catch {
            handleError(error)
        }
    }

    /// Checks if a habit is completed on a specific date
    func isHabitCompleted(_ habit: Habit, on date: Date) -> Bool {
        habit.isCompleted(on: date)
    }

    /// Fetches log data for a habit for the grid display
    func fetchGridData(for habit: Habit, days: Int = Constants.gridDaysCount) async -> [Date: Bool] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            return [:]
        }

        do {
            let logs = try await repository.fetchLogs(for: habit.id, from: startDate, to: endDate)
            return Dictionary(uniqueKeysWithValues: logs.map { ($0.date, $0.isCompleted) })
        } catch {
            handleError(error)
            return [:]
        }
    }

    /// Fetches mini grid data (last 2 weeks)
    func fetchMiniGridData(for habit: Habit) async -> [Date: Bool] {
        await fetchGridData(for: habit, days: Constants.miniGridDaysCount)
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        if let habitError = error as? HabitError {
            errorMessage = habitError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }

    /// Dismisses the error alert
    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
