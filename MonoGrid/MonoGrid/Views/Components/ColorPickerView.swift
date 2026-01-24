//
//  ColorPickerView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Horizontal picker for selecting habit colors from presets
struct ColorPickerView: View {
    // MARK: - Properties

    /// Currently selected color hex
    @Binding var selectedColorHex: String

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let circleSize: CGFloat = 44
    private let checkmarkSize: CGFloat = 20

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Constants.colorPresets, id: \.hex) { preset in
                colorCircle(preset)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func colorCircle(_ preset: (name: String, hex: String)) -> some View {
        let baseColor = Color(hex: preset.hex)
        let adaptedColor = AppColors.habitColor(hex: preset.hex, for: colorScheme)
        let isSelected = selectedColorHex == preset.hex

        Button {
            HapticManager.shared.selectionChanged()
            selectedColorHex = preset.hex
        } label: {
            ZStack {
                Circle()
                    .fill(adaptedColor)
                    .frame(width: circleSize, height: circleSize)

                if isSelected {
                    // Selection indicator with improved dark mode visibility
                    Circle()
                        .strokeBorder(AppColors.selectionIndicator(for: colorScheme), lineWidth: 3)
                        .frame(width: circleSize, height: circleSize)

                    // Outer border for dark mode visibility
                    if colorScheme == .dark {
                        Circle()
                            .strokeBorder(Color.black.opacity(0.3), lineWidth: 1)
                            .frame(width: circleSize + 2, height: circleSize + 2)
                    }

                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.checkmark(for: colorScheme))
                }
            }
            .shadow(color: adaptedColor.opacity(colorScheme == .dark ? 0.3 : 0.4), radius: isSelected ? 4 : 0, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preset.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Compact Variant

/// Compact color picker for inline use
struct CompactColorPicker: View {
    @Binding var selectedColorHex: String

    @Environment(\.colorScheme) private var colorScheme

    private let circleSize: CGFloat = 32

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Constants.colorPresets, id: \.hex) { preset in
                let adaptedColor = AppColors.habitColor(hex: preset.hex, for: colorScheme)
                let isSelected = selectedColorHex == preset.hex

                Button {
                    HapticManager.shared.selectionChanged()
                    selectedColorHex = preset.hex
                } label: {
                    Circle()
                        .fill(adaptedColor)
                        .frame(width: circleSize, height: circleSize)
                        .overlay {
                            if isSelected {
                                Circle()
                                    .strokeBorder(AppColors.selectionIndicator(for: colorScheme), lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedColor = "#FF6B6B"

        var body: some View {
            VStack(spacing: 32) {
                // Selected color preview
                Circle()
                    .fill(Color(hex: selectedColor))
                    .frame(width: 80, height: 80)

                // Standard picker
                VStack(alignment: .leading) {
                    Text("색상")
                        .font(.headline)
                    ColorPickerView(selectedColorHex: $selectedColor)
                }

                Divider()

                // Compact picker
                VStack(alignment: .leading) {
                    Text("컴팩트")
                        .font(.headline)
                    CompactColorPicker(selectedColorHex: $selectedColor)
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
