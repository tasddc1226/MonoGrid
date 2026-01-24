//
//  SwiftDataHabitRepository.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import SwiftData
import WidgetKit

/// SwiftData implementation of HabitRepository and GridDataProvider
@MainActor
final class SwiftDataHabitRepository: HabitRepository, GridDataProvider {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Habit Operations

    func fetchHabits() async throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        return try modelContext.fetch(descriptor)
    }

    func saveHabit(_ habit: Habit) async throws {
        // Check if this is a new habit and we're at the limit
        let existingHabits = try await fetchHabits()
        let isNewHabit = !existingHabits.contains { $0.id == habit.id }

        if isNewHabit && existingHabits.count >= Constants.maxHabitCount {
            throw HabitError.maxLimitReached
        }

        // Update timestamp
        habit.updatedAt = Date()

        // If new habit, set order index
        if isNewHabit {
            habit.orderIndex = existingHabits.count
            modelContext.insert(habit)
        }

        try modelContext.save()
        reloadWidgets()
    }

    func deleteHabit(_ habit: Habit) async throws {
        modelContext.delete(habit)
        try modelContext.save()

        // Reorder remaining habits
        let remainingHabits = try await fetchHabits()
        for (index, h) in remainingHabits.enumerated() {
            h.orderIndex = index
        }
        try modelContext.save()

        reloadWidgets()
    }

    func updateHabitOrder(_ habits: [Habit]) async throws {
        for (index, habit) in habits.enumerated() {
            habit.orderIndex = index
            habit.updatedAt = Date()
        }
        try modelContext.save()
        reloadWidgets()
    }

    // MARK: - Log Operations

    @discardableResult
    func toggleLog(for habitId: UUID, on date: Date) async throws -> HabitLog {
        let targetDate = Calendar.current.startOfDay(for: date)

        // Find the habit
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == habitId }
        )
        guard let habit = try modelContext.fetch(habitDescriptor).first else {
            throw HabitError.habitNotFound
        }

        // Check if log exists for this date
        if let existingLog = try await fetchLog(for: habitId, on: date) {
            existingLog.toggle()
            try modelContext.save()
            reloadWidgets()
            return existingLog
        }

        // Create new log (completed by default when toggled from incomplete)
        let newLog = HabitLog(date: targetDate, isCompleted: true, habit: habit)
        modelContext.insert(newLog)
        try modelContext.save()
        reloadWidgets()
        return newLog
    }

    func fetchLogs(for habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)

        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { log in
                log.habit?.id == habitId &&
                log.date >= start &&
                log.date <= end
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchLog(for habitId: UUID, on date: Date) async throws -> HabitLog? {
        let targetDate = Calendar.current.startOfDay(for: date)

        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { log in
                log.habit?.id == habitId && log.date == targetDate
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchAllLogs(for habitId: UUID) async throws -> [HabitLog] {
        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { log in
                log.habit?.id == habitId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Utility

    func habitCount() async throws -> Int {
        let habits = try await fetchHabits()
        return habits.count
    }

    // MARK: - Private Methods

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - GridDataProvider Implementation

    func fetchYearlyData(habitId: UUID, year: Int) async throws -> [Date: Bool] {
        guard let range = DateRangeCalculator.yearRange(for: year) else {
            throw GridDataError.invalidDateRange
        }

        return try await fetchRangeData(habitId: habitId, from: range.start, to: range.end)
    }

    func fetchMonthlyData(habitId: UUID, year: Int, month: Int) async throws -> [Date: Bool] {
        guard let range = DateRangeCalculator.monthRange(year: year, month: month) else {
            throw GridDataError.invalidDateRange
        }

        return try await fetchRangeData(habitId: habitId, from: range.start, to: range.end)
    }

    func fetchWeeklyData(habitId: UUID, weekOf: Date) async throws -> [Date: Bool] {
        let range = DateRangeCalculator.weekRange(containing: weekOf)
        return try await fetchRangeData(habitId: habitId, from: range.start, to: range.end)
    }

    func fetchRangeData(habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [Date: Bool] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        // Validate date range
        guard start <= end else {
            throw GridDataError.invalidDateRange
        }

        // Fetch logs for the range
        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { log in
                log.habit?.id == habitId &&
                log.date >= start &&
                log.date <= end
            }
        )

        do {
            let logs = try modelContext.fetch(descriptor)

            // Convert to dictionary for O(1) lookup
            var result: [Date: Bool] = [:]
            for log in logs {
                let logDate = calendar.startOfDay(for: log.date)
                result[logDate] = log.isCompleted
            }

            return result
        } catch {
            throw GridDataError.fetchFailed(underlying: error)
        }
    }
}
