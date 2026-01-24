//
//  HabitDetailGridView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Main container view for displaying habit grid in detail
struct HabitDetailGridView: View {
    // MARK: - Properties

    let habit: Habit
    let repository: HabitRepository

    @State private var viewModel: GridViewModel?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        setupViewModel()
                    }
            }
        }
        .navigationTitle(habit.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                headerView
            }
        }
    }

    // MARK: - Setup

    private func setupViewModel() {
        viewModel = GridViewModel(habit: habit, repository: repository)
        Task {
            await viewModel?.loadData()
        }
    }

    // MARK: - Subviews

    /// Custom header with habit icon and title
    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: habit.iconSymbol)
                .font(.headline)
                .foregroundColor(adaptedHabitColor)

            Text(habit.title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private func contentView(viewModel: GridViewModel) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    // View mode picker
                    GridViewModePicker(
                        selectedMode: Binding(
                            get: { viewModel.viewMode },
                            set: { newMode in
                                viewModel.viewMode = newMode
                                viewModel.onViewModeChange()
                            }
                        ),
                        habitColorHex: habit.colorHex
                    )
                    .padding(.horizontal)

                    // Period title
                    periodTitleView(viewModel: viewModel)

                    // Loading or grid content
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 200)
                    } else {
                        gridContent(viewModel: viewModel)
                    }

                    // Legend (only for yearly view)
                    if viewModel.viewMode == .yearly {
                        GridLegendView(habitColorHex: habit.colorHex)
                            .padding(.top, 8)
                    }

                    // Statistics section
                    statisticsSection(viewModel: viewModel)

                    Spacer(minLength: 80)
                }
                .padding(.top)
            }

            // Floating "Today" button
            if !viewModel.isShowingToday {
                todayJumpButton(viewModel: viewModel)
                    .padding(.bottom, 20)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color(.systemGroupedBackground))
        .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isShowingToday)
        .alert(
            String(localized: "오류"),
            isPresented: Binding(
                get: { viewModel.showError },
                set: { _ in viewModel.dismissError() }
            )
        ) {
            Button(String(localized: "확인"), role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }

    /// Period title with navigation
    private func periodTitleView(viewModel: GridViewModel) -> some View {
        HStack {
            Button {
                viewModel.navigatePrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button {
                viewModel.jumpToToday()
            } label: {
                Text(viewModel.periodTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                viewModel.navigateNext()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(viewModel.canNavigateForward ? .primary : .secondary.opacity(0.3))
            }
            .disabled(!viewModel.canNavigateForward)
        }
        .padding(.horizontal)
    }

    /// Grid content based on view mode
    @ViewBuilder
    private func gridContent(viewModel: GridViewModel) -> some View {
        let gridTransition: AnyTransition = reduceMotion
            ? .opacity
            : .opacity.combined(with: .scale(scale: 0.95))

        switch viewModel.viewMode {
        case .yearly:
            YearlyGridView(
                habitId: habit.id,
                habitColorHex: habit.colorHex,
                year: viewModel.currentYear,
                completionData: viewModel.completionData
            ) { date in
                Task {
                    await viewModel.toggleCompletion(on: date)
                }
            }
            .padding(.horizontal)
            .transition(gridTransition)

        case .monthly:
            MonthlyGridView(
                habitId: habit.id,
                habitColorHex: habit.colorHex,
                currentDate: Binding(
                    get: { viewModel.currentMonthDate },
                    set: { viewModel.currentMonthDate = $0 }
                ),
                completionData: viewModel.completionData
            ) { date in
                Task {
                    await viewModel.toggleCompletion(on: date)
                }
            } onMonthChange: { year, month in
                Task {
                    await viewModel.loadData()
                }
            }
            .padding(.horizontal)
            .transition(gridTransition)

        case .weekly:
            WeeklyListView(
                habitId: habit.id,
                habitColorHex: habit.colorHex,
                currentWeekStart: Binding(
                    get: { viewModel.currentWeekStart },
                    set: { viewModel.currentWeekStart = $0 }
                ),
                completionData: viewModel.completionData
            ) { date in
                Task {
                    await viewModel.toggleCompletion(on: date)
                }
            } onWeekChange: { weekStart in
                Task {
                    await viewModel.loadData()
                }
            }
            .padding(.horizontal)
            .transition(gridTransition)
        }
    }

    /// Statistics section with animated summary view
    private func statisticsSection(viewModel: GridViewModel) -> some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal)

            StatisticsSummaryView(
                statistics: viewModel.statistics,
                habitColorHex: habit.colorHex,
                viewMode: viewModel.viewMode
            )
            .padding(.horizontal)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.statistics)
        }
    }

    /// Floating button to jump to today
    private func todayJumpButton(viewModel: GridViewModel) -> some View {
        Button {
            HapticManager.shared.mediumImpact()
            if reduceMotion {
                viewModel.jumpToToday()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.jumpToToday()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .semibold))
                Text("오늘로 이동")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(adaptedHabitColor)
                    .shadow(color: adaptedHabitColor.opacity(0.4), radius: 8, x: 0, y: 4)
            )
        }
        .accessibilityLabel(String(localized: "오늘로 이동"))
        .accessibilityHint(String(localized: "오늘 날짜가 포함된 기간으로 이동합니다"))
    }

    // MARK: - Helpers

    private var adaptedHabitColor: Color {
        if colorScheme == .dark {
            let darkHex = Color.darkModeHex(for: habit.colorHex)
            return Color(hex: darkHex)
        }
        return Color(hex: habit.colorHex)
    }
}

// MARK: - Preview

#Preview("Habit Detail Grid View") {
    NavigationStack {
        HabitDetailGridView(
            habit: Habit(title: "독서", colorHex: "#4D96FF", iconSymbol: "book.fill"),
            repository: PreviewHabitRepository()
        )
    }
}
