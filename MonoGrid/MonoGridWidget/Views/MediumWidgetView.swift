//
//  MediumWidgetView.swift
//  MonoGridWidget
//
//  Created on 2026-01-23.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Medium Widget Definition

struct MediumHabitWidget: Widget {
    let kind: String = "MediumHabitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: HabitWidgetConfigurationIntent.self,
            provider: HabitTimelineProvider()
        ) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .preferredColorScheme(entry.themeMode.colorScheme)
        }
        .configurationDisplayName("습관 리스트")
        .description("모든 습관을 한눈에 확인하고 체크하세요")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: HabitEntry

    @Environment(\.colorScheme) private var colorScheme

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
            VStack(alignment: .leading, spacing: 8) {
                // Header
                Text("오늘의 습관")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Habit rows
                ForEach(entry.habits) { habit in
                    habitRow(habit)

                    if habit.id != entry.habits.last?.id {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func habitRow(_ habit: HabitData) -> some View {
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
                .lineLimit(1)

            Spacer()

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

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "target")
                .font(.title)
                .foregroundColor(.secondary)

            Text("습관을 추가하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    MediumHabitWidget()
} timeline: {
    HabitEntry.sample
    HabitEntry.placeholder
    HabitEntry.empty
}
