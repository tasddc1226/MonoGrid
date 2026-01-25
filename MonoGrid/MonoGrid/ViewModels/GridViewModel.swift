//
//  GridViewModel.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import SwiftUI
import Observation

/// ViewModel for managing grid view state and data
@Observable
@MainActor
final class GridViewModel {
    // MARK: - Properties

    /// The habit being displayed
    let habit: Habit

    /// Current view mode
    var viewMode: GridViewMode = .weekly

    /// Current year for yearly view
    var currentYear: Int

    /// Current date for monthly view (first day of month)
    var currentMonthDate: Date

    /// Current week start for weekly view
    var currentWeekStart: Date

    /// Grid completion data
    private(set) var completionData: [Date: Bool] = [:]

    /// Statistics for the current view
    private(set) var statistics: GridStatistics = .empty

    /// Loading state
    private(set) var isLoading: Bool = false

    /// Error message
    var errorMessage: String?

    /// Show error
    var showError: Bool = false

    /// Repository for data operations
    private let repository: HabitRepository

    /// Cache for grid data
    private let cache = GridDataCache.shared

    /// Prefetch task for adjacent periods
    private var prefetchTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Today's date (start of day)
    /// Uses SharedInstances for consistency
    var today: Date {
        SharedInstances.today
    }

    /// Title for the current period based on view mode
    /// Uses SharedInstances for performance
    var periodTitle: String {
        switch viewMode {
        case .yearly:
            return "\(currentYear)년"
        case .monthly:
            return SharedInstances.periodTitleFormatter.string(from: currentMonthDate)
        case .weekly:
            return weekTitle
        }
    }

    private var weekTitle: String {
        let dates = DateRangeCalculator.datesInWeek(containing: currentWeekStart)
        guard let first = dates.first, let last = dates.last else { return "" }

        let formatter = SharedInstances.weekRangeFormatter
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }

    // MARK: - Initialization

    init(habit: Habit, repository: HabitRepository) {
        self.habit = habit
        self.repository = repository

        // Initialize current dates
        let now = Date()
        self.currentYear = DateRangeCalculator.currentYear
        self.currentMonthDate = {
            let ym = DateRangeCalculator.yearMonth(from: now)
            return DateRangeCalculator.monthRange(year: ym.year, month: ym.month)?.start ?? now
        }()
        self.currentWeekStart = DateRangeCalculator.startOfWeek(for: now)
    }

    // MARK: - Data Loading

