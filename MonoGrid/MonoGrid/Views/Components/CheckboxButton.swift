//
//  CheckboxButton.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Animated checkbox button for toggling habit completion
struct CheckboxButton: View {
    // MARK: - Properties

    /// Whether the checkbox is checked
    let isChecked: Bool

    /// Color when checked
    let color: Color

    /// Action to perform on tap
    let action: () -> Void

    // MARK: - State

    @State private var isPressed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let touchSize: CGFloat = Constants.UI.checkboxTouchSize
    private let visualSize: CGFloat = Constants.UI.checkboxVisualSize
    private let cornerRadius: CGFloat = Constants.UI.checkboxCornerRadius
    private let borderWidth: CGFloat = Constants.UI.checkboxBorderWidth

    // MARK: - Body

    // MARK: - Computed

    private var adaptedColor: Color {
        AppColors.habitColor(hex: color.hexString, for: colorScheme)
    }

    private var checkboxBorderColor: Color {
        isChecked ? adaptedColor : AppColors.checkboxBorder(for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        Button(action: performAction) {
            ZStack {
                // Background/Border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isChecked ? adaptedColor : Color.clear)
                    .frame(width: visualSize, height: visualSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                checkboxBorderColor,
                                lineWidth: borderWidth
                            )
                    )

                // Checkmark
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.checkmark(for: colorScheme))
                }
            }
            .frame(width: touchSize, height: touchSize)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isChecked ? String(localized: "완료됨") : String(localized: "미완료"))
        .accessibilityHint(String(localized: "이중 탭하여 상태 전환"))
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }

    // MARK: - Actions

    private func performAction() {
        // Haptic feedback
        HapticManager.shared.habitToggle()

        // Animation
        if reduceMotion {
            action()
        } else {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }
    }
}

// MARK: - Preview

#Preview("Unchecked") {
    CheckboxButton(isChecked: false, color: .habitCoral) {
        print("Toggled")
    }
}

#Preview("Checked") {
    CheckboxButton(isChecked: true, color: .habitBlue) {
        print("Toggled")
    }
}

#Preview("All Colors") {
    HStack(spacing: 20) {
        ForEach(Constants.colorPresets, id: \.hex) { preset in
            VStack {
                CheckboxButton(isChecked: true, color: Color(hex: preset.hex)) {}
                CheckboxButton(isChecked: false, color: Color(hex: preset.hex)) {}
            }
        }
    }
    .padding()
}
