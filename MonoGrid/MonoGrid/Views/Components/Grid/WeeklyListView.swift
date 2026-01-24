//
//  WeeklyListView.swift
//  MonoGrid
//
//  Created on 2026-01-24.
//

import SwiftUI

/// Vertical list layout for weekly habit tracking
/// Replaces WeeklyGridView for better Korean text display on narrow screens
struct WeeklyListView: View {
    // MARK: - Properties

    let habitId: UUID
    let habitColorHex: String
    @Binding var currentWeekStart: Date
    let completionData: [Date: Bool]

    /// Callback when a day is tapped
    var onDayTap: ((Date) -> Void)?

    /// Callback when week changes
    var onWeekChange: ((Date) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let rowSpacing: CGFloat = 4

    // MARK: - Computed Properties

    private var calendar: Calendar { Calendar.current }

    private var weekDates: [Date] {
        DateRangeCalculator.datesInWeek(containing: currentWeekStart)
    }

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private var canNavigateForward: Bool {
        guard let lastDay = weekDates.last else { return false }
        return lastDay < today
    }

    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habitColorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habitColorHex)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(weekDates, id: \.self) { date in
                let normalizedDate = calendar.startOfDay(for: date)
                DayRowView(
                    date: date,
                    isCompleted: completionData[normalizedDate],
                    isToday: normalizedDate == today,
                    isFuture: normalizedDate > today,
                    habitColor: adaptedHabitColor
                ) {
                    HapticManager.shared.lightImpact()
                    onDayTap?(normalizedDate)
                }
            }
        }
        .gesture(swipeGesture)
    }

    // MARK: - Navigation

    private func navigateWeek(by value: Int) {
        if value > 0 {
            currentWeekStart = DateRangeCalculator.nextWeek(from: currentWeekStart)
        } else {
            currentWeekStart = DateRangeCalculator.previousWeek(from: currentWeekStart)
        }
        onWeekChange?(currentWeekStart)
    }

    /// Swipe gesture for week navigation
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                if value.translation.width < -50 && canNavigateForward {
                    HapticManager.shared.selectionChanged()
                    if reduceMotion {
                        navigateWeek(by: 1)
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            navigateWeek(by: 1)
                        }
                    }
                } else if value.translation.width > 50 {
                    HapticManager.shared.selectionChanged()
                    if reduceMotion {
                        navigateWeek(by: -1)
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            navigateWeek(by: -1)
                        }
                    }
                }
            }
    }
}

// MARK: - Day Row Component

/// Individual row for a single day in the weekly list
private struct DayRowView: View {
    let date: Date
    let isCompleted: Bool?
    let isToday: Bool
    let isFuture: Bool
    let habitColor: Color
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var calendar: Calendar { Calendar.current }

    // MARK: - Constants

    private let rowHeight: CGFloat = 56
    private let cornerRadius: CGFloat = 12
    private let checkboxSize: CGFloat = 28
    private let touchTargetSize: CGFloat = 44

    // MARK: - Body

    var body: some View {
        Button(action: {
            if !isFuture {
                onTap()
            }
        }) {
            HStack(spacing: 0) {
                // Day name section
                dayNameSection

                Spacer()

                // Date section
                dateSection

                Spacer()

                // Checkbox section
                checkboxSection
            }
            .padding(.horizontal, 16)
            .frame(height: rowHeight)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(todayBorder)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .contextMenu {
            if !isFuture {
                Button {
                    onTap()
                } label: {
                    Label(
                        isCompleted == true ? "미완료로 변경" : "완료로 변경",
                        systemImage: isCompleted == true ? "xmark.circle" : "checkmark.circle"
                    )
                }
            }

            Button {
                // View date info - no action needed, just informational
            } label: {
                Label(dateInfoText, systemImage: "info.circle")
            }
            .disabled(true)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isFuture ? "" : String(localized: "두 번 탭하여 완료 상태 전환"))
    }

    // MARK: - Day Name Section

    private var dayNameSection: some View {
        Text(dayName)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(isToday ? habitColor : .secondary)
            .frame(width: touchTargetSize, alignment: .leading)
    }

    // MARK: - Date Section

    private var dateSection: some View {
        HStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))일")
                .font(.system(size: 17))
                .foregroundColor(isFuture ? .secondary.opacity(0.4) : .primary)

            if isToday {
                Text("오늘")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(habitColor)
            }
        }
    }

    // MARK: - Checkbox Section

    @ViewBuilder
    private var checkboxSection: some View {
        ZStack {
            if isFuture {
                // Future: disabled indicator
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: checkboxSize, height: checkboxSize)
            } else if let completed = isCompleted, completed {
                // Completed: filled checkbox
                RoundedRectangle(cornerRadius: 6)
                    .fill(habitColor)
                    .frame(width: checkboxSize, height: checkboxSize)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                // Incomplete: empty checkbox
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: checkboxSize, height: checkboxSize)
            }
        }
        .frame(width: touchTargetSize, height: touchTargetSize)
    }

    // MARK: - Styling

    private var rowBackground: Color {
        if isFuture {
            return colorScheme == .dark ? Color(hex: "#1C1C1E") : Color(hex: "#F5F5F5")
        }
        if let completed = isCompleted, completed {
            return habitColor.opacity(0.1)
        }
        return colorScheme == .dark ? Color(hex: "#2C2C2E") : Color(hex: "#F2F2F7")
    }

    @ViewBuilder
    private var todayBorder: some View {
        if isToday {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(habitColor, lineWidth: 2)
        }
    }

    // MARK: - Helpers

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private var dateInfoText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: date)
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateString = formatter.string(from: date)

        if let completed = isCompleted {
            return completed
                ? String(localized: "\(dateString), 완료됨")
                : String(localized: "\(dateString), 미완료")
        }
        return String(localized: "\(dateString), 기록 없음")
    }
}

// MARK: - Preview

#Preview("Weekly List View") {
    struct PreviewWrapper: View {
        @State private var weekStart = DateRangeCalculator.startOfWeek(for: Date())

        var sampleData: [Date: Bool] {
            var data: [Date: Bool] = [:]
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            for i in 0..<14 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    data[date] = Bool.random()
                }
            }
            return data
        }

        var body: some View {
            WeeklyListView(
                habitId: UUID(),
                habitColorHex: "#6BCB77",
                currentWeekStart: $weekStart,
                completionData: sampleData
            ) { date in
                print("Tapped: \(date)")
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
