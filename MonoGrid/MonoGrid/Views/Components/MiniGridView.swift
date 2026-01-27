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

    // MARK: - Grid Style Settings (Pro Feature)

    /// Get the current grid style settings
    /// For non-Pro users, returns default settings
    private var gridStyle: GridStyleSettings {
        if LicenseManager.shared.hasProAccess {
            return GridStyleManager.shared.settings
        }
        return .default
    }

    /// Computed corner radius considering the cell size
    private var cellCornerRadius: CGFloat {
        // Scale corner radius relative to cell size to prevent over-rounding
        min(gridStyle.cornerRadius * (cellSize / 10), cellSize / 2)
    }

    /// Computed border width considering the cell size
    private var cellBorderWidth: CGFloat {
        // Scale border width for mini grid cells
        min(gridStyle.borderWidth * 0.5, 1)
    }

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
                // Border overlay (Pro feature)
                if cellBorderWidth > 0 {
                    RoundedRectangle(cornerRadius: cellCornerRadius)
                        .strokeBorder(
                            Color.primary.opacity(0.2),
                            lineWidth: cellBorderWidth
                        )
                }
            }
            .overlay {
                // Today indicator (when not completed)
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
