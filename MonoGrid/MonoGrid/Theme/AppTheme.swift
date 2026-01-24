//
//  AppTheme.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

// MARK: - Theme Mode

/// User preference for app appearance
enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return String(localized: "시스템 설정")
        case .light: return String(localized: "라이트")
        case .dark: return String(localized: "다크")
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager

/// Manages app-wide theme settings
/// Uses App Group UserDefaults so widgets can access the theme preference
@Observable
class ThemeManager {
    static let shared = ThemeManager()

    /// Hardcoded App Group identifier to ensure consistency between app and widget
    private static let appGroupId = "group.com.suyoung.monogrid"

    /// Theme key for UserDefaults
    private static let themeKey = "appTheme"

    /// Shared UserDefaults accessible by both app and widget extension
    private static var sharedDefaults: UserDefaults {
        // Force unwrap is safe here - if App Group is misconfigured, we want to crash early
        // to catch the issue during development
        UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
    }

    var currentTheme: ThemeMode {
        didSet {
            Self.saveTheme(currentTheme)
        }
    }

    private init() {
        self.currentTheme = Self.loadTheme()
    }

    /// Save theme to shared UserDefaults with synchronization
    private static func saveTheme(_ theme: ThemeMode) {
        sharedDefaults.set(theme.rawValue, forKey: themeKey)
        // Force synchronize to ensure widget sees the change immediately
        sharedDefaults.synchronize()
    }

    /// Load theme from shared UserDefaults
    private static func loadTheme() -> ThemeMode {
        let savedTheme = sharedDefaults.string(forKey: themeKey) ?? ThemeMode.system.rawValue
        return ThemeMode(rawValue: savedTheme) ?? .system
    }

    /// Static method for widgets to read current theme without instantiating ThemeManager
    static func currentThemeMode() -> ThemeMode {
        return loadTheme()
    }
}

// MARK: - Semantic Colors

/// Semantic color definitions that adapt to color scheme
struct AppColors {
    // MARK: - Background Colors

    /// Primary background color
    static func primaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(.systemBackground) : Color(.systemBackground)
    }

    /// Card background color
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }

    /// Grouped background color
    static func groupedBackground(for colorScheme: ColorScheme) -> Color {
        Color(.systemGroupedBackground)
    }

    // MARK: - Text Colors

    /// Primary text color
    static func primaryText(for colorScheme: ColorScheme) -> Color {
        Color.primary
    }

    /// Secondary text color
    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        Color.secondary
    }

    // MARK: - UI Element Colors

    /// Grid incomplete cell color
    static func gridIncomplete(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15)
    }

    /// Checkmark color on completed checkbox
    static func checkmark(for colorScheme: ColorScheme) -> Color {
        .white
    }

    /// Selection indicator color (for pickers)
    static func selectionIndicator(for colorScheme: ColorScheme) -> Color {
        .white
    }

    /// Border color for unchecked checkbox
    static func checkboxBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.secondary.opacity(0.6) : Color.secondary.opacity(0.5)
    }

    /// Card shadow color
    static func cardShadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(Constants.UI.cardShadowOpacity)
    }

    // MARK: - Habit Color Variants

    /// Returns the appropriate habit color variant for the current color scheme
    static func habitColor(hex: String, for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color(hex: darkModeHex(for: hex))
        }
        return Color(hex: hex)
    }

    /// Maps light mode hex to dark mode hex
    private static func darkModeHex(for lightHex: String) -> String {
        let mapping: [String: String] = [
            "#FF6B6B": "#E05555", // Coral
            "#FFA94D": "#E89540", // Orange
            "#FFD93D": "#E6C336", // Yellow
            "#6BCB77": "#5BB867", // Green
            "#4D96FF": "#4086E6", // Blue
            "#9B5DE5": "#8A4FCC"  // Purple
        ]
        return mapping[lightHex.uppercased()] ?? lightHex
    }
}

// MARK: - View Extension for Theme

extension View {
    /// Applies the current theme preference
    func applyTheme(_ themeManager: ThemeManager) -> some View {
        self.preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}
