//
//  YearlyGridView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Full 365-day GitHub-style contribution graph
/// Performance optimized with memoized computed properties
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

    // MARK: - Memoized State
    // 매 렌더링마다 재계산 방지: 53주 × 7일 = 371회 → 연도 변경 시 1회
    @State private var cachedWeekColumns: [[Date]] = []
    @State private var cachedMonthLabels: [(name: String, weekIndex: Int)] = []
    @State private var cachedYear: Int = 0

    // MARK: - Constants

    private let cellSize: CGFloat = 10
    private let cellGap: CGFloat = 2
    private let rowCount = 7  // Days of week
    private let dayLabelWidth: CGFloat = 24
    private let monthLabelHeight: CGFloat = 16

    // MARK: - Computed Properties (memoized access)

    /// Generates week columns for the year (uses cached value)
    private var weekColumns: [[Date]] {
        cachedWeekColumns
    }

    /// Month labels with their starting positions (uses cached value)
    private var monthLabels: [(name: String, weekIndex: Int)] {
        cachedMonthLabels
    }

    /// Today's date for highlighting (uses shared instance)
    private var today: Date {
        SharedInstances.today
    }

    // MARK: - Memoization Logic

    /// 연도가 변경될 때만 재계산
    private func computeGridDataIfNeeded() {
        guard cachedYear != year else { return }
        cachedYear = year
        cachedWeekColumns = computeWeekColumns()
        cachedMonthLabels = computeMonthLabels(from: cachedWeekColumns)
    }

    private func computeWeekColumns() -> [[Date]] {
        let calendar = SharedInstances.calendar
        let dates = DateRangeCalculator.datesInYear(year)
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []

        for date in dates {
            let weekday = calendar.component(.weekday, from: date)
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

    private func computeMonthLabels(from weeks: [[Date]]) -> [(name: String, weekIndex: Int)] {
        let calendar = SharedInstances.calendar
        let formatter = SharedInstances.monthLabelFormatter
        var labels: [(String, Int)] = []
        var currentMonth = 0

        for (weekIndex, week) in weeks.enumerated() {
            if let firstDay = week.first {
                let month = calendar.component(.month, from: firstDay)
                if month != currentMonth {
                    currentMonth = month
                    labels.append((formatter.string(from: firstDay), weekIndex))
                }
            }
        }

        return labels
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
        .onAppear {
            computeGridDataIfNeeded()
        }
        .onChange(of: year) { _, _ in
            computeGridDataIfNeeded()
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
            let firstWeekday = SharedInstances.calendar.component(.weekday, from: dates.first ?? Date())
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
        let calendar = SharedInstances.calendar
        let normalizedDate = calendar.startOfDay(for: date)
        let isCompleted = completionData[normalizedDate]
        let isToday = normalizedDate == today
        let isFuture = normalizedDate > today

        return BaseGridCell(
            isCompleted: isCompleted,
            habitColorHex: habitColorHex,
            size: cellSize,
            isToday: isToday,
            isFuture: isFuture
        )
        .onTapGesture {
            if !isFuture {
                onCellTap?(normalizedDate)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(cellAccessibilityLabel(date: date, isCompleted: isCompleted, isToday: isToday))
        .accessibilityHint(cellAccessibilityHint(isFuture: isFuture))
        .accessibilityAddTraits(isFuture ? [] : .isButton)
    }

    // MARK: - Accessibility Helpers

    private func cellAccessibilityLabel(date: Date, isCompleted: Bool?, isToday: Bool) -> String {
        let dateStr = SharedInstances.accessibilityDateFormatter.string(from: date)

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

    private func cellAccessibilityHint(isFuture: Bool) -> String {
        if isFuture {
            return String(localized: "미래 날짜는 수정할 수 없습니다")
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
