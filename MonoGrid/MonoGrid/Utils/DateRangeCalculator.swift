//
//  DateRangeCalculator.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation

/// Utility for calculating date ranges for grid views
/// All calculations are timezone-safe using Calendar API
enum DateRangeCalculator {
    // MARK: - Year Calculations

    /// Returns the start and end dates for a given year
    /// - Parameter year: The year (e.g., 2026)
    /// - Returns: Tuple of (startDate, endDate) both at start of day
    static func yearRange(for year: Int) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1

        guard let startDate = calendar.date(from: components) else { return nil }

        components.year = year
        components.month = 12
        components.day = 31

        guard let endDate = calendar.date(from: components) else { return nil }

        return (calendar.startOfDay(for: startDate), calendar.startOfDay(for: endDate))
    }

    /// Returns all dates in a given year
    /// - Parameter year: The year (e.g., 2026)
    /// - Returns: Array of dates from Jan 1 to Dec 31
    static func datesInYear(_ year: Int) -> [Date] {
        guard let range = yearRange(for: year) else { return [] }
        return datesInRange(from: range.start, to: range.end)
    }

    // MARK: - Month Calculations

    /// Returns the start and end dates for a given month
    /// - Parameters:
    ///   - year: The year
    ///   - month: The month (1-12)
    /// - Returns: Tuple of (startDate, endDate) both at start of day
    static func monthRange(year: Int, month: Int) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let startDate = calendar.date(from: components) else { return nil }
        guard let range = calendar.range(of: .day, in: .month, for: startDate) else { return nil }

        components.day = range.count

        guard let endDate = calendar.date(from: components) else { return nil }

        return (calendar.startOfDay(for: startDate), calendar.startOfDay(for: endDate))
    }

    /// Returns all dates in a given month
    /// - Parameters:
    ///   - year: The year
    ///   - month: The month (1-12)
    /// - Returns: Array of dates from 1st to last day of month
    static func datesInMonth(year: Int, month: Int) -> [Date] {
        guard let range = monthRange(year: year, month: month) else { return [] }
        return datesInRange(from: range.start, to: range.end)
    }

    /// Returns the month range with week alignment for calendar grid display
    /// Includes leading/trailing days from adjacent months to fill complete weeks
    /// - Parameters:
    ///   - year: The year
    ///   - month: The month (1-12)
    ///   - startOnMonday: Whether week starts on Monday (true) or Sunday (false)
    /// - Returns: Tuple of (startDate, endDate) aligned to week boundaries
    static func monthRangeWithWeekAlignment(year: Int, month: Int, startOnMonday: Bool = true) -> (start: Date, end: Date)? {
        guard let monthRange = monthRange(year: year, month: month) else { return nil }

        let calendar = Calendar.current

        // Find the start of the week containing the first day of the month
        let weekStart = startOfWeek(for: monthRange.start, startOnMonday: startOnMonday)

        // Find the end of the week containing the last day of the month
        let weekEnd = endOfWeek(for: monthRange.end, startOnMonday: startOnMonday)

        return (weekStart, weekEnd)
    }

    // MARK: - Week Calculations

    /// Returns the start and end dates for the week containing a given date
    /// - Parameters:
    ///   - date: Any date within the desired week
    ///   - startOnMonday: Whether week starts on Monday (true) or Sunday (false)
    /// - Returns: Tuple of (startDate, endDate) both at start of day
    static func weekRange(containing date: Date, startOnMonday: Bool = true) -> (start: Date, end: Date) {
        let start = startOfWeek(for: date, startOnMonday: startOnMonday)
        let end = endOfWeek(for: date, startOnMonday: startOnMonday)
        return (start, end)
    }

    /// Returns all 7 dates in the week containing a given date
    /// - Parameters:
    ///   - date: Any date within the desired week
    ///   - startOnMonday: Whether week starts on Monday (true) or Sunday (false)
    /// - Returns: Array of 7 dates from week start to week end
    static func datesInWeek(containing date: Date, startOnMonday: Bool = true) -> [Date] {
        let range = weekRange(containing: date, startOnMonday: startOnMonday)
        return datesInRange(from: range.start, to: range.end)
    }

    /// Returns the start of the week for a given date
    /// - Parameters:
    ///   - date: The reference date
    ///   - startOnMonday: Whether week starts on Monday (true) or Sunday (false)
    /// - Returns: Start of the week at start of day
    static func startOfWeek(for date: Date, startOnMonday: Bool = true) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        let daysToSubtract: Int
        if startOnMonday {
            // Monday = 2, so Monday -> 0, Tuesday -> 1, ..., Sunday -> 6
            daysToSubtract = (weekday + 5) % 7
        } else {
            // Sunday = 1, so Sunday -> 0, Monday -> 1, ..., Saturday -> 6
            daysToSubtract = weekday - 1
        }

        let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: date) ?? date
        return calendar.startOfDay(for: weekStart)
    }

    /// Returns the end of the week for a given date
    /// - Parameters:
    ///   - date: The reference date
    ///   - startOnMonday: Whether week starts on Monday (true) or Sunday (false)
    /// - Returns: Last day of the week at start of day
    static func endOfWeek(for date: Date, startOnMonday: Bool = true) -> Date {
        let calendar = Calendar.current
        let weekStart = startOfWeek(for: date, startOnMonday: startOnMonday)
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return calendar.startOfDay(for: weekEnd)
    }

    // MARK: - Range Helpers

    /// Generates an array of dates between two dates (inclusive)
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Array of dates from start to end
    static func datesInRange(from startDate: Date, to endDate: Date) -> [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        guard start <= end else { return [] }

        var dates: [Date] = []
        var currentDate = start

        while currentDate <= end {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return dates
    }

    /// Returns the number of days between two dates
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Number of days (inclusive)
    static func daysBetween(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return (components.day ?? 0) + 1  // +1 for inclusive
    }

    // MARK: - Navigation Helpers

    /// Returns the previous month date
    /// - Parameter date: Current date
    /// - Returns: Same day in previous month (or last day if invalid)
    static func previousMonth(from date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: -1, to: date) ?? date
    }

    /// Returns the next month date
    /// - Parameter date: Current date
    /// - Returns: Same day in next month (or last day if invalid)
    static func nextMonth(from date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }

    /// Returns the previous week date
    /// - Parameter date: Current date
    /// - Returns: Same weekday in previous week
    static func previousWeek(from date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .weekOfYear, value: -1, to: date) ?? date
    }

    /// Returns the next week date
    /// - Parameter date: Current date
    /// - Returns: Same weekday in next week
    static func nextWeek(from date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
    }

    /// Returns the previous year
    /// - Parameter year: Current year
    /// - Returns: Previous year number
    static func previousYear(from year: Int) -> Int {
        return year - 1
    }

    /// Returns the next year
    /// - Parameter year: Current year
    /// - Returns: Next year number
    static func nextYear(from year: Int) -> Int {
        return year + 1
    }

    // MARK: - Date Info

    /// Returns year and month components from a date
    /// - Parameter date: The date to extract from
    /// - Returns: Tuple of (year, month)
    static func yearMonth(from date: Date) -> (year: Int, month: Int) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return (year, month)
    }

    /// Returns the current year
    static var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    /// Returns the current month
    static var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }
}
