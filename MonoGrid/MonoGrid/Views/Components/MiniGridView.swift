//
//  MiniGridView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Mini heatmap grid showing the last 2 weeks of habit completion
struct MiniGridView: View {
    // MARK: - Properties

    /// Dictionary mapping dates to completion status
    let completionData: [Date: Bool]

    /// Color for completed cells
    let habitColor: Color

    /// Number of days to show (default 14)
    let days: Int

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let cellSize: CGFloat = Constants.UI.miniGridCellSize
    private let cellGap: CGFloat = Constants.UI.gridCellGap
    private let cellCornerRadius: CGFloat = 1

    // MARK: - Initialization

    init(completionData: [Date: Bool], habitColor: Color, days: Int = Constants.miniGridDaysCount) {
        self.completionData = completionData
        self.habitColor = habitColor
        self.days = days
    }

    // MARK: - Computed

    private var dates: [Date] {
        Date.past(days: days)
    }

    private var incompleteColor: Color {
        AppColors.gridIncomplete(for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: cellGap) {
            ForEach(dates.reversed(), id: \.self) { date in
                gridCell(for: date)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func gridCell(for date: Date) -> some View {
        let isCompleted = completionData[Calendar.current.startOfDay(for: date)] ?? false
        let isToday = date.isToday

        RoundedRectangle(cornerRadius: cellCornerRadius)
            .fill(isCompleted ? habitColor : incompleteColor)
            .frame(width: cellSize, height: cellSize)
            .overlay {
                if isToday && !isCompleted {
                    RoundedRectangle(cornerRadius: cellCornerRadius)
                        .strokeBorder(habitColor.opacity(0.5), lineWidth: 1)
                }
            }
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

    return VStack(spacing: 20) {
        MiniGridView(
            completionData: sampleData,
            habitColor: .habitCoral
        )

        MiniGridView(
            completionData: sampleData,
            habitColor: .habitBlue
        )

        MiniGridView(
            completionData: sampleData,
            habitColor: .habitGreen
        )
    }
    .padding()
}
