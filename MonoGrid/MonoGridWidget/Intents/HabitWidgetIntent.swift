//
//  HabitWidgetIntent.swift
//  MonoGridWidget
//
//  Created on 2026-01-23.
//

import AppIntents
import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Configuration Intent

/// Configuration intent for widgets to select a specific habit
struct HabitWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "습관 선택"
    static var description: IntentDescription = IntentDescription("위젯에 표시할 습관을 선택합니다")

    @Parameter(title: "습관")
    var habit: HabitAppEntity?
}

// MARK: - Habit App Entity

/// App entity representing a habit for intents
struct HabitAppEntity: AppEntity {
    var id: String
    var title: String
    var iconSymbol: String
    var colorHex: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "습관"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            image: .init(systemName: iconSymbol)
        )
    }

    static var defaultQuery = HabitAppEntityQuery()
}

// MARK: - Habit Entity Query

/// Query for fetching habit entities
struct HabitAppEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [HabitAppEntity] {
        let allEntities = try await suggestedEntities()
        return allEntities.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [HabitAppEntity] {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) else {
            return []
        }

        let storeURL = containerURL.appendingPathComponent("MonoGrid.sqlite")
        let schema = Schema([Habit.self, HabitLog.self])
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.orderIndex)])
        let habits = try context.fetch(descriptor)

        return habits.map { habit in
            HabitAppEntity(
                id: habit.id.uuidString,
                title: habit.title,
                iconSymbol: habit.iconSymbol,
                colorHex: habit.colorHex
            )
        }
    }

    func defaultResult() async -> HabitAppEntity? {
        try? await suggestedEntities().first
    }
}
