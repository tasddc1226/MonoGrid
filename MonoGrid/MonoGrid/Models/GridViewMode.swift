//
//  GridViewMode.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// View mode states for grid visualization
enum GridViewMode: String, CaseIterable, Identifiable {
    case yearly
    case monthly
    case weekly

    var id: String { rawValue }

    /// Localized display name for the mode
    var displayName: String {
        switch self {
        case .yearly:
            return String(localized: "연간")
        case .monthly:
            return String(localized: "월간")
        case .weekly:
            return String(localized: "주간")
        }
    }

    /// SF Symbol icon name for the mode
    var iconName: String {
        switch self {
        case .yearly:
            return "calendar"
        case .monthly:
            return "calendar.badge.clock"
        case .weekly:
            return "calendar.day.timeline.left"
        }
    }

    /// Description text for accessibility
    var accessibilityLabel: String {
        switch self {
        case .yearly:
            return String(localized: "연간 보기 - 365일 그리드")
        case .monthly:
            return String(localized: "월간 보기 - 달력 형식")
        case .weekly:
            return String(localized: "주간 보기 - 7일 상세")
        }
    }

    /// Default cell size for each mode
    var defaultCellSize: CGFloat {
        switch self {
        case .yearly:
            return 10
        case .monthly:
            return 44
        case .weekly:
            return 60
        }
    }

    /// Gap between cells for each mode
    var cellGap: CGFloat {
        switch self {
        case .yearly:
            return 2
        case .monthly:
            return 4
        case .weekly:
            return 8
        }
    }
}

// MARK: - Grid Cell State

/// Represents the completion state of a grid cell
enum GridCellState {
    /// No data exists for this date
    case empty
    /// Log exists but not completed
    case incomplete
    /// Log exists and completed
    case complete
    /// Future date (not actionable)
    case future

    /// Whether the cell can be toggled
    var isToggleable: Bool {
        switch self {
        case .empty, .incomplete, .complete:
            return true
        case .future:
            return false
        }
    }

    /// Initialize from optional completion status
    /// - Parameters:
    ///   - isCompleted: nil if no log, true/false if log exists
    ///   - isFuture: whether the date is in the future
    init(isCompleted: Bool?, isFuture: Bool = false) {
        if isFuture {
            self = .future
        } else if let completed = isCompleted {
            self = completed ? .complete : .incomplete
        } else {
            self = .empty
        }
    }
}

// MARK: - Grid Cell Data

/// Data model for a single grid cell
struct GridCellData: Identifiable, Equatable {
    let id: Date
    let date: Date
    let state: GridCellState
    let isToday: Bool
    let isEditable: Bool
    let weekOfYear: Int
    let dayOfWeek: Int

    init(
        date: Date,
        isCompleted: Bool?,
        isToday: Bool = false,
        isEditable: Bool = false
    ) {
        self.id = date
        self.date = date
        self.isToday = isToday
        self.isEditable = isEditable

        let calendar = Calendar.current
        self.weekOfYear = calendar.component(.weekOfYear, from: date)
        self.dayOfWeek = calendar.component(.weekday, from: date)

        // Determine state
        let isFuture = date > calendar.startOfDay(for: Date())
        self.state = GridCellState(isCompleted: isCompleted, isFuture: isFuture)
    }

    static func == (lhs: GridCellData, rhs: GridCellData) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}

extension GridCellState: Equatable {}
