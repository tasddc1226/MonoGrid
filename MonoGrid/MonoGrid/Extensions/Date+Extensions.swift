//
//  Date+Extensions.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation

extension Date {
    // MARK: - Start of Day

    /// Returns the start of the day (00:00:00) for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    // MARK: - Date Checks

    /// Checks if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Checks if this date is within the last N days from the reference date
    func isWithin(days: Int, of referenceDate: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: referenceDate)
        let startOfThis = calendar.startOfDay(for: self)

        guard let daysDifference = calendar.dateComponents([.day], from: startOfThis, to: startOfToday).day else {
            return false
        }

        return daysDifference >= 0 && daysDifference <= days
    }

    /// Checks if this date is within the last 7 days (editable range)
    func isWithin7Days(of referenceDate: Date = Date()) -> Bool {
        isWithin(days: 7, of: referenceDate)
    }

    // MARK: - Date Components

    /// Returns the day of week (0 = Monday, 6 = Sunday)
    var dayOfWeekMondayFirst: Int {
        let weekday = Calendar.current.component(.weekday, from: self)
        // Calendar weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        // We want: 0 = Monday, 1 = Tuesday, ..., 6 = Sunday
        return (weekday + 5) % 7
    }

    /// Returns the ISO week number
    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: self)
    }

    // MARK: - Date Generation

    /// Generates an array of dates for the past N days (including today)
    static func past(days: Int, from referenceDate: Date = Date()) -> [Date] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: referenceDate)

        return (0..<days).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday)
        }
    }

    /// Generates dates for the past year (365 days)
    static func pastYear(from referenceDate: Date = Date()) -> [Date] {
        past(days: 365, from: referenceDate)
    }

    /// Generates dates for the past 2 weeks (14 days)
    static func past2Weeks(from referenceDate: Date = Date()) -> [Date] {
        past(days: 14, from: referenceDate)
    }

    // MARK: - Formatting

    /// Returns a formatted date string for display
    /// - Parameter style: Date formatter style
    /// - Returns: Formatted date string
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Returns a localized short date string (e.g., "1/23" or "23/1")
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("Md")
        return formatter.string(from: self)
    }

    /// Returns a localized long date string (e.g., "January 23, 2026" or "2026년 1월 23일")
    var longFormatted: String {
        formatted(style: .long)
    }

    /// Returns a full date string with weekday (e.g., "1월 23일 목요일")
    var fullFormattedWithWeekday: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMd EEEE")
        return formatter.string(from: self)
    }

    // MARK: - Grid Helpers

    /// Returns the week column index for a 52-week grid (0 = oldest week)
    func weekColumnIndex(from startDate: Date) -> Int {
        let calendar = Calendar.current
        let weeks = calendar.dateComponents([.weekOfYear], from: startDate.startOfDay, to: self.startOfDay).weekOfYear ?? 0
        return max(0, weeks)
    }

    /// Adds days to the date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
