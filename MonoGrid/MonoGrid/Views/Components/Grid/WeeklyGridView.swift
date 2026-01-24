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

    private let cellSpacing: CGFloat = 8

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
        VStack(spacing: 16) {
            // Week header with navigation
            weekHeader

            // Week grid
            weekGrid
        }
    }

    // MARK: - Subviews

    /// Week header with navigation arrows
    private var weekHeader: some View {
        HStack {
            Button {
                navigateWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            Spacer()

            Text(weekTitle)
                .font(.headline)

            Spacer()

            Button {
                navigateWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(canNavigateForward ? .primary : .secondary.opacity(0.3))
            }
            .disabled(!canNavigateForward)
        }
        .padding(.horizontal, 8)
    }

    /// Main week grid (4 columns x 2 rows layout)
    private var weekGrid: some View {
        VStack(spacing: cellSpacing) {
            // First row: Mon-Thu (4 days)
            HStack(spacing: cellSpacing) {
                ForEach(0..<4, id: \.self) { index in
                    if index < weekDates.count {
                        dayCellView(for: weekDates[index])
                    }
                }
            }

            // Second row: Fri-Sun (3 days)
            HStack(spacing: cellSpacing) {
                ForEach(4..<7, id: \.self) { index in
                    if index < weekDates.count {
                        dayCellView(for: weekDates[index])
                    }
                }
                // Empty space for 4th column
                Color.clear
                    .frame(maxWidth: .infinity)
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
        let isEditable = normalizedDate.isWithin(days: Constants.editableDaysRange)

        return Button {
            if isEditable && !isFuture {
                HapticManager.shared.lightImpact()
                onDayTap?(normalizedDate)
            }
        } label: {
            VStack(spacing: 8) {
                // Day name
                Text(dayName(for: date))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isToday ? adaptedHabitColor : .secondary)

                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.title2)
                    .fontWeight(isToday ? .bold : .regular)
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
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(cellBackground(isCompleted: isCompleted, isToday: isToday, isFuture: isFuture))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isToday ? adaptedHabitColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isFuture || !isEditable)
        .contextMenu {
            if !isFuture && isEditable {
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
        .accessibilityHint(isEditable && !isFuture ? String(localized: "두 번 탭하여 전환") : "")
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
                .frame(width: 48, height: 48)
        } else if let completed = isCompleted, completed {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(adaptedHabitColor)
                    .frame(width: 48, height: 48)

                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        } else {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 2)
                .frame(width: 48, height: 48)
        }
    }

    // MARK: - Helpers

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func dayNumberColor(isFuture: Bool) -> Color {
        isFuture ? .secondary.opacity(0.5) : .primary
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
