//
//  MonthlyGridView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Calendar-style monthly grid view
struct MonthlyGridView: View {
    // MARK: - Properties

    let habitId: UUID
    let habitColorHex: String
    @Binding var currentDate: Date
    let completionData: [Date: Bool]

    /// Callback when a cell is tapped
    var onCellTap: ((Date) -> Void)?

    /// Callback when month changes
    var onMonthChange: ((Int, Int) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let cellSize: CGFloat = 44
    private let cellGap: CGFloat = 4
    private let weekDays = ["일", "월", "화", "수", "목", "금", "토"]

    // MARK: - Computed Properties

    private var calendar: Calendar { Calendar.current }

    private var yearMonth: (year: Int, month: Int) {
        DateRangeCalculator.yearMonth(from: currentDate)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentDate)
    }

    /// Grid cells for the month (including leading/trailing empty cells)
    private var gridCells: [GridCell] {
        var cells: [GridCell] = []

        guard let range = DateRangeCalculator.monthRange(year: yearMonth.year, month: yearMonth.month) else {
            return cells
        }

        // Get the weekday of the first day (1=Sunday, 2=Monday, ...)
        let firstWeekday = calendar.component(.weekday, from: range.start)

        // Add empty cells for days before the month starts
        for _ in 1..<firstWeekday {
            cells.append(GridCell(date: nil, dayNumber: 0))
        }

        // Add cells for each day of the month
        let daysInMonth = DateRangeCalculator.datesInMonth(year: yearMonth.year, month: yearMonth.month)
        for date in daysInMonth {
            let dayNumber = calendar.component(.day, from: date)
            cells.append(GridCell(date: date, dayNumber: dayNumber))
        }

        // Add trailing empty cells to complete the last row
        let remainder = cells.count % 7
        if remainder > 0 {
            for _ in 0..<(7 - remainder) {
                cells.append(GridCell(date: nil, dayNumber: 0))
            }
        }

        return cells
    }

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Month header with navigation
            monthHeader

            // Weekday headers
            weekdayHeader

            // Calendar grid
            calendarGrid
        }
    }

    // MARK: - Subviews

    /// Month header with navigation arrows
    private var monthHeader: some View {
        HStack {
            Button {
                navigateMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            Spacer()

            Text(monthTitle)
                .font(.headline)

            Spacer()

            Button {
                navigateMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(canNavigateForward ? .primary : .secondary.opacity(0.3))
            }
            .disabled(!canNavigateForward)
        }
        .padding(.horizontal, 8)
    }

    /// Weekday labels row
    private var weekdayHeader: some View {
        HStack(spacing: cellGap) {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(day == "일" || day == "토" ? .secondary : .primary)
                    .frame(width: cellSize)
            }
        }
    }

    /// Main calendar grid
    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.fixed(cellSize), spacing: cellGap), count: 7)

        return LazyVGrid(columns: columns, spacing: cellGap) {
            ForEach(Array(gridCells.enumerated()), id: \.offset) { _, cell in
                if let date = cell.date {
                    dayCellView(date: date, dayNumber: cell.dayNumber)
                } else {
                    Color.clear
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
        .gesture(swipeGesture)
    }

    /// Individual day cell
    private func dayCellView(date: Date, dayNumber: Int) -> some View {
        let normalizedDate = calendar.startOfDay(for: date)
        let isCompleted = completionData[normalizedDate]
        let isToday = normalizedDate == today
        let isFuture = normalizedDate > today
        let isEditable = normalizedDate.isWithin(days: Constants.editableDaysRange)

        return Button {
            if isEditable && !isFuture {
                HapticManager.shared.lightImpact()
                onCellTap?(normalizedDate)
            }
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(cellBackgroundColor(isCompleted: isCompleted, isFuture: isFuture))
                    .frame(width: cellSize, height: cellSize)

                // Today border
                if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(todayBorderColor, lineWidth: 2)
                        .frame(width: cellSize, height: cellSize)
                }

                // Day number and completion indicator
                VStack(spacing: 2) {
                    Text("\(dayNumber)")
                        .font(.system(size: 12, weight: isToday ? .bold : .regular))
                        .foregroundColor(dayNumberColor(isCompleted: isCompleted, isFuture: isFuture, isToday: isToday))

                    // Completion dot
                    if let completed = isCompleted, completed {
                        Circle()
                            .fill(adaptedHabitColor)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !isFuture && isEditable {
                Button {
                    HapticManager.shared.lightImpact()
                    onCellTap?(normalizedDate)
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
    }

    private func dateInfoText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: date)
    }

    // MARK: - Colors

    private func cellBackgroundColor(isCompleted: Bool?, isFuture: Bool) -> Color {
        if isFuture {
            return colorScheme == .dark ? Color(hex: "#1C1C1E") : Color(hex: "#F5F5F5")
        }
        if let completed = isCompleted, completed {
            return adaptedHabitColor.opacity(0.15)
        }
        return colorScheme == .dark ? Color(hex: "#2C2C2E") : Color(hex: "#F2F2F7")
    }

    private func dayNumberColor(isCompleted: Bool?, isFuture: Bool, isToday: Bool) -> Color {
        if isFuture {
            return .secondary.opacity(0.5)
        }
        if isToday {
            return .primary
        }
        return .primary.opacity(0.8)
    }

    private var todayBorderColor: Color {
        adaptedHabitColor
    }

    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habitColorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habitColorHex)
    }

    // MARK: - Navigation

    private var canNavigateForward: Bool {
        let nextMonth = DateRangeCalculator.nextMonth(from: currentDate)
        return calendar.startOfDay(for: nextMonth) <= today
    }

    private func navigateMonth(by value: Int) {
        if value > 0 {
            currentDate = DateRangeCalculator.nextMonth(from: currentDate)
        } else {
            currentDate = DateRangeCalculator.previousMonth(from: currentDate)
        }
        let ym = DateRangeCalculator.yearMonth(from: currentDate)
        onMonthChange?(ym.year, ym.month)
    }

    /// Swipe gesture for month navigation
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                if value.translation.width < -50 && canNavigateForward {
                    HapticManager.shared.selectionChanged()
                    if reduceMotion {
                        navigateMonth(by: 1)
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            navigateMonth(by: 1)
                        }
                    }
                } else if value.translation.width > 50 {
                    HapticManager.shared.selectionChanged()
                    if reduceMotion {
                        navigateMonth(by: -1)
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            navigateMonth(by: -1)
                        }
                    }
                }
            }
    }

    // MARK: - Accessibility

    private func accessibilityLabel(for date: Date, isCompleted: Bool?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateString = formatter.string(from: date)

        if let completed = isCompleted {
            return completed
                ? String(localized: "\(dateString), 완료")
                : String(localized: "\(dateString), 미완료")
        }
        return String(localized: "\(dateString), 기록 없음")
    }
}

// MARK: - Supporting Types

private extension MonthlyGridView {
    struct GridCell {
        let date: Date?
        let dayNumber: Int
    }
}

// MARK: - Preview

#Preview("Monthly Grid") {
    struct PreviewWrapper: View {
        @State private var currentDate = Date()

        var sampleData: [Date: Bool] {
            var data: [Date: Bool] = [:]
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            for i in 0..<60 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    data[date] = Bool.random()
                }
            }
            return data
        }

        var body: some View {
            MonthlyGridView(
                habitId: UUID(),
                habitColorHex: "#4D96FF",
                currentDate: $currentDate,
                completionData: sampleData
            )
            .padding()
        }
    }

    return PreviewWrapper()
}
