//
//  GridLegendView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Legend showing completion intensity levels
/// Displays: Less ░░ ▒▒ ▓▓ ██ More
struct GridLegendView: View {
    // MARK: - Properties

    let habitColorHex: String
    let cellSize: CGFloat
    let showLabels: Bool

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(
        habitColorHex: String,
        cellSize: CGFloat = 10,
        showLabels: Bool = true
    ) {
        self.habitColorHex = habitColorHex
        self.cellSize = cellSize
        self.showLabels = showLabels
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            if showLabels {
                Text("적음")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Gradient cells from empty to full
            ForEach(opacityLevels.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: max(2, cellSize * 0.2))
                    .fill(cellColor(at: index))
                    .frame(width: cellSize, height: cellSize)
            }

            if showLabels {
                Text("많음")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "범례: 왼쪽이 적음, 오른쪽이 많음"))
    }

    // MARK: - Private

    /// Opacity levels for the gradient
    private var opacityLevels: [Double] {
        [0.0, 0.25, 0.5, 0.75, 1.0]
    }

    /// Color for each level
    private func cellColor(at index: Int) -> Color {
        let opacity = opacityLevels[index]

        if opacity == 0 {
            // Empty cell color
            return colorScheme == .dark
                ? Color(hex: "#3A3A3C").opacity(0.3)
                : Color(hex: "#E5E5E5").opacity(0.2)
        }

        // Habit color with varying opacity
        return adaptedHabitColor.opacity(opacity)
    }

    /// Habit color adapted for dark mode
    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habitColorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habitColorHex)
    }
}

// MARK: - Compact Legend

/// Compact version of the legend without labels
struct CompactGridLegend: View {
    let habitColorHex: String

    var body: some View {
        GridLegendView(
            habitColorHex: habitColorHex,
            cellSize: 8,
            showLabels: false
        )
    }
}

// MARK: - Preview

#Preview("Grid Legend") {
    VStack(spacing: 24) {
        // With labels
        GridLegendView(habitColorHex: "#4D96FF")

        // Different colors
        ForEach(Constants.colorPresets, id: \.hex) { preset in
            GridLegendView(habitColorHex: preset.hex, cellSize: 12)
        }

        // Compact (no labels)
        CompactGridLegend(habitColorHex: "#FF6B6B")

        // Large cells
        GridLegendView(habitColorHex: "#6BCB77", cellSize: 16)
    }
    .padding()
}