    /// Loads data for the current view mode
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch viewMode {
            case .yearly:
                completionData = try await loadYearlyData()
            case .monthly:
                completionData = try await loadMonthlyData()
            case .weekly:
                completionData = try await loadWeeklyData()
            }
            // Calculate statistics after loading data
            updateStatistics()
        } catch {
            handleError(error)
        }
    }

    /// Updates statistics based on current view mode and data
    private func updateStatistics() {
        switch viewMode {
        case .yearly:
            statistics = StatisticsCalculator.calculateYearlyStatistics(
                completionData: completionData,
                year: currentYear
            )
        case .monthly:
            let ym = DateRangeCalculator.yearMonth(from: currentMonthDate)
            statistics = StatisticsCalculator.calculateMonthlyStatistics(
                completionData: completionData,
                year: ym.year,
                month: ym.month
            )
        case .weekly:
            statistics = StatisticsCalculator.calculateWeeklyStatistics(
                completionData: completionData,
                weekStart: currentWeekStart
            )
        }
    }

    private func loadYearlyData() async throws -> [Date: Bool] {
        // Try cache first
        if let cached = await cache.get(for: .yearly(habitId: habit.id, year: currentYear)) {
            return cached
        }

        // Fetch from repository
        guard let provider = repository as? GridDataProvider else {
            // Fallback: fetch all logs for the year
            guard let range = DateRangeCalculator.yearRange(for: currentYear) else { return [:] }
            let logs = try await repository.fetchLogs(for: habit.id, from: range.start, to: range.end)
            let data = Dictionary(uniqueKeysWithValues: logs.map { ($0.date, $0.isCompleted) })
            await cache.set(data, for: .yearly(habitId: habit.id, year: currentYear))
            return data
        }

        let data = try await provider.fetchYearlyData(habitId: habit.id, year: currentYear)
        await cache.set(data, for: .yearly(habitId: habit.id, year: currentYear))
        return data
    }

    private func loadMonthlyData() async throws -> [Date: Bool] {
        let ym = DateRangeCalculator.yearMonth(from: currentMonthDate)

        // Try cache first
        if let cached = await cache.get(for: .monthly(habitId: habit.id, year: ym.year, month: ym.month)) {
            return cached
        }

        // Fetch from repository
        guard let provider = repository as? GridDataProvider else {
            guard let range = DateRangeCalculator.monthRange(year: ym.year, month: ym.month) else { return [:] }
            let logs = try await repository.fetchLogs(for: habit.id, from: range.start, to: range.end)
            let data = Dictionary(uniqueKeysWithValues: logs.map { ($0.date, $0.isCompleted) })
            await cache.set(data, for: .monthly(habitId: habit.id, year: ym.year, month: ym.month))
            return data
        }

        let data = try await provider.fetchMonthlyData(habitId: habit.id, year: ym.year, month: ym.month)
        await cache.set(data, for: .monthly(habitId: habit.id, year: ym.year, month: ym.month))
        return data
    }

    private func loadWeeklyData() async throws -> [Date: Bool] {
        let weekStart = DateRangeCalculator.startOfWeek(for: currentWeekStart)

        // Try cache first
        if let cached = await cache.get(for: .weekly(habitId: habit.id, weekStart: weekStart)) {
            return cached
        }

        // Fetch from repository
        guard let provider = repository as? GridDataProvider else {
            let range = DateRangeCalculator.weekRange(containing: currentWeekStart)
            let logs = try await repository.fetchLogs(for: habit.id, from: range.start, to: range.end)
            let data = Dictionary(uniqueKeysWithValues: logs.map { ($0.date, $0.isCompleted) })
            await cache.set(data, for: .weekly(habitId: habit.id, weekStart: weekStart))
            return data
        }

        let data = try await provider.fetchWeeklyData(habitId: habit.id, weekOf: currentWeekStart)
        await cache.set(data, for: .weekly(habitId: habit.id, weekStart: weekStart))
        return data
    }

    // MARK: - Toggle Completion

    /// Toggles habit completion for a specific date
    func toggleCompletion(on date: Date) async {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        // Optimistic update
        let previousValue = completionData[normalizedDate]
        completionData[normalizedDate] = !(previousValue ?? false)
        updateStatistics()

        // Invalidate cache
        await cache.invalidate(habitId: habit.id)

        do {
            try await repository.toggleLog(for: habit.id, on: normalizedDate)
            HapticManager.shared.habitToggle()
        } catch {
            // Revert on failure
            if let previous = previousValue {
                completionData[normalizedDate] = previous
            } else {
                completionData.removeValue(forKey: normalizedDate)
            }
            updateStatistics()
            handleError(error)
        }
    }

    // MARK: - Navigation

    /// Navigates to the previous period
    func navigatePrevious() {
        cancelPrefetch()

        switch viewMode {
        case .yearly:
            currentYear = DateRangeCalculator.previousYear(from: currentYear)
            Task {
                await loadData()
                prefetchAdjacentYears()
            }
        case .monthly:
            currentMonthDate = DateRangeCalculator.previousMonth(from: currentMonthDate)
            Task {
                await loadData()
                prefetchAdjacentMonths()
            }
        case .weekly:
            currentWeekStart = DateRangeCalculator.previousWeek(from: currentWeekStart)
            Task {
                await loadData()
                prefetchAdjacentWeeks()
            }
        }
    }

    /// Navigates to the next period
    func navigateNext() {
        guard canNavigateForward else { return }
        cancelPrefetch()

        switch viewMode {
        case .yearly:
            currentYear = DateRangeCalculator.nextYear(from: currentYear)
            Task {
                await loadData()
                prefetchAdjacentYears()
            }
        case .monthly:
            currentMonthDate = DateRangeCalculator.nextMonth(from: currentMonthDate)
            Task {
                await loadData()
                prefetchAdjacentMonths()
            }
        case .weekly:
            currentWeekStart = DateRangeCalculator.nextWeek(from: currentWeekStart)
            Task {
                await loadData()
                prefetchAdjacentWeeks()
            }
        }
    }

    // MARK: - Prefetch Implementation

    /// 빠른 네비게이션 중 프리페치 취소
    private func cancelPrefetch() {
        prefetchTask?.cancel()
        prefetchTask = nil
    }

    /// 이전/다음 연도 미리 로드
    private func prefetchAdjacentYears() {
        guard PerformanceFlags.enablePrefetching else { return }

        prefetchTask = Task(priority: .utility) {
            let prevYear = DateRangeCalculator.previousYear(from: currentYear)
            let nextYear = DateRangeCalculator.nextYear(from: currentYear)

            async let _ = loadYearlyDataSilently(year: prevYear)
            async let _ = loadYearlyDataSilently(year: nextYear)
        }
    }

    /// 이전/다음 월 미리 로드
    private func prefetchAdjacentMonths() {
        guard PerformanceFlags.enablePrefetching else { return }

        prefetchTask = Task(priority: .utility) {
            let prevMonth = DateRangeCalculator.previousMonth(from: currentMonthDate)
            let nextMonth = DateRangeCalculator.nextMonth(from: currentMonthDate)

            async let _ = loadMonthlyDataSilently(date: prevMonth)
            async let _ = loadMonthlyDataSilently(date: nextMonth)
        }
    }

    /// 이전/다음 주 미리 로드
    private func prefetchAdjacentWeeks() {
        guard PerformanceFlags.enablePrefetching else { return }

        prefetchTask = Task(priority: .utility) {
            let prevWeek = DateRangeCalculator.previousWeek(from: currentWeekStart)
            let nextWeek = DateRangeCalculator.nextWeek(from: currentWeekStart)

            async let _ = loadWeeklyDataSilently(weekStart: prevWeek)
            async let _ = loadWeeklyDataSilently(weekStart: nextWeek)
        }
    }

    // MARK: - Silent Loading (캐시에만 저장, UI 업데이트 없음)

    private func loadYearlyDataSilently(year: Int) async {
        let key = GridDataCache.CacheKey.yearly(habitId: habit.id, year: year)
        guard await cache.get(for: key) == nil else { return }

        if let provider = repository as? GridDataProvider {
            if let data = try? await provider.fetchYearlyData(habitId: habit.id, year: year) {
                await cache.set(data, for: key)
            }
        }
    }

    private func loadMonthlyDataSilently(date: Date) async {
        let ym = DateRangeCalculator.yearMonth(from: date)
        let key = GridDataCache.CacheKey.monthly(habitId: habit.id, year: ym.year, month: ym.month)
        guard await cache.get(for: key) == nil else { return }

        if let provider = repository as? GridDataProvider {
            if let data = try? await provider.fetchMonthlyData(habitId: habit.id, year: ym.year, month: ym.month) {
                await cache.set(data, for: key)
            }
        }
    }

    private func loadWeeklyDataSilently(weekStart: Date) async {
        let key = GridDataCache.CacheKey.weekly(habitId: habit.id, weekStart: weekStart)
        guard await cache.get(for: key) == nil else { return }

        if let provider = repository as? GridDataProvider {
            if let data = try? await provider.fetchWeeklyData(habitId: habit.id, weekOf: weekStart) {
                await cache.set(data, for: key)
            }
        }
    }

    /// Whether we can navigate forward (can't go past today)
    var canNavigateForward: Bool {
        switch viewMode {
        case .yearly:
            return currentYear < DateRangeCalculator.currentYear
        case .monthly:
            let ym = DateRangeCalculator.yearMonth(from: currentMonthDate)
            let currentYM = DateRangeCalculator.yearMonth(from: Date())
            return ym.year < currentYM.year || (ym.year == currentYM.year && ym.month < currentYM.month)
        case .weekly:
            let weekEnd = DateRangeCalculator.endOfWeek(for: currentWeekStart)
            return weekEnd < today
        }
    }

    /// Whether the current view period contains today
    var isShowingToday: Bool {
        let now = Date()
        switch viewMode {
        case .yearly:
            return currentYear == DateRangeCalculator.currentYear
        case .monthly:
            let ym = DateRangeCalculator.yearMonth(from: currentMonthDate)
            let currentYM = DateRangeCalculator.yearMonth(from: now)
            return ym.year == currentYM.year && ym.month == currentYM.month
        case .weekly:
            let todayWeekStart = DateRangeCalculator.startOfWeek(for: now)
            return Calendar.current.isDate(currentWeekStart, inSameDayAs: todayWeekStart)
        }
    }

    /// Jumps to today's date in the current view mode
    func jumpToToday() {
        let now = Date()
        currentYear = DateRangeCalculator.currentYear
        currentMonthDate = {
            let ym = DateRangeCalculator.yearMonth(from: now)
            return DateRangeCalculator.monthRange(year: ym.year, month: ym.month)?.start ?? now
        }()
        currentWeekStart = DateRangeCalculator.startOfWeek(for: now)

        Task {
            await loadData()
        }
    }

    // MARK: - View Mode Change

    /// Called when view mode changes
    func onViewModeChange() {
        Task {
            await loadData()
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        if let gridError = error as? GridDataError {
            errorMessage = gridError.errorDescription
        } else if let habitError = error as? HabitError {
            errorMessage = habitError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }

    /// Dismisses the error
    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
