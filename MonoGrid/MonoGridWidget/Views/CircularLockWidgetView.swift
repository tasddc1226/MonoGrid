//
//  CircularLockWidgetView.swift
//  MonoGridWidget
//
//  Created on 2026-01-23.
//

import WidgetKit
import SwiftUI

// MARK: - Circular Lock Screen Widget Definition

struct CircularLockWidget: Widget {
    let kind: String = "CircularLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SimpleLockScreenProvider()
        ) { entry in
            CircularLockWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("습관 링")
        .description("잠금 화면에서 첫 번째 습관 상태를 확인하세요")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Circular Lock Widget View

struct CircularLockWidgetView: View {
    let entry: HabitEntry

    var body: some View {
        if let habit = entry.primaryHabit {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 4)

                // Progress ring
                if habit.isTodayCompleted {
                    Circle()
                        .stroke(Color.primary, lineWidth: 4)
                }

                // Icon
                Image(systemName: habit.iconSymbol)
                    .font(.title3)
            }
            .widgetAccentable()
        } else {
            Image(systemName: "target")
                .font(.title3)
        }
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    CircularLockWidget()
} timeline: {
    HabitEntry.sample
    HabitEntry.placeholder
}
