//
//  HabitCardView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Card view displaying a single habit with mini grid and toggle
struct HabitCardView: View {
    // MARK: - Properties

    /// The habit to display
    let habit: Habit

    /// Completion data for the mini grid
    let completionData: [Date: Bool]

    /// Whether the habit is completed today
    let isTodayCompleted: Bool

    /// Action when checkbox is toggled
    let onToggle: () -> Void

    /// Action when card is long pressed (for editing past dates)
    var onLongPress: (() -> Void)?

    /// Action when card is tapped (for navigation to detail)
    var onCardTap: (() -> Void)?

    // MARK: - Constants

    private let cardHeight: CGFloat = Constants.UI.cardHeight
    private let cornerRadius: CGFloat = Constants.UI.cardCornerRadius
    private let padding: CGFloat = Constants.UI.cardPadding
    private let iconSize: CGFloat = Constants.UI.habitIconSize

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed

    private var habitColor: Color {
        AppColors.habitColor(hex: habit.colorHex, for: colorScheme)
    }

    private var cardBackground: Color {
        AppColors.cardBackground(for: colorScheme)
    }

    private var cardShadowColor: Color {
        AppColors.cardShadow(for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: Icon, Title, Checkbox
            HStack {
                // Icon
                Image(systemName: habit.iconSymbol)
                    .font(.system(size: iconSize))
                    .foregroundColor(habitColor)

                // Title
                Text(habit.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                // Checkbox
                CheckboxButton(
                    isChecked: isTodayCompleted,
                    color: habitColor,
                    action: onToggle
                )
            }

            Spacer()

            // Mini Grid
            MiniGridView(
                completionData: completionData,
                habitColor: habitColor
            )
        }
        .padding(padding)
        .frame(height: cardHeight)
        .background(cardBackground)
        .cornerRadius(cornerRadius)
        .shadow(
            color: cardShadowColor,
            radius: Constants.UI.cardShadowRadius,
            x: 0,
            y: 2
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onCardTap?()
        }
        .onLongPressGesture {
            HapticManager.shared.mediumImpact()
            onLongPress?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.title), \(isTodayCompleted ? String(localized: "완료") : String(localized: "미완료"))")
        .accessibilityHint(String(localized: "탭하여 상세 보기, 길게 눌러 과거 기록 편집"))
    }
}

// MARK: - Preview

#Preview {
    let sampleData: [Date: Bool] = {
        var data: [Date: Bool] = [:]
        let dates = Date.past(days: 14)
        for date in dates {
            data[Calendar.current.startOfDay(for: date)] = Bool.random()
        }
        return data
    }()

    return VStack(spacing: 16) {
        HabitCardView(
            habit: Habit(title: "독서", colorHex: "#FF6B6B", iconSymbol: "book.fill"),
            completionData: sampleData,
            isTodayCompleted: true,
            onToggle: { print("Toggled") }
        )

        HabitCardView(
            habit: Habit(title: "운동", colorHex: "#4D96FF", iconSymbol: "figure.walk"),
            completionData: sampleData,
            isTodayCompleted: false,
            onToggle: { print("Toggled") }
        )

        HabitCardView(
            habit: Habit(title: "영양제", colorHex: "#6BCB77", iconSymbol: "pills.fill"),
            completionData: sampleData,
            isTodayCompleted: false,
            onToggle: { print("Toggled") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
