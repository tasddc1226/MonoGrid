//
//  GridViewModePicker.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Segmented control for switching between grid view modes
struct GridViewModePicker: View {
    // MARK: - Properties

    @Binding var selectedMode: GridViewMode
    let habitColorHex: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let segmentHeight: CGFloat = 36
    private let cornerRadius: CGFloat = 10

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)

                // Selection indicator
                RoundedRectangle(cornerRadius: cornerRadius - 2)
                    .fill(selectionColor)
                    .frame(width: segmentWidth(in: geometry))
                    .padding(3)
                    .offset(x: selectionOffset(in: geometry))
                    .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7), value: selectedMode)

                // Segment buttons
                HStack(spacing: 0) {
                    ForEach(GridViewMode.allCases) { mode in
                        segmentButton(for: mode, in: geometry)
                    }
                }
            }
        }
        .frame(height: segmentHeight)
    }

    // MARK: - Subviews

    private func segmentButton(for mode: GridViewMode, in geometry: GeometryProxy) -> some View {
        Button {
            if reduceMotion {
                selectedMode = mode
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedMode = mode
                }
            }
            HapticManager.shared.selectionChanged()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 12))

                Text(mode.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedMode == mode ? selectedTextColor : .secondary)
            .frame(width: segmentWidth(in: geometry), height: segmentHeight)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.accessibilityLabel)
        .accessibilityAddTraits(selectedMode == mode ? .isSelected : [])
    }

    // MARK: - Computed Properties

    private func segmentWidth(in geometry: GeometryProxy) -> CGFloat {
        geometry.size.width / CGFloat(GridViewMode.allCases.count)
    }

    private func selectionOffset(in geometry: GeometryProxy) -> CGFloat {
        let index = GridViewMode.allCases.firstIndex(of: selectedMode) ?? 0
        return CGFloat(index) * segmentWidth(in: geometry)
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(hex: "#2C2C2E")
            : Color(hex: "#E5E5EA")
    }

    private var selectionColor: Color {
        colorScheme == .dark
            ? Color(hex: "#3A3A3C")
            : .white
    }

    private var selectedTextColor: Color {
        adaptedHabitColor
    }

    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habitColorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habitColorHex)
    }
}

// MARK: - Simple Style Picker

/// Alternative minimal style picker
struct SimpleGridViewModePicker: View {
    @Binding var selectedMode: GridViewMode
    let habitColorHex: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(GridViewMode.allCases) { mode in
                Button {
                    if reduceMotion {
                        selectedMode = mode
                    } else {
                        withAnimation {
                            selectedMode = mode
                        }
                    }
                    HapticManager.shared.selectionChanged()
                } label: {
                    VStack(spacing: 4) {
                        Text(mode.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedMode == mode ? .semibold : .regular)
                            .foregroundColor(selectedMode == mode ? adaptedHabitColor : .secondary)

                        // Selection indicator line
                        Rectangle()
                            .fill(selectedMode == mode ? adaptedHabitColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habitColorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habitColorHex)
    }
}

// MARK: - Preview

#Preview("Grid View Mode Picker") {
    struct PreviewWrapper: View {
        @State private var mode: GridViewMode = .weekly

        var body: some View {
            VStack(spacing: 32) {
                // Standard picker
                GridViewModePicker(
                    selectedMode: $mode,
                    habitColorHex: "#4D96FF"
                )
                .padding(.horizontal)

                // Different colors
                GridViewModePicker(
                    selectedMode: $mode,
                    habitColorHex: "#FF6B6B"
                )
                .padding(.horizontal)

                // Simple style
                SimpleGridViewModePicker(
                    selectedMode: $mode,
                    habitColorHex: "#6BCB77"
                )
                .padding(.horizontal)

                Text("Selected: \(mode.displayName)")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical)
        }
    }

    return PreviewWrapper()
}
