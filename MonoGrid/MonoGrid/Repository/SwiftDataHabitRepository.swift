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
        let targetDate = SharedInstances.calendar.startOfDay(for: date)

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
        let start = SharedInstances.calendar.startOfDay(for: startDate)
        let end = SharedInstances.calendar.startOfDay(for: endDate)

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
        let targetDate = SharedInstances.calendar.startOfDay(for: date)

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

    // MARK: - Batch Query Methods (N+1 쿼리 패턴 해결)

    /// 모든 습관과 지정 기간의 로그를 한 번에 조회
    /// N*2 queries → 2 queries로 최적화
    func fetchAllHabitsWithLogs(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [(habit: Habit, logs: [Date: Bool])] {
        let calendar = SharedInstances.calendar
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        // 1. 모든 습관 조회 (1 query)
        let habitDescriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        let habits = try modelContext.fetch(habitDescriptor)

        guard !habits.isEmpty else { return [] }

        // 2. 해당 기간의 모든 로그 조회 (1 query)
        let logDescriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { log in
                log.date >= start && log.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        let allLogs = try modelContext.fetch(logDescriptor)

        // 3. 습관별로 로그 그룹화 (메모리 내 처리)
        var logsByHabit: [UUID: [Date: Bool]] = [:]
        for log in allLogs {
            guard let habitId = log.habit?.id else { continue }
            let logDate = calendar.startOfDay(for: log.date)
            logsByHabit[habitId, default: [:]][logDate] = log.isCompleted
        }

        // 4. 결과 조합
        return habits.map { habit in
            (habit: habit, logs: logsByHabit[habit.id] ?? [:])
        }
    }

    /// 특정 습관들의 로그를 배치로 조회
    func fetchLogsForHabits(
        _ habitIds: [UUID],
        from startDate: Date,
        to endDate: Date
    ) async throws -> [UUID: [Date: Bool]] {
        let calendar = SharedInstances.calendar
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        // 단일 쿼리로 모든 로그 조회
        let logDescriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { log in
                log.date >= start && log.date <= end
            }
        )
        let allLogs = try modelContext.fetch(logDescriptor)

        // 필터링 및 그룹화
        var result: [UUID: [Date: Bool]] = [:]
        let habitIdSet = Set(habitIds)

        for log in allLogs {
            guard let habitId = log.habit?.id,
                  habitIdSet.contains(habitId) else { continue }
            let logDate = calendar.startOfDay(for: log.date)
            result[habitId, default: [:]][logDate] = log.isCompleted
        }

        return result
    }

    // MARK: - Statistics (for Notifications)

    func getCurrentStreak() async throws -> Int {
        let calendar = SharedInstances.calendar
        let habits = try await fetchHabits()

        guard !habits.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: Date())!)

        while true {
            var allCompleted = true
            for habit in habits {
                if !habit.isCompleted(on: checkDate) {
                    allCompleted = false
                    break
                }
            }

            if allCompleted {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }

            // Limit to 365 days to prevent infinite loop
            if streak >= 365 { break }
        }

        return streak
    }

    func getWeeklyCompletionRate() async throws -> Double {
        let calendar = SharedInstances.calendar
        let today = calendar.startOfDay(for: Date())
        let habits = try await fetchHabits()

        guard !habits.isEmpty else { return 0.0 }

        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        var totalExpected = 0
        var totalCompleted = 0

        for dayOffset in 0..<7 {
            guard let checkDay = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            for habit in habits {
                totalExpected += 1
                if habit.isCompleted(on: checkDay) {
                    totalCompleted += 1
                }
            }
        }

        return totalExpected > 0 ? Double(totalCompleted) / Double(totalExpected) : 0.0
    }

    func fetchIncompleteHabitsCount(for date: Date) async throws -> Int {
        let habits = try await fetchHabits()
        return habits.filter { !$0.isCompleted(on: date) }.count
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
        let calendar = SharedInstances.calendar
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
