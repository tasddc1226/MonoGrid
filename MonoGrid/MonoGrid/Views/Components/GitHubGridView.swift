//
//  GitHubGridView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// GitHub-style contribution grid for displaying habit completion history
/// Performance optimized with memoized grid data
struct GitHubGridView: View {
    // MARK: - Properties

    /// Dictionary mapping dates to completion status
    let completionData: [Date: Bool]

    /// Color for completed cells
    let habitColor: Color

    /// Number of days to show (default 365)
    let days: Int

    /// Action when a cell is tapped (date)
    var onCellTap: ((Date) -> Void)?

    // MARK: - Memoized State
    // 매 렌더링마다 재계산 방지
    @State private var cachedGridData: [[Date?]] = []
    @State private var cachedDays: Int = 0

    // MARK: - Constants

    private let cellSize: CGFloat = Constants.UI.gridCellSize
    private let cellGap: CGFloat = Constants.UI.gridCellGap
    private let cellCornerRadius: CGFloat = Constants.UI.gridCellCornerRadius
    private let rowCount: Int = 7 // Days of week (Mon-Sun)

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(
        completionData: [Date: Bool],
        habitColor: Color,
        days: Int = Constants.gridDaysCount,
        onCellTap: ((Date) -> Void)? = nil
    ) {
        self.completionData = completionData
        self.habitColor = habitColor
        self.days = days
        self.onCellTap = onCellTap
    }

    // MARK: - Computed (memoized access)

    /// Grid data organized by weeks (uses cached value)
    private var gridData: [[Date?]] {
        cachedGridData
    }

    // MARK: - Memoization Logic

    /// days가 변경될 때만 재계산
    private func computeGridDataIfNeeded() {
        guard cachedDays != days else { return }
        cachedDays = days
        cachedGridData = computeGridData()
    }

    /// Generate grid data organized by weeks
    /// Uses SharedInstances.calendar for performance
    private func computeGridData() -> [[Date?]] {
        let calendar = SharedInstances.calendar
        let today = SharedInstances.today

        // Get the Monday of the current week
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        guard let currentWeekMonday = calendar.date(from: components) else { return [] }

        // Calculate number of weeks needed
        let weeksCount = (days / 7) + 1

        var weeks: [[Date?]] = []

        for weekOffset in (0..<weeksCount).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekMonday) else {
                continue
            }

            var week: [Date?] = []
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    week.append(nil)
                    continue
                }

                // Only include dates within range and not in the future
                if date <= today {
                    week.append(date)
                } else {
                    week.append(nil)
                }
            }
            weeks.append(week)
        }

        return weeks
    }

    private var incompleteColor: Color {
        AppColors.gridIncomplete(for: colorScheme)
    }

    private var adaptedHabitColor: Color {
        AppColors.habitColor(hex: habitColor.hexString, for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(alignment: .top, spacing: cellGap) {
                    // Week day labels
                    VStack(alignment: .trailing, spacing: cellGap) {
                        ForEach(weekdayLabels, id: \.self) { label in
                            Text(label)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(height: cellSize)
                        }
                    }

                    // Grid
                    LazyHStack(alignment: .top, spacing: cellGap) {
                        ForEach(Array(gridData.enumerated()), id: \.offset) { weekIndex, week in
                            VStack(spacing: cellGap) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    gridCell(for: week[safe: dayIndex] ?? nil)
                                        .id(weekIndex == gridData.count - 1 && dayIndex == 0 ? "today" : nil)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    // Compute grid data if needed
                    computeGridDataIfNeeded()

                    // Scroll to today (rightmost)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
                            proxy.scrollTo("today", anchor: .trailing)
                        }
                    }
                }
                .onChange(of: days) { _, _ in
                    computeGridDataIfNeeded()
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func gridCell(for date: Date?) -> some View {
        if let date = date {
            let isCompleted = completionData[SharedInstances.calendar.startOfDay(for: date)] ?? false
            let isToday = date.isToday
            let isEditable = date.isWithin7Days()

            Button {
                if isEditable {
                    onCellTap?(date)
                }
            } label: {
                RoundedRectangle(cornerRadius: cellCornerRadius)
                    .fill(isCompleted ? adaptedHabitColor : incompleteColor)
                    .frame(width: cellSize, height: cellSize)
                    .overlay {
                        if isToday {
                            RoundedRectangle(cornerRadius: cellCornerRadius)
                                .strokeBorder(adaptedHabitColor, lineWidth: 1.5)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isEditable)
            .accessibilityLabel(accessibilityLabel(for: date, isCompleted: isCompleted))
            .accessibilityHint(isEditable ? String(localized: "이중 탭하여 상태 전환") : "")
        } else {
            // Empty cell for future dates
            RoundedRectangle(cornerRadius: cellCornerRadius)
                .fill(Color.clear)
                .frame(width: cellSize, height: cellSize)
        }
    }

    // MARK: - Helpers

    private var weekdayLabels: [String] {
        // Use shared formatter for performance
        var symbols = SharedInstances.weekdayFormatter.shortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        // Rotate so Monday is first
        let sunday = symbols.removeFirst()
        symbols.append(sunday)
        return symbols.map { String($0.prefix(1)) }
    }

    private func accessibilityLabel(for date: Date, isCompleted: Bool) -> String {
        let dateString = date.longFormatted
        let status = isCompleted ? String(localized: "완료") : String(localized: "미완료")
        return "\(dateString), \(status)"
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    let sampleData: [Date: Bool] = {
        var data: [Date: Bool] = [:]
        let dates = Date.past(days: 365)
        for date in dates {
            data[SharedInstances.calendar.startOfDay(for: date)] = Bool.random()
        }
        return data
    }()

    return VStack {
        GitHubGridView(
            completionData: sampleData,
            habitColor: .habitCoral
        ) { date in
            print("Tapped: \(date)")
        }
        .frame(height: 100)

        GitHubGridView(
            completionData: sampleData,
            habitColor: .habitBlue
        )
        .frame(height: 100)
    }
    .padding()
}
