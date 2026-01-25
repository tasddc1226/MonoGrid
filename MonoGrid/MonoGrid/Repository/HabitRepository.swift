//
//  HabitRepository.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation

/// Protocol defining the interface for habit data operations
protocol HabitRepository {
    // MARK: - Habit Operations

    /// Fetches all habits sorted by orderIndex
    func fetchHabits() async throws -> [Habit]

    /// Saves a new habit or updates an existing one
    func saveHabit(_ habit: Habit) async throws

    /// Deletes a habit and all associated logs
    func deleteHabit(_ habit: Habit) async throws

    /// Updates the order of habits
    func updateHabitOrder(_ habits: [Habit]) async throws

    // MARK: - Log Operations

    /// Toggles the completion status for a habit on a specific date
    /// Returns the updated or newly created log
    @discardableResult
    func toggleLog(for habitId: UUID, on date: Date) async throws -> HabitLog

    /// Fetches all logs for a habit within a date range
    func fetchLogs(for habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]

    /// Fetches the log for a habit on a specific date (if exists)
    func fetchLog(for habitId: UUID, on date: Date) async throws -> HabitLog?

    /// Fetches all logs for a habit
    func fetchAllLogs(for habitId: UUID) async throws -> [HabitLog]

    // MARK: - Utility

    /// Returns the current habit count
    func habitCount() async throws -> Int

    // MARK: - Statistics (for Notifications)

    /// Fetches the current streak (consecutive days with all habits completed)
    func getCurrentStreak() async throws -> Int

    /// Fetches the weekly completion rate (0.0-1.0)
    func getWeeklyCompletionRate() async throws -> Double

    /// Fetches the count of incomplete habits for a specific date
    func fetchIncompleteHabitsCount(for date: Date) async throws -> Int
}

// MARK: - Habit Errors

/// Custom errors for habit operations
enum HabitError: LocalizedError {
    case maxLimitReached
    case habitNotFound
    case dateOutOfRange
    case invalidData
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .maxLimitReached:
            return String(localized: "error.maxLimitReached", defaultValue: "Maximum 3 habits allowed")
        case .habitNotFound:
            return String(localized: "error.habitNotFound", defaultValue: "Habit not found")
        case .dateOutOfRange:
            return String(localized: "error.dateOutOfRange", defaultValue: "Can only edit records within the last 7 days")
        case .invalidData:
            return String(localized: "error.invalidData", defaultValue: "Invalid data provided")
        case .saveFailed:
            return String(localized: "error.saveFailed", defaultValue: "Failed to save data")
        case .deleteFailed:
            return String(localized: "error.deleteFailed", defaultValue: "Failed to delete data")
        }
    }
}
