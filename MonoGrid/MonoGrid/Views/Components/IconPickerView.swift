//
//  IconPickerView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Grid view for selecting SF Symbol icons
struct IconPickerView: View {
    // MARK: - Properties

    /// Currently selected icon symbol
    @Binding var selectedIcon: String

    /// Color for the selected icon
    let color: Color

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    private let iconSize: CGFloat = 28
    private let cellSize: CGFloat = 50

    // MARK: - Computed

    private var adaptedColor: Color {
        AppColors.habitColor(hex: color.hexString, for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Constants.iconPresets, id: \.self) { icon in
                iconCell(icon)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Subviews

    private var cellBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }

    @ViewBuilder
    private func iconCell(_ icon: String) -> some View {
        let isSelected = selectedIcon == icon

        Button {
            HapticManager.shared.selectionChanged()
            selectedIcon = icon
        } label: {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(isSelected ? AppColors.checkmark(for: colorScheme) : adaptedColor)
                .frame(width: cellSize, height: cellSize)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? adaptedColor : cellBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? adaptedColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "fill", with: ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedIcon = "book.fill"

        var body: some View {
            VStack {
                Image(systemName: selectedIcon)
                    .font(.largeTitle)
                    .foregroundColor(.habitCoral)
                    .padding()

                IconPickerView(selectedIcon: $selectedIcon, color: .habitCoral)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
