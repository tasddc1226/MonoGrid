//
//  LargeWidgetView.swift
//  MonoGridWidget
//
//  Created on 2026-01-23.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Large Widget Definition

struct LargeHabitWidget: Widget {
    let kind: String = "LargeHabitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: HabitWidgetConfigurationIntent.self,
            provider: HabitTimelineProvider()
        ) { entry in
            LargeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .preferredColorScheme(entry.themeMode.colorScheme)
        }
        .configurationDisplayName("습관 그리드")
        .description("습관과 최근 기록을 함께 확인하세요")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: HabitEntry

    @Environment(\.colorScheme) private var colorScheme

    private let gridCellSize: CGFloat = 4
    private let gridCellGap: CGFloat = 2

    private func adaptedColor(for habit: HabitData) -> Color {
        let hex = habit.colorHex
        if colorScheme == .dark {
            let mapping: [String: String] = [
                "#FF6B6B": "#E05555",
                "#FFA94D": "#E89540",
                "#FFD93D": "#E6C336",
                "#6BCB77": "#5BB867",
                "#4D96FF": "#4086E6",
                "#9B5DE5": "#8A4FCC"
            ]
            if let darkHex = mapping[hex.uppercased()] {
                return Color(hex: darkHex)
            }
        }
        return habit.color
    }

    var body: some View {
        if entry.habits.isEmpty {
            emptyView
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("MonoGrid")
                        .font(.headline)

                    Spacer()

                    Text(Date().shortFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Habit rows with mini grids
                ForEach(entry.habits) { habit in
                    habitRowWithGrid(habit)

                    if habit.id != entry.habits.last?.id {
                        Divider()
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func habitRowWithGrid(_ habit: HabitData) -> some View {
        let habitColor = adaptedColor(for: habit)

        HStack {
            // Icon
            Image(systemName: habit.iconSymbol)
                .font(.title3)
                .foregroundColor(habitColor)
                .frame(width: 28)

            // Title
            Text(habit.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Spacer()

            // Mini Grid
            miniGrid(for: habit)

            // Toggle Button
            Button(intent: ToggleHabitIntent(habitId: habit.id)) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(habit.isTodayCompleted ? habitColor : Color.clear)
                        .frame(width: 28, height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(
                                    habit.isTodayCompleted ? habitColor : Color.secondary.opacity(colorScheme == .dark ? 0.5 : 0.4),
                                    lineWidth: 1.5
                                )
                        )

                    if habit.isTodayCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func miniGrid(for habit: HabitData) -> some View {
        let dates = Date.past(days: 14)
        let habitColor = adaptedColor(for: habit)

        HStack(spacing: gridCellGap) {
            ForEach(dates.reversed(), id: \.self) { date in
                let isCompleted = habit.recentLogs[Calendar.current.startOfDay(for: date)] ?? false

                RoundedRectangle(cornerRadius: 1)
                    .fill(isCompleted ? habitColor : Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                    .frame(width: gridCellSize, height: gridCellSize)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("습관을 추가하세요")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("앱에서 최대 3개의 습관을 등록할 수 있습니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview(as: .systemLarge) {
    LargeHabitWidget()
} timeline: {
    HabitEntry.sample
    HabitEntry.placeholder
    HabitEntry.empty
}
