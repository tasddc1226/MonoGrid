//
//  SmallWidgetView.swift
//  MonoGridWidget
//
//  Created on 2026-01-23.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Small Widget Definition

struct SmallHabitWidget: Widget {
    let kind: String = "SmallHabitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: HabitWidgetConfigurationIntent.self,
            provider: HabitTimelineProvider()
        ) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .preferredColorScheme(entry.themeMode.colorScheme)
        }
        .configurationDisplayName("습관")
        .description("선택한 습관을 빠르게 확인하고 체크하세요")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
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
        if let habit = entry.primaryHabit {
            let habitColor = adaptedColor(for: habit)

            VStack(spacing: 12) {
                // Icon
                Image(systemName: habit.iconSymbol)
                    .font(.system(size: 32))
                    .foregroundColor(habitColor)

                // Title
                Text(habit.title)
                    .font(.headline)
                    .lineLimit(1)

                // Toggle Button
                Button(intent: ToggleHabitIntent(habitId: habit.id)) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(habit.isTodayCompleted ? habitColor : Color.clear)
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        habit.isTodayCompleted ? habitColor : Color.secondary.opacity(colorScheme == .dark ? 0.6 : 0.5),
                                        lineWidth: 2
                                    )
                            )

                        if habit.isTodayCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            emptyView
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("습관 추가")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SmallHabitWidget()
} timeline: {
    HabitEntry.sample
    HabitEntry.placeholder
    HabitEntry.empty
}
