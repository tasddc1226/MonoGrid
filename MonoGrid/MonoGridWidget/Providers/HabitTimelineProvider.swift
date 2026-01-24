//
//  HabitTimelineProvider.swift
//  MonoGridWidget
//
//  Created on 2026-01-23.
//

import WidgetKit
import SwiftUI
import SwiftData

/// Timeline provider for habit widgets
struct HabitTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = HabitEntry
    typealias Intent = HabitWidgetConfigurationIntent

    // MARK: - Protocol Methods

    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry.placeholder
    }

    func snapshot(for configuration: HabitWidgetConfigurationIntent, in context: Context) async -> HabitEntry {
        if context.isPreview {
            return HabitEntry.placeholder
        }

        return await fetchEntry(for: configuration)
    }

    func timeline(for configuration: HabitWidgetConfigurationIntent, in context: Context) async -> Timeline<HabitEntry> {
        let entry = await fetchEntry(for: configuration)

        // Refresh at next midnight
        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )

        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }

    // MARK: - Data Fetching

    private func fetchEntry(for configuration: HabitWidgetConfigurationIntent) async -> HabitEntry {
        do {
            let habits = try await fetchHabitsFromSharedContainer()
            let themeMode = ThemeManager.currentThemeMode()

            let selectedHabitId: String?
            if let selectedHabit = configuration.habit {
                selectedHabitId = selectedHabit.id
            } else {
                selectedHabitId = nil
            }

            return HabitEntry(
                date: Date(),
                habits: habits,
                selectedHabitId: selectedHabitId,
                isPlaceholder: false,
                themeMode: themeMode
            )
        } catch {
            print("Widget: Failed to fetch habits: \(error)")
            return HabitEntry.empty
        }
    }

    private func fetchHabitsFromSharedContainer() async throws -> [HabitData] {
        // Access shared App Group container
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.suyoung.monogrid"
        ) else {
            return []
        }

        let storeURL = containerURL.appendingPathComponent("MonoGrid.sqlite")

        let schema = Schema([Habit.self, HabitLog.self])
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        // Fetch habits
        let habitDescriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.orderIndex)])
        let habits = try context.fetch(habitDescriptor)

        // Convert to widget data
        let today = Calendar.current.startOfDay(for: Date())
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: today) ?? today

        return habits.map { habit in
            // Fetch recent logs using habitId for predicate compatibility
            let habitId = habit.id
            let logDescriptor = FetchDescriptor<HabitLog>(
                predicate: #Predicate { log in
                    log.habitId == habitId && log.date >= twoWeeksAgo
                }
            )
            let logs = (try? context.fetch(logDescriptor)) ?? []

            let recentLogs = Dictionary(
                uniqueKeysWithValues: logs.map { ($0.date, $0.isCompleted) }
            )

            let isTodayCompleted = logs.first { $0.date == today }?.isCompleted ?? false

            return HabitData(
                id: habit.id.uuidString,
                title: habit.title,
                colorHex: habit.colorHex,
                iconSymbol: habit.iconSymbol,
                isTodayCompleted: isTodayCompleted,
                recentLogs: recentLogs
            )
        }
    }
}

// MARK: - Simple Timeline Provider (for Lock Screen widgets)

struct SimpleLockScreenProvider: TimelineProvider {
    typealias Entry = HabitEntry

    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(HabitEntry.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextMidnight = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            )
            let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
            completion(timeline)
        }
    }

    private func fetchEntry() async -> HabitEntry {
        // Simplified fetch - same logic as main provider
        do {
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.suyoung.monogrid"
            ) else {
                return HabitEntry.empty
            }

            let storeURL = containerURL.appendingPathComponent("MonoGrid.sqlite")
            let schema = Schema([Habit.self, HabitLog.self])
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)

            let habitDescriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.orderIndex)])
            let habits = try context.fetch(habitDescriptor)

            let today = Calendar.current.startOfDay(for: Date())

            let habitDataList = habits.map { habit in
                let habitId = habit.id
                let logDescriptor = FetchDescriptor<HabitLog>(
                    predicate: #Predicate { log in
                        log.habitId == habitId && log.date == today
                    }
                )
                let isTodayCompleted = (try? context.fetch(logDescriptor).first?.isCompleted) ?? false

                return HabitData(
                    id: habit.id.uuidString,
                    title: habit.title,
                    colorHex: habit.colorHex,
                    iconSymbol: habit.iconSymbol,
                    isTodayCompleted: isTodayCompleted,
                    recentLogs: [:]
                )
            }

            let themeMode = ThemeManager.currentThemeMode()
            return HabitEntry(date: Date(), habits: habitDataList, themeMode: themeMode)
        } catch {
            return HabitEntry.empty
        }
    }
}
