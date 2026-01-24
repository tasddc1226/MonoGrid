//
//  Habit.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import SwiftData

/// Habit model representing a single habit that the user tracks.
/// Maximum of 3 habits are allowed per user.
@Model
final class Habit {
    // MARK: - Properties

    /// Unique identifier for the habit
    @Attribute(.unique) var id: UUID

    /// Title/name of the habit (e.g., "Reading", "Exercise")
    var title: String

    /// Color in hex format (e.g., "#FF6B6B")
    var colorHex: String

    /// SF Symbol name for the icon (e.g., "book.fill")
    var iconSymbol: String

    /// Display order index (0, 1, or 2)
    var orderIndex: Int

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    // MARK: - Relationships

    /// Associated habit logs (one-to-many)
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]?

    // MARK: - Initialization

    init(
        title: String,
        colorHex: String = "#4D96FF",
        iconSymbol: String = "star.fill",
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.colorHex = colorHex
        self.iconSymbol = iconSymbol
        self.orderIndex = orderIndex
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Returns the count of completed logs
    var completedLogsCount: Int {
        logs?.filter { $0.isCompleted }.count ?? 0
    }

    /// Checks if the habit is completed for a specific date
    func isCompleted(on date: Date) -> Bool {
        let targetDate = Calendar.current.startOfDay(for: date)
        return logs?.first { $0.date == targetDate }?.isCompleted ?? false
    }
}

// MARK: - Hashable Conformance

extension Habit: Hashable {
    static func == (lhs: Habit, rhs: Habit) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
