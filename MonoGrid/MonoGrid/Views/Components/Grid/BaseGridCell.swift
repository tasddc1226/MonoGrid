//
//  BaseGridCell.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Reusable grid cell component with configurable size and state
struct BaseGridCell: View {
    // MARK: - Properties

    let state: GridCellState
    let habitColorHex: String
    let size: CGFloat
    let isToday: Bool
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(
        state: GridCellState,
        habitColorHex: String,
        size: CGFloat = 10,
        isToday: Bool = false,
        cornerRadius: CGFloat? = nil
    ) {
        self.state = state
        self.habitColorHex = habitColorHex
        self.size = size
        self.isToday = isToday
        self.cornerRadius = cornerRadius ?? max(2, size * 0.2)
    }

    // MARK: - Body

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(fillColor)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(todayBorderColor, lineWidth: isToday ? 1.5 : 0)
            )
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
    }

    // MARK: - Computed Properties

    /// Fill color based on state and color scheme
    private var fillColor: Color {
        switch state {
        case .empty:
            return emptyColor
        case .incomplete:
            return incompleteColor
        case .complete:
            return completeColor
        case .future:
            return futureColor
        }
    }

    /// Color for empty cells (no log data)
    private var emptyColor: Color {
        colorScheme == .dark
            ? Color(hex: "#3A3A3C").opacity(0.3)
            : Color(hex: "#E5E5E5").opacity(0.1)
    }

    /// Color for incomplete cells
    private var incompleteColor: Color {
        colorScheme == .dark
            ? Color(hex: "#3A3A3C").opacity(0.4)
            : Color(hex: "#E5E5E5").opacity(0.2)
    }

    /// Color for completed cells (full habit color)
    private var completeColor: Color {
        adaptedHabitColor
    }

    /// Color for future cells (disabled appearance)
    private var futureColor: Color {
        colorScheme == .dark
            ? Color(hex: "#1C1C1E")
            : Color(hex: "#F5F5F5")
    }

    /// Today border color
    private var todayBorderColor: Color {
        guard isToday else { return .clear }
        return colorScheme == .dark
            ? Color.white.opacity(0.3)
            : Color.black.opacity(0.2)
    }

    /// Habit color adapted for dark mode
    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habitColorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habitColorHex)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        switch state {
        case .empty:
            return String(localized: "기록 없음")
        case .incomplete:
            return String(localized: "미완료")
        case .complete:
            return String(localized: "완료")
        case .future:
            return String(localized: "미래 날짜")
        }
    }

    private var accessibilityHint: String {
        switch state {
        case .empty, .incomplete, .complete:
            return String(localized: "두 번 탭하여 전환")
        case .future:
            return String(localized: "미래 날짜는 수정할 수 없습니다")
        }
    }
}

// MARK: - Convenience Initializers

extension BaseGridCell {
    /// Creates a cell from GridCellData
    init(data: GridCellData, habitColorHex: String, size: CGFloat = 10) {
        self.init(
            state: data.state,
            habitColorHex: habitColorHex,
            size: size,
            isToday: data.isToday
        )
    }

    /// Creates a cell from completion status
    init(
        isCompleted: Bool?,
        habitColorHex: String,
        size: CGFloat = 10,
        isToday: Bool = false,
        isFuture: Bool = false
    ) {
        self.init(
            state: GridCellState(isCompleted: isCompleted, isFuture: isFuture),
            habitColorHex: habitColorHex,
            size: size,
            isToday: isToday
        )
    }
}

// MARK: - Preview

#Preview("Grid Cell States") {
    VStack(spacing: 20) {
        // Light mode
        HStack(spacing: 10) {
            BaseGridCell(state: .empty, habitColorHex: "#4D96FF", size: 20)
            BaseGridCell(state: .incomplete, habitColorHex: "#4D96FF", size: 20)
            BaseGridCell(state: .complete, habitColorHex: "#4D96FF", size: 20)
            BaseGridCell(state: .future, habitColorHex: "#4D96FF", size: 20)
            BaseGridCell(state: .complete, habitColorHex: "#4D96FF", size: 20, isToday: true)
        }

        // Different sizes
        HStack(spacing: 10) {
            BaseGridCell(state: .complete, habitColorHex: "#FF6B6B", size: 8)
            BaseGridCell(state: .complete, habitColorHex: "#FF6B6B", size: 12)
            BaseGridCell(state: .complete, habitColorHex: "#FF6B6B", size: 16)
            BaseGridCell(state: .complete, habitColorHex: "#FF6B6B", size: 24)
        }

        // All habit colors
        HStack(spacing: 10) {
            ForEach(Constants.colorPresets, id: \.hex) { preset in
                BaseGridCell(state: .complete, habitColorHex: preset.hex, size: 16)
            }
        }
    }
    .padding()
}
