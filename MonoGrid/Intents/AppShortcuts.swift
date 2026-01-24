//
//  AppShortcuts.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import AppIntents

/// Provides pre-built shortcuts for the Shortcuts app and Siri
struct MonoGridShortcuts: AppShortcutsProvider {
    // MARK: - App Shortcuts

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleHabitIntent(),
            phrases: [
                // English phrases
                "Check \(.applicationName) habit",
                "Toggle \(.applicationName) habit",
                "Mark habit done in \(.applicationName)",
                "Complete habit in \(.applicationName)",

                // Korean phrases
                "\(.applicationName) 습관 체크",
                "\(.applicationName)에서 습관 체크",
                "\(.applicationName) 습관 완료",
                "\(.applicationName)에서 습관 완료",
                "\(.applicationName) 습관 기록"
            ],
            shortTitle: LocalizedStringResource("습관 체크"),
            systemImageName: "checkmark.circle.fill"
        )
    }

    // MARK: - Short Title

    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}
