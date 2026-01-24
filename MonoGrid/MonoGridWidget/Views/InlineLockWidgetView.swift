//
//  InlineLockWidgetView.swift
//  MonoGridWidget
//
//  Created on 2026-01-23.
//

import WidgetKit
import SwiftUI

// MARK: - Inline Lock Screen Widget Definition

struct InlineLockWidget: Widget {
    let kind: String = "InlineLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SimpleLockScreenProvider()
        ) { entry in
            InlineLockWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("남은 습관")
        .description("잠금 화면에서 오늘 남은 습관 수를 확인하세요")
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Inline Lock Widget View

struct InlineLockWidgetView: View {
    let entry: HabitEntry

    var body: some View {
        if entry.habits.isEmpty {
            Label("습관을 추가하세요", systemImage: "target")
        } else if entry.remainingCount == 0 {
            Label("모든 습관 완료! 🎉", systemImage: "checkmark.circle.fill")
        } else {
            Label("남은 습관: \(entry.remainingCount)개", systemImage: "target")
        }
    }
}

// MARK: - Preview

#Preview(as: .accessoryInline) {
    InlineLockWidget()
} timeline: {
    HabitEntry.sample
    HabitEntry.placeholder
    HabitEntry.empty
}
