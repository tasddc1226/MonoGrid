//
//  HabitLog.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import SwiftData

/// HabitLog model representing a daily record of habit completion.
/// Each log is associated with a single habit and a specific date.
@Model
final class HabitLog {
    // MARK: - Properties

    /// Unique identifier for the log
    var id: UUID = UUID()

    /// Date of the log (normalized to start of day)
    var date: Date = Date()

    /// Whether the habit was completed on this date
    var isCompleted: Bool = false

    /// Last update timestamp for sync conflict resolution
    var updatedAt: Date = Date()

    /// Habit ID for predicate queries (denormalized for SwiftData compatibility)
    var habitId: UUID? = nil

    // MARK: - Relationships

    /// Associated habit (many-to-one)
    var habit: Habit?

    // MARK: - Initialization

    init(date: Date, isCompleted: Bool = false, habit: Habit? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
        self.habit = habit
        self.habitId = habit?.id
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// Toggle the completion status
    func toggle() {
        isCompleted.toggle()
        updatedAt = Date()
    }
}
