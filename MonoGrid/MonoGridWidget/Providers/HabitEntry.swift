//
//  HabitEntry.swift
//  MonoGridWidget
//
//  Created on 2026-01-23.
//

import WidgetKit
import SwiftUI

/// Data model for widget timeline entries
struct HabitEntry: TimelineEntry {
    /// The date of the entry
    let date: Date

    /// All habits data
    let habits: [HabitData]

    /// Selected habit for single-habit widgets (nil uses first habit)
    let selectedHabitId: String?

    /// Whether this is a placeholder entry
    let isPlaceholder: Bool

    /// User's theme preference from app settings
    let themeMode: ThemeMode

    init(
        date: Date = Date(),
        habits: [HabitData] = [],
        selectedHabitId: String? = nil,
        isPlaceholder: Bool = false,
        themeMode: ThemeMode = .system
    ) {
        self.date = date
        self.habits = habits
        self.selectedHabitId = selectedHabitId
        self.isPlaceholder = isPlaceholder
        self.themeMode = themeMode
    }

    /// Returns the selected habit or the first habit
    var primaryHabit: HabitData? {
        if let selectedId = selectedHabitId {
            return habits.first { $0.id == selectedId }
        }
        return habits.first
    }

    /// Returns the count of completed habits today
    var completedCount: Int {
        habits.filter { $0.isTodayCompleted }.count
    }

    /// Returns the count of remaining habits today
    var remainingCount: Int {
        habits.count - completedCount
    }
}

/// Simplified habit data for widgets
struct HabitData: Identifiable, Hashable {
    let id: String
    let title: String
    let colorHex: String
    let iconSymbol: String
    let isTodayCompleted: Bool
    let recentLogs: [Date: Bool] // Last 14 days

    var color: Color {
        Color(hex: colorHex)
    }

    static func == (lhs: HabitData, rhs: HabitData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data for Previews

extension HabitEntry {
    static let placeholder: HabitEntry = {
        let sampleHabits = [
            HabitData(
                id: "1",
                title: "독서",
                colorHex: "#FF6B6B",
                iconSymbol: "book.fill",
                isTodayCompleted: true,
                recentLogs: generateSampleLogs()
            ),
            HabitData(
                id: "2",
                title: "운동",
                colorHex: "#4D96FF",
                iconSymbol: "figure.walk",
                isTodayCompleted: false,
                recentLogs: generateSampleLogs()
            ),
            HabitData(
                id: "3",
                title: "영양제",
                colorHex: "#6BCB77",
                iconSymbol: "pills.fill",
                isTodayCompleted: false,
                recentLogs: generateSampleLogs()
            )
        ]

        return HabitEntry(
            date: Date(),
            habits: sampleHabits,
            isPlaceholder: true,
            themeMode: .system
        )
    }()

    static let sample = HabitEntry(
        date: Date(),
        habits: placeholder.habits,
        isPlaceholder: false,
        themeMode: ThemeManager.currentThemeMode()
    )

    static let empty = HabitEntry(
        date: Date(),
        habits: [],
        isPlaceholder: false,
        themeMode: ThemeManager.currentThemeMode()
    )

    private static func generateSampleLogs() -> [Date: Bool] {
        var logs: [Date: Bool] = [:]
        let today = Calendar.current.startOfDay(for: Date())

        for i in 0..<14 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) {
                logs[date] = Bool.random()
            }
        }
        return logs
    }
}
