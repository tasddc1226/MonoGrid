//
//  WeeklyGridView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Detailed 7-day week view with large toggleable cells
struct WeeklyGridView: View {
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

    private let cellSpacing: CGFloat = 4

    // MARK: - Computed Properties

    private var calendar: Calendar { Calendar.current }

    private var weekDates: [Date] {
        DateRangeCalculator.datesInWeek(containing: currentWeekStart)
    }

    private var weekTitle: String {
        guard let first = weekDates.first, let last = weekDates.last else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"

        let startStr = formatter.string(from: first)
        let endStr = formatter.string(from: last)

        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let year = yearFormatter.string(from: first)

        return "\(startStr) - \(endStr), \(year)"
    }

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private var canNavigateForward: Bool {
        guard let lastDay = weekDates.last else { return false }
        return lastDay < today
    }

    // MARK: - Body

    var body: some View {
        // Week grid only (navigation handled by parent HabitDetailGridView)
        weekGrid
    }

    // MARK: - Subviews

    /// Main week grid (7 columns x 1 row layout)
    private var weekGrid: some View {
        HStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { index in
                if index < weekDates.count {
                    dayCellView(for: weekDates[index])
                }
            }
        }
        .gesture(swipeGesture)
    }

    /// Individual day cell
    private func dayCellView(for date: Date) -> some View {
        let normalizedDate = calendar.startOfDay(for: date)
        let isCompleted = completionData[normalizedDate]
        let isToday = normalizedDate == today
        let isFuture = normalizedDate > today

        return Button {
            if !isFuture {
                HapticManager.shared.lightImpact()
                onDayTap?(normalizedDate)
            }
        } label: {
            VStack(spacing: 6) {
                // Day name
                Text(dayName(for: date))
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(isToday ? adaptedHabitColor : .secondary)

                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 20, weight: isToday ? .bold : .medium))
                    .foregroundColor(dayNumberColor(isFuture: isFuture))

                // Today label
                if isToday {
                    Text("오늘")
                        .font(.caption2)
                        .foregroundColor(adaptedHabitColor)
                } else {
                    Text(" ")
                        .font(.caption2)
                }

                Spacer()

                // Completion indicator
                completionIndicator(isCompleted: isCompleted, isFuture: isFuture)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(cellBackground(isCompleted: isCompleted, isToday: isToday, isFuture: isFuture))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isToday ? adaptedHabitColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .contextMenu {
            if !isFuture {
                Button {
                    HapticManager.shared.lightImpact()
                    onDayTap?(normalizedDate)
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
                Label(dateInfoText(for: date), systemImage: "info.circle")
            }
            .disabled(true)
        }
        .accessibilityLabel(accessibilityLabel(for: date, isCompleted: isCompleted))
        .accessibilityHint(!isFuture ? String(localized: "두 번 탭하여 전환") : "")
    }

    private func dateInfoText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: date)
    }

    /// Completion indicator view
    @ViewBuilder
    private func completionIndicator(isCompleted: Bool?, isFuture: Bool) -> some View {
        if isFuture {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 44, height: 44)
        } else if let completed = isCompleted, completed {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(adaptedHabitColor)
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        } else {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 2)
                .frame(width: 44, height: 44)
        }
    }

    // MARK: - Helpers

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func dayNumberColor(isFuture: Bool) -> Color {
        isFuture ? .secondary.opacity(0.4) : .primary
    }

    private func cellBackground(isCompleted: Bool?, isToday: Bool, isFuture: Bool) -> Color {
        if isFuture {
            return colorScheme == .dark ? Color(hex: "#1C1C1E") : Color(hex: "#F5F5F5")
        }
        if let completed = isCompleted, completed {
            return adaptedHabitColor.opacity(0.1)
        }
        return colorScheme == .dark ? Color(hex: "#2C2C2E") : Color(hex: "#F2F2F7")
    }

    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habitColorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habitColorHex)
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

    // MARK: - Accessibility

    private func accessibilityLabel(for date: Date, isCompleted: Bool?) -> String {
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

#Preview("Weekly Grid") {
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
            WeeklyGridView(
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
