//
//  GridStatistics.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation

/// Model containing statistics for a habit's grid view
struct GridStatistics: Equatable {
    // MARK: - Properties

    /// Total number of days in the period
    let totalDays: Int

    /// Number of completed days
    let completedDays: Int

    /// Completion rate as percentage (0-100)
    let completionRate: Double

    /// Current consecutive streak of completed days
    let currentStreak: Int

    /// Longest consecutive streak of completed days
    let longestStreak: Int

    /// Period description (e.g., "2026년", "2026년 1월", "1/20 - 1/26")
    let period: String

    /// Best day of week (0=Sunday, 1=Monday, ...)
    let bestDayOfWeek: Int?

    /// Best month (1-12) for yearly view
    let bestMonth: Int?

    // MARK: - Computed Properties

    /// Formatted completion rate string
    var formattedCompletionRate: String {
        String(format: "%.0f%%", completionRate)
    }

    /// Formatted current streak string
    var formattedCurrentStreak: String {
        "\(currentStreak)일"
    }

    /// Formatted longest streak string
    var formattedLongestStreak: String {
        "\(longestStreak)일"
    }

    /// Formatted completed days string
    var formattedCompletedDays: String {
        "\(completedDays)일"
    }

    /// Best day of week name in Korean
    var bestDayOfWeekName: String? {
        guard let day = bestDayOfWeek else { return nil }
        let dayNames = ["일", "월", "화", "수", "목", "금", "토"]
        guard day >= 0 && day < dayNames.count else { return nil }
        return dayNames[day]
    }

    /// Best month name in Korean
    var bestMonthName: String? {
        guard let month = bestMonth, month >= 1 && month <= 12 else { return nil }
        return "\(month)월"
    }

    // MARK: - Initialization

    init(
        totalDays: Int,
        completedDays: Int,
        completionRate: Double,
        currentStreak: Int,
        longestStreak: Int,
        period: String,
        bestDayOfWeek: Int? = nil,
        bestMonth: Int? = nil
    ) {
        self.totalDays = totalDays
        self.completedDays = completedDays
        self.completionRate = completionRate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.period = period
        self.bestDayOfWeek = bestDayOfWeek
        self.bestMonth = bestMonth
    }

    // MARK: - Static

    /// Empty statistics for initial state
    static var empty: GridStatistics {
        GridStatistics(
            totalDays: 0,
            completedDays: 0,
            completionRate: 0,
            currentStreak: 0,
            longestStreak: 0,
            period: ""
        )
    }
}
