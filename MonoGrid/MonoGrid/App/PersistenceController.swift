//
//  PersistenceController.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import SwiftData

/// Singleton controller for managing SwiftData persistence with App Groups and CloudKit
@MainActor
final class PersistenceController {
    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Properties

    /// The main model container
    let container: ModelContainer

    /// The main model context
    var mainContext: ModelContext {
        container.mainContext
    }

    // MARK: - Initialization

    private init() {
        // Define schema
        let schema = Schema([
            Habit.self,
            HabitLog.self
        ])

        // Configure for CloudKit sync via App Groups
        let modelConfiguration: ModelConfiguration

        #if DEBUG
        // Use in-memory store for previews/testing if needed
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            modelConfiguration = Self.createConfiguration(schema: schema)
        }
        #else
        modelConfiguration = Self.createConfiguration(schema: schema)
        #endif

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Configuration

    private static func createConfiguration(schema: Schema) -> ModelConfiguration {
        // Get App Group container URL
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) {
            let storeURL = containerURL.appendingPathComponent("MonoGrid.sqlite")

            // CloudKit disabled for simulator compatibility
            // Enable for production: cloudKitDatabase: .private(Constants.cloudKitContainerIdentifier)
            return ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
        } else {
            // Fallback to default location (development/testing)
            return ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .none
            )
        }
    }

    // MARK: - Preview Support

    /// Creates a preview container with sample data
    @MainActor
    static var preview: PersistenceController = {
        let controller = PersistenceController.previewInstance

        // Add sample data
        let context = controller.mainContext

        let habit1 = Habit(title: "독서", colorHex: "#FF6B6B", iconSymbol: "book.fill", orderIndex: 0)
        let habit2 = Habit(title: "운동", colorHex: "#4D96FF", iconSymbol: "figure.walk", orderIndex: 1)
        let habit3 = Habit(title: "영양제", colorHex: "#6BCB77", iconSymbol: "pills.fill", orderIndex: 2)

        context.insert(habit1)
        context.insert(habit2)
        context.insert(habit3)

        // Add some sample logs
        let today = Calendar.current.startOfDay(for: Date())
        for i in 0..<14 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) {
                if Bool.random() {
                    let log1 = HabitLog(date: date, isCompleted: true, habit: habit1)
                    context.insert(log1)
                }
                if Bool.random() {
                    let log2 = HabitLog(date: date, isCompleted: true, habit: habit2)
                    context.insert(log2)
                }
                if Bool.random() {
                    let log3 = HabitLog(date: date, isCompleted: true, habit: habit3)
                    context.insert(log3)
                }
            }
        }

        return controller
    }()

    /// Creates an in-memory preview instance
    private static var previewInstance: PersistenceController = {
        let schema = Schema([Habit.self, HabitLog.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let controller = PersistenceController(container: container)
            return controller
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    /// Private initializer for preview
    private init(container: ModelContainer) {
        self.container = container
    }
}
