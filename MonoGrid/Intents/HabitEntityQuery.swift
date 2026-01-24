//
//  HabitEntityQuery.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import AppIntents
import SwiftData

/// Query for fetching habit entities for use in Shortcuts and Siri
struct HabitEntityQuery: EntityQuery {
    // MARK: - Entity Fetching

    /// Fetches entities matching specific identifiers
    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        let allHabits = try await fetchAllHabits()
        return allHabits.filter { identifiers.contains($0.id) }
    }

    /// Returns suggested entities for selection UI
    func suggestedEntities() async throws -> [HabitEntity] {
        try await fetchAllHabits()
    }

    /// Default result when no specific selection is made
    func defaultResult() async -> HabitEntity? {
        try? await fetchAllHabits().first
    }

    // MARK: - Private Methods

    private func fetchAllHabits() async throws -> [HabitEntity] {
        // Use SharedModelContainer for consistent CloudKit-enabled configuration
        guard let context = await MainActor.run(body: {
            SharedModelContainer.getSharedContext()
        }) else {
            return []
        }

        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )

        let habits = try context.fetch(descriptor)

        return habits.map { habit in
            HabitEntity(
                id: habit.id.uuidString,
                title: habit.title,
                iconSymbol: habit.iconSymbol,
                colorHex: habit.colorHex
            )
        }
    }
}

// MARK: - String-based Entity Query

extension HabitEntityQuery: EntityStringQuery {
    /// Search for habits by string query (for Siri)
    func entities(matching string: String) async throws -> [HabitEntity] {
        let allHabits = try await fetchAllHabits()

        if string.isEmpty {
            return allHabits
        }

        // Filter by title containing the search string (case-insensitive)
        return allHabits.filter { habit in
            habit.title.localizedCaseInsensitiveContains(string)
        }
    }
}
