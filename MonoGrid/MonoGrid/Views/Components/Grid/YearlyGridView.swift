//
//  YearlyGridView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Full 365-day GitHub-style contribution graph
struct YearlyGridView: View {
    // MARK: - Properties

    let habitId: UUID
    let habitColorHex: String
    let year: Int
    let completionData: [Date: Bool]

    /// Optional callback when a cell is tapped
    var onCellTap: ((Date) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let cellSize: CGFloat = 10
    private let cellGap: CGFloat = 2
    private let rowCount = 7  // Days of week
    private let dayLabelWidth: CGFloat = 24
    private let monthLabelHeight: CGFloat = 16

    // MARK: - Computed Properties

    /// Generates week columns for the year
    private var weekColumns: [[Date]] {
        let dates = DateRangeCalculator.datesInYear(year)
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []

        for date in dates {
            let weekday = Calendar.current.component(.weekday, from: date)
            // Start new week on Monday (weekday 2)
            if weekday == 2 && !currentWeek.isEmpty {
                weeks.append(currentWeek)
                currentWeek = []
            }
            currentWeek.append(date)
        }

        // Add remaining days
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }

        return weeks
    }

    /// Month labels with their starting positions
    private var monthLabels: [(name: String, weekIndex: Int)] {
        var labels: [(String, Int)] = []
        var currentMonth = 0
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        for (weekIndex, week) in weekColumns.enumerated() {
            if let firstDay = week.first {
                let month = Calendar.current.component(.month, from: firstDay)
                if month != currentMonth {
                    currentMonth = month
                    labels.append((formatter.string(from: firstDay), weekIndex))
                }
            }
        }

        return labels
    }

    /// Today's date for highlighting
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Month labels
            monthLabelsView

            // Grid with day labels
            HStack(alignment: .top, spacing: 0) {
                // Day of week labels (Mon, Wed, Fri)
                dayLabelsView

                // Main grid
                gridView
            }
        }
    }

    // MARK: - Subviews

    /// Month labels at the top
    private var monthLabelsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // Spacer for day labels
                Color.clear
                    .frame(width: dayLabelWidth)

                // Month labels positioned over their weeks
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        ForEach(monthLabels, id: \.weekIndex) { label in
                            Text(label.name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .offset(x: CGFloat(label.weekIndex) * (cellSize + cellGap))
                        }
                    }
                }
                .frame(width: CGFloat(weekColumns.count) * (cellSize + cellGap), height: monthLabelHeight)
            }
        }
    }

    /// Day of week labels (Mon, Wed, Fri)
    private var dayLabelsView: some View {
        VStack(spacing: cellGap) {
            ForEach(0..<rowCount, id: \.self) { dayIndex in
                Text(dayLabel(for: dayIndex))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(width: dayLabelWidth, height: cellSize, alignment: .trailing)
            }
        }
    }

    /// Main grid of cells
    private var gridView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: cellGap) {
                ForEach(Array(weekColumns.enumerated()), id: \.offset) { _, week in
                    weekColumn(for: week)
                }
            }
            .padding(.trailing, 8)
        }
    }

    /// Single week column (7 cells)
    private func weekColumn(for dates: [Date]) -> some View {
        VStack(spacing: cellGap) {
            // Fill empty slots at the start of the year
            let firstWeekday = Calendar.current.component(.weekday, from: dates.first ?? Date())
            let mondayBasedWeekday = (firstWeekday + 5) % 7  // Convert to Monday=0

            ForEach(0..<rowCount, id: \.self) { dayIndex in
                if dayIndex < mondayBasedWeekday && dates == weekColumns.first {
                    // Empty cell for days before year starts
                    Color.clear
                        .frame(width: cellSize, height: cellSize)
                } else {
                    let dateIndex = dayIndex - (dates == weekColumns.first ? mondayBasedWeekday : 0)
                    if dateIndex >= 0 && dateIndex < dates.count {
                        cellView(for: dates[dateIndex])
                    } else if dates == weekColumns.last {
                        // Empty cell for days after year ends
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    } else {
                        cellView(for: dates[min(dateIndex, dates.count - 1)])
                    }
                }
            }
        }
    }

    /// Individual cell view
    private func cellView(for date: Date) -> some View {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let isCompleted = completionData[normalizedDate]
        let isToday = normalizedDate == today
        let isFuture = normalizedDate > today
        let isEditable = normalizedDate.isWithin(days: Constants.editableDaysRange)

        return BaseGridCell(
            isCompleted: isCompleted,
            habitColorHex: habitColorHex,
            size: cellSize,
            isToday: isToday,
            isFuture: isFuture
        )
        .onTapGesture {
            if !isFuture && isEditable {
                onCellTap?(normalizedDate)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(cellAccessibilityLabel(date: date, isCompleted: isCompleted, isToday: isToday))
        .accessibilityHint(cellAccessibilityHint(isFuture: isFuture, isEditable: isEditable))
        .accessibilityAddTraits(isFuture || !isEditable ? [] : .isButton)
    }

    // MARK: - Accessibility Helpers

    private func cellAccessibilityLabel(date: Date, isCompleted: Bool?, isToday: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        let dateStr = formatter.string(from: date)

        var status: String
        if let completed = isCompleted {
            status = completed ? String(localized: "완료") : String(localized: "미완료")
        } else {
            status = String(localized: "기록 없음")
        }

        if isToday {
            return String(localized: "오늘, \(dateStr), \(status)")
        }
        return "\(dateStr), \(status)"
    }

    private func cellAccessibilityHint(isFuture: Bool, isEditable: Bool) -> String {
        if isFuture {
            return String(localized: "미래 날짜는 수정할 수 없습니다")
        }
        if !isEditable {
            return String(localized: "7일 이전 기록은 수정할 수 없습니다")
        }
        return String(localized: "두 번 탭하여 완료 상태 전환")
    }

    /// Day label for row index (Mon=0, Tue=1, ...)
    private func dayLabel(for index: Int) -> String {
        // Show labels only for Mon, Wed, Fri
        switch index {
        case 0: return "월"
        case 2: return "수"
        case 4: return "금"
        default: return ""
        }
    }
}

// MARK: - Preview

#Preview("Yearly Grid") {
    let sampleData: [Date: Bool] = {
        var data: [Date: Bool] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for i in 0..<365 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                data[date] = Bool.random()
            }
        }
        return data
    }()

    return ScrollView {
        VStack(spacing: 20) {
            YearlyGridView(
                habitId: UUID(),
                habitColorHex: "#4D96FF",
                year: 2026,
                completionData: sampleData
            )

            YearlyGridView(
                habitId: UUID(),
                habitColorHex: "#FF6B6B",
                year: 2026,
                completionData: sampleData
            )
        }
        .padding()
    }
}
