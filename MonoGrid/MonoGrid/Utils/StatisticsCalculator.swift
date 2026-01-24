//
//  StatisticsCalculator.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation

/// Utility for calculating habit statistics from completion data
enum StatisticsCalculator {
    // MARK: - Main Calculation Methods

    /// Calculates statistics for yearly view
    static func calculateYearlyStatistics(
        completionData: [Date: Bool],
        year: Int
    ) -> GridStatistics {
        guard let range = DateRangeCalculator.yearRange(for: year) else {
            return .empty
        }

        let today = Calendar.current.startOfDay(for: Date())
        let endDate = min(range.end, today)
        let datesInRange = DateRangeCalculator.datesInRange(from: range.start, to: endDate)

        let totalDays = datesInRange.count
        let completedDays = countCompletedDays(in: completionData, dates: datesInRange)
        let completionRate = calculateCompletionRate(completed: completedDays, total: totalDays)
        let (currentStreak, longestStreak) = calculateStreaks(
            completionData: completionData,
            dates: datesInRange
        )
        let bestDayOfWeek = calculateBestDayOfWeek(completionData: completionData, dates: datesInRange)
        let bestMonth = calculateBestMonth(completionData: completionData, dates: datesInRange)

        return GridStatistics(
            totalDays: totalDays,
            completedDays: completedDays,
            completionRate: completionRate,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            period: "\(year)년",
            bestDayOfWeek: bestDayOfWeek,
            bestMonth: bestMonth
        )
    }

    /// Calculates statistics for monthly view
    static func calculateMonthlyStatistics(
        completionData: [Date: Bool],
        year: Int,
        month: Int
    ) -> GridStatistics {
        guard let range = DateRangeCalculator.monthRange(year: year, month: month) else {
            return .empty
        }

        let today = Calendar.current.startOfDay(for: Date())
        let endDate = min(range.end, today)

        // If the month is in the future, return empty
        if range.start > today {
            return GridStatistics(
                totalDays: 0,
                completedDays: 0,
                completionRate: 0,
                currentStreak: 0,
                longestStreak: 0,
                period: "\(year)년 \(month)월"
            )
        }

        let datesInRange = DateRangeCalculator.datesInRange(from: range.start, to: endDate)

        let totalDays = datesInRange.count
        let completedDays = countCompletedDays(in: completionData, dates: datesInRange)
        let completionRate = calculateCompletionRate(completed: completedDays, total: totalDays)
        let (currentStreak, longestStreak) = calculateStreaks(
            completionData: completionData,
            dates: datesInRange
        )
        let bestDayOfWeek = calculateBestDayOfWeek(completionData: completionData, dates: datesInRange)

        return GridStatistics(
            totalDays: totalDays,
            completedDays: completedDays,
            completionRate: completionRate,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            period: "\(year)년 \(month)월",
            bestDayOfWeek: bestDayOfWeek
        )
    }

    /// Calculates statistics for weekly view
    static func calculateWeeklyStatistics(
        completionData: [Date: Bool],
        weekStart: Date
    ) -> GridStatistics {
        let range = DateRangeCalculator.weekRange(containing: weekStart)
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = min(range.end, today)

        // If the week is in the future, return empty
        if range.start > today {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let periodStr = "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"

            return GridStatistics(
                totalDays: 0,
                completedDays: 0,
                completionRate: 0,
                currentStreak: 0,
                longestStreak: 0,
                period: periodStr
            )
        }

        let datesInRange = DateRangeCalculator.datesInRange(from: range.start, to: endDate)

        let totalDays = datesInRange.count
        let completedDays = countCompletedDays(in: completionData, dates: datesInRange)
        let completionRate = calculateCompletionRate(completed: completedDays, total: totalDays)
        let (currentStreak, longestStreak) = calculateStreaks(
            completionData: completionData,
            dates: datesInRange
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        let periodStr = "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"

        return GridStatistics(
            totalDays: totalDays,
            completedDays: completedDays,
            completionRate: completionRate,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            period: periodStr
        )
    }

    // MARK: - Helper Methods

    /// Counts completed days from completion data
    private static func countCompletedDays(in data: [Date: Bool], dates: [Date]) -> Int {
        dates.filter { date in
            data[date] == true
        }.count
    }

    /// Calculates completion rate as percentage
    private static func calculateCompletionRate(completed: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }

    /// Calculates current and longest streaks
    private static func calculateStreaks(
        completionData: [Date: Bool],
        dates: [Date]
    ) -> (current: Int, longest: Int) {
        guard !dates.isEmpty else { return (0, 0) }

        let sortedDates = dates.sorted()
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0

        for date in sortedDates {
            if completionData[date] == true {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 0
            }
        }

        // Calculate current streak from today backwards
        let today = Calendar.current.startOfDay(for: Date())
        let reversedDates = sortedDates.reversed()

        for date in reversedDates {
            if date > today {
                continue
            }
            if completionData[date] == true {
                currentStreak += 1
            } else {
                break
            }
        }

        return (currentStreak, longestStreak)
    }

    /// Calculates the best day of week (most completions)
    private static func calculateBestDayOfWeek(
        completionData: [Date: Bool],
        dates: [Date]
    ) -> Int? {
        let calendar = Calendar.current
        var dayOfWeekCounts: [Int: Int] = [:]

        for date in dates {
            if completionData[date] == true {
                let weekday = calendar.component(.weekday, from: date) - 1 // 0=Sunday
                dayOfWeekCounts[weekday, default: 0] += 1
            }
        }

        guard !dayOfWeekCounts.isEmpty else { return nil }
        return dayOfWeekCounts.max(by: { $0.value < $1.value })?.key
    }

    /// Calculates the best month (most completions) for yearly view
    private static func calculateBestMonth(
        completionData: [Date: Bool],
        dates: [Date]
    ) -> Int? {
        let calendar = Calendar.current
        var monthCounts: [Int: Int] = [:]

        for date in dates {
            if completionData[date] == true {
                let month = calendar.component(.month, from: date)
                monthCounts[month, default: 0] += 1
            }
        }

        guard !monthCounts.isEmpty else { return nil }
        return monthCounts.max(by: { $0.value < $1.value })?.key
    }
}
