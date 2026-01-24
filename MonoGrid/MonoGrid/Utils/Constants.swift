//
//  Constants.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import SwiftUI

/// App-wide constants
enum Constants {
    // MARK: - App Configuration

    /// App Group identifier for sharing data between app and extensions
    static let appGroupIdentifier = "group.com.suyoung.monogrid"

    /// CloudKit container identifier (disabled for now)
    static let cloudKitContainerIdentifier = "iCloud.com.suyoung.monogrid"

    /// Maximum number of habits allowed
    static let maxHabitCount = 3

    /// Number of days that can be edited (unlimited - all past dates are editable)
    static let editableDaysRange = Int.max

    /// Number of days to display in the full grid
    static let gridDaysCount = 365

    /// Number of days to display in the mini grid
    static let miniGridDaysCount = 14

    // MARK: - UserDefaults Keys

    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastSyncDate = "lastSyncDate"
        static let preferredLanguage = "preferredLanguage"
        static let appTheme = "appTheme"
    }

    // MARK: - Color Presets

    /// Available habit colors with hex values
    static let colorPresets: [(name: String, hex: String)] = [
        ("Coral", "#FF6B6B"),
        ("Orange", "#FFA94D"),
        ("Yellow", "#FFD93D"),
        ("Green", "#6BCB77"),
        ("Blue", "#4D96FF"),
        ("Purple", "#9B5DE5")
    ]

    // MARK: - Icon Presets

    /// Curated SF Symbol icons for habits
    static let iconPresets: [String] = [
        // Books & Learning
        "book.fill",
        "book.closed.fill",
        "books.vertical.fill",
        "text.book.closed.fill",
        "graduationcap.fill",

        // Health & Fitness
        "figure.walk",
        "figure.run",
        "figure.yoga",
        "dumbbell.fill",
        "heart.fill",

        // Mind & Wellness
        "brain.head.profile",
        "moon.fill",
        "sun.max.fill",
        "leaf.fill",
        "drop.fill",

        // Productivity
        "checkmark.circle.fill",
        "star.fill",
        "flag.fill",
        "target",
        "chart.line.uptrend.xyaxis",

        // Daily Activities
        "cup.and.saucer.fill",
        "fork.knife",
        "pills.fill",
        "bed.double.fill",
        "alarm.fill",

        // Creative
        "paintbrush.fill",
        "pencil",
        "music.note",
        "camera.fill",
        "gamecontroller.fill",

        // Communication
        "message.fill",
        "phone.fill",
        "person.2.fill",
        "house.fill",
        "briefcase.fill"
    ]

    // MARK: - UI Dimensions

    enum UI {
        // Card
        static let cardCornerRadius: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let cardHeight: CGFloat = 120
        static let cardShadowRadius: CGFloat = 8
        static let cardShadowOpacity: CGFloat = 0.08

        // Grid
        static let gridCellSize: CGFloat = 10
        static let gridCellGap: CGFloat = 2
        static let gridCellCornerRadius: CGFloat = 2
        static let miniGridCellSize: CGFloat = 6
        static let widgetGridCellSize: CGFloat = 4

        // Checkbox
        static let checkboxTouchSize: CGFloat = 44
        static let checkboxVisualSize: CGFloat = 28
        static let checkboxCornerRadius: CGFloat = 8
        static let checkboxBorderWidth: CGFloat = 2

        // Icons
        static let habitIconSize: CGFloat = 32
        static let smallIconSize: CGFloat = 24

        // Buttons
        static let primaryButtonHeight: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 12
    }

    // MARK: - Animations

    enum Animations {
        static let checkboxSpring = Animation.spring(response: 0.3, dampingFraction: 0.6)
        static let cardAppear = Animation.easeOut(duration: 0.2)
        static let gridCellFill = Animation.easeInOut(duration: 0.15)
    }
}
