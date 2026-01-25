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
        // 백그라운드 스레드에서 실행하여 MainActor 오버헤드 제거
        // 배치 조회 패턴으로 N+1 쿼리 문제 해결
        return try await Task.detached(priority: .userInitiated) {
            guard let context = SharedModelContainer.getBackgroundContext() else {
                return []
            }

            let calendar = SharedInstances.calendar
            let today = calendar.startOfDay(for: Date())
            let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today) ?? today

            // 배치 조회: 모든 습관 + 2주간 로그를 2회 쿼리로
            // 기존: N habits × 2 queries = 2N queries
            // 최적화: 1 (habits) + 1 (logs) = 2 queries

            // 1. 모든 습관 조회 (1 query)
            let habitDescriptor = FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.orderIndex)]
            )
            let habits = try context.fetch(habitDescriptor)

            guard !habits.isEmpty else { return [] }

            // 2. 모든 로그를 한 번에 조회 (1 query)
            let logDescriptor = FetchDescriptor<HabitLog>(
                predicate: #Predicate { log in
                    log.date >= twoWeeksAgo
                }
            )
            let allLogs = try context.fetch(logDescriptor)

            // 3. 메모리 내에서 습관별로 그룹화
            var logsByHabitId: [UUID: [HabitLog]] = [:]
            for log in allLogs {
                guard let habitId = log.habit?.id else { continue }
                logsByHabitId[habitId, default: []].append(log)
            }

            // 4. HabitData 생성
            return habits.map { habit in
                let habitLogs = logsByHabitId[habit.id] ?? []
                let recentLogs = Dictionary(
                    uniqueKeysWithValues: habitLogs.map {
                        (calendar.startOfDay(for: $0.date), $0.isCompleted)
                    }
                )
                let isTodayCompleted = recentLogs[today] ?? false

                return HabitData(
                    id: habit.id.uuidString,
                    title: habit.title,
                    colorHex: habit.colorHex,
                    iconSymbol: habit.iconSymbol,
                    isTodayCompleted: isTodayCompleted,
                    recentLogs: recentLogs
                )
            }
        }.value
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
        // Use SharedModelContainer for consistent CloudKit-enabled configuration
        guard let context = await MainActor.run(body: {
            SharedModelContainer.getSharedContext()
        }) else {
            return HabitEntry.empty
        }

        do {

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
