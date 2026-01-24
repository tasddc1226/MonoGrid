//
//  GridDataProvider.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation

/// Protocol for fetching habit completion data at different time scales
/// Returns [Date: Bool] dictionary for O(1) lookup of completion status
protocol GridDataProvider {
    /// Fetches completion data for an entire year
    /// - Parameters:
    ///   - habitId: The habit UUID
    ///   - year: The year to fetch (e.g., 2026)
    /// - Returns: Dictionary mapping dates to completion status
    func fetchYearlyData(habitId: UUID, year: Int) async throws -> [Date: Bool]

    /// Fetches completion data for a specific month
    /// - Parameters:
    ///   - habitId: The habit UUID
    ///   - year: The year
    ///   - month: The month (1-12)
    /// - Returns: Dictionary mapping dates to completion status
    func fetchMonthlyData(habitId: UUID, year: Int, month: Int) async throws -> [Date: Bool]

    /// Fetches completion data for a week containing the specified date
    /// - Parameters:
    ///   - habitId: The habit UUID
    ///   - weekOf: Any date within the desired week
    /// - Returns: Dictionary mapping dates to completion status
    func fetchWeeklyData(habitId: UUID, weekOf: Date) async throws -> [Date: Bool]

    /// Fetches completion data for a custom date range
    /// - Parameters:
    ///   - habitId: The habit UUID
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    /// - Returns: Dictionary mapping dates to completion status
    func fetchRangeData(habitId: UUID, from: Date, to: Date) async throws -> [Date: Bool]
}

// MARK: - Grid Data Errors

enum GridDataError: LocalizedError {
    case invalidDateRange
    case habitNotFound
    case fetchFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return "Invalid date range specified"
        case .habitNotFound:
            return "Habit not found"
        case .fetchFailed(let underlying):
            return "Failed to fetch grid data: \(underlying.localizedDescription)"
        }
    }
}
