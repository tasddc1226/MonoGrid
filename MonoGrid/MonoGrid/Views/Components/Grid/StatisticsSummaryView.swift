//
//  StatisticsSummaryView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// View displaying habit statistics in a card layout
struct StatisticsSummaryView: View {
    // MARK: - Properties

    let statistics: GridStatistics
    let habitColorHex: String
    let viewMode: GridViewMode

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ProViewModel.self) private var proViewModel

    @State private var showPaywall = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Main stats row
            HStack(spacing: 12) {
                StatCard(
                    title: "완료",
                    value: statistics.formattedCompletedDays,
                    icon: "checkmark.circle.fill",
                    color: adaptedHabitColor
                )

                StatCard(
                    title: "달성률",
                    value: statistics.formattedCompletionRate,
                    icon: "percent",
                    color: adaptedHabitColor
                )

                StatCard(
                    title: "연속",
                    value: statistics.formattedCurrentStreak,
                    icon: "flame.fill",
                    color: streakColor
                )

                // Longest Streak - Pro Feature
                if proViewModel.hasProAccess {
                    StatCard(
                        title: "최장",
                        value: statistics.formattedLongestStreak,
                        icon: "trophy.fill",
                        color: .orange
                    )
                } else {
                    LockedStatCard(
                        title: "최장",
                        icon: "trophy.fill",
                        color: .orange
                    ) {
                        HapticManager.shared.lightImpact()
                        showPaywall = true
                    }
                }
            }

            // Additional info row (for yearly/monthly views)
            if viewMode != .weekly {
                additionalStatsRow
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
        )
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                showPaywall = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var additionalStatsRow: some View {
        HStack(spacing: 16) {
            // Average Streak - Pro Feature
            if proViewModel.hasProAccess {
                AdditionalStatItem(
                    label: "평균 연속",
                    value: statistics.formattedAverageStreak,
                    icon: "chart.bar.fill"
                )
            } else {
                LockedStatItem(
                    label: "평균 연속",
                    icon: "chart.bar.fill"
                ) {
                    HapticManager.shared.lightImpact()
                    showPaywall = true
                }
            }

            // Best Day of Week - Pro Feature
            if let bestDay = statistics.bestDayOfWeekName {
                if proViewModel.hasProAccess {
                    AdditionalStatItem(
                        label: "가장 좋은 요일",
                        value: bestDay,
                        icon: "calendar"
                    )
                } else {
                    LockedStatItem(
                        label: "가장 좋은 요일",
                        icon: "calendar"
                    ) {
                        HapticManager.shared.lightImpact()
                        showPaywall = true
                    }
                }
            }

            if viewMode == .yearly, let bestMonth = statistics.bestMonthName {
                AdditionalStatItem(
                    label: "가장 좋은 달",
                    value: bestMonth,
                    icon: "calendar.badge.plus"
                )
            }

            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Colors

    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habitColorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habitColorHex)
    }

    private var streakColor: Color {
        if statistics.currentStreak > 0 {
            return .orange
        }
        return .secondary
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "#2C2C2E") : Color.white
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            // Value with animation (respect Reduce Motion)
            if reduceMotion {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            } else {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
            }

            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "#3A3A3C") : Color(hex: "#F2F2F7")
    }
}

// MARK: - Additional Stat Item

private struct AdditionalStatItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Locked Stat Item (Pro Feature)

/// Locked state for Pro-only statistics
private struct LockedStatItem: View {
    let label: String
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Blurred placeholder value
                Text("???")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary.opacity(0.5))
                    .blur(radius: 2)

                // Pro lock badge
                HStack(spacing: 2) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .semibold))
                    Text("Pro")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.accentColor)
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), Pro 전용 기능")
        .accessibilityHint("탭하여 Pro 구매 화면으로 이동")
    }
}

// MARK: - Locked Stat Card (Pro Feature)

/// Locked version of StatCard for Pro-only statistics
private struct LockedStatCard: View {
    let title: String
    let icon: String
    let color: Color
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon with lock overlay
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color.opacity(0.5))

                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.accentColor))
                        .offset(x: 8, y: -8)
                }

                // Blurred placeholder value
                Text("??")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary.opacity(0.5))
                    .blur(radius: 3)

                // Title with Pro badge
                HStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Pro")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.accentColor))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), Pro 전용 기능")
        .accessibilityHint("탭하여 Pro 구매 화면으로 이동")
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "#3A3A3C") : Color(hex: "#F2F2F7")
    }
}

// MARK: - Compact Statistics View

/// A more compact version for smaller displays
struct CompactStatisticsSummaryView: View {
    let statistics: GridStatistics
    let habitColorHex: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 24) {
            CompactStatItem(
                value: "\(statistics.completedDays)",
                label: "완료",
                color: adaptedHabitColor
            )

            CompactStatItem(
                value: statistics.formattedCompletionRate,
                label: "달성률",
                color: adaptedHabitColor
            )

            CompactStatItem(
                value: "\(statistics.currentStreak)",
                label: "연속",
                color: statistics.currentStreak > 0 ? .orange : .secondary
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "#2C2C2E") : Color.white)
        )
    }

    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habitColorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habitColorHex)
    }
}

private struct CompactStatItem: View {
    let value: String
    let label: String
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            if reduceMotion {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            } else {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .contentTransition(.numericText())
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Statistics Summary") {
    VStack(spacing: 20) {
        StatisticsSummaryView(
            statistics: GridStatistics(
                totalDays: 30,
                completedDays: 22,
                completionRate: 73.3,
                currentStreak: 5,
                longestStreak: 12,
                averageStreak: 4.5,
                period: "2026년 1월",
                bestDayOfWeek: 1,
                bestMonth: nil
            ),
            habitColorHex: "#4D96FF",
            viewMode: .monthly
        )
        .padding(.horizontal)

        StatisticsSummaryView(
            statistics: GridStatistics(
                totalDays: 365,
                completedDays: 280,
                completionRate: 76.7,
                currentStreak: 15,
                longestStreak: 45,
                averageStreak: 8.2,
                period: "2026년",
                bestDayOfWeek: 3,
                bestMonth: 6
            ),
            habitColorHex: "#FF6B6B",
            viewMode: .yearly
        )
        .padding(.horizontal)

        CompactStatisticsSummaryView(
            statistics: GridStatistics(
                totalDays: 7,
                completedDays: 5,
                completionRate: 71.4,
                currentStreak: 3,
                longestStreak: 5,
                averageStreak: 2.5,
                period: "1/20 - 1/26"
            ),
            habitColorHex: "#6BCB77"
        )
        .padding(.horizontal)
    }
    .background(Color(.systemGroupedBackground))
}
