//
//  Color+Extensions.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

extension Color {
    // MARK: - Hex Initialization

    /// Creates a Color from a hex string (e.g., "#FF6B6B" or "FF6B6B")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Hex Conversion

    /// Converts the color to a hex string
    var hexString: String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }

        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0

        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )
    }

    // MARK: - Preset Colors

    /// Coral - Habit color preset 1
    static let habitCoral = Color(hex: "#FF6B6B")

    /// Orange - Habit color preset 2
    static let habitOrange = Color(hex: "#FFA94D")

    /// Yellow - Habit color preset 3
    static let habitYellow = Color(hex: "#FFD93D")

    /// Green - Habit color preset 4
    static let habitGreen = Color(hex: "#6BCB77")

    /// Blue - Habit color preset 5
    static let habitBlue = Color(hex: "#4D96FF")

    /// Purple - Habit color preset 6
    static let habitPurple = Color(hex: "#9B5DE5")

    /// All habit color presets
    static let habitPresets: [Color] = [
        .habitCoral,
        .habitOrange,
        .habitYellow,
        .habitGreen,
        .habitBlue,
        .habitPurple
    ]

    // MARK: - Grid Colors

    /// Incomplete grid cell color (adapts to color scheme)
    static let gridIncomplete = Color.gray.opacity(0.15)

    /// Grid cell background color for dark mode
    static let gridIncompleteDark = Color.gray.opacity(0.3)

    // MARK: - Dark Mode Habit Color Variants

    /// Coral dark mode variant (brightness -10%)
    static let habitCoralDark = Color(hex: "#E05555")

    /// Orange dark mode variant
    static let habitOrangeDark = Color(hex: "#E89540")

    /// Yellow dark mode variant
    static let habitYellowDark = Color(hex: "#E6C336")

    /// Green dark mode variant
    static let habitGreenDark = Color(hex: "#5BB867")

    /// Blue dark mode variant
    static let habitBlueDark = Color(hex: "#4086E6")

    /// Purple dark mode variant
    static let habitPurpleDark = Color(hex: "#8A4FCC")

    // MARK: - Adaptive Colors

    /// Returns the habit color adapted for the given color scheme
    func adaptedForColorScheme(_ colorScheme: ColorScheme) -> Color {
        guard colorScheme == .dark else { return self }
        return AppColors.habitColor(hex: self.hexString, for: colorScheme)
    }

    /// Dark mode color mapping
    static let darkModeColorMap: [String: String] = [
        "#FF6B6B": "#E05555",
        "#FFA94D": "#E89540",
        "#FFD93D": "#E6C336",
        "#6BCB77": "#5BB867",
        "#4D96FF": "#4086E6",
        "#9B5DE5": "#8A4FCC"
    ]

    /// Gets the dark mode variant hex for a given light mode hex
    static func darkModeHex(for hex: String) -> String {
        darkModeColorMap[hex.uppercased()] ?? hex
    }
}

// MARK: - UIColor Extension

extension UIColor {
    /// Creates a UIColor from a hex string
    convenience init(hex: String) {
        let color = Color(hex: hex)
        self.init(color)
    }
}
