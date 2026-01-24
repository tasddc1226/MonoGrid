//
//  HomeView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Main dashboard view showing all habits
struct HomeView: View {
    // MARK: - Environment

    @Environment(HabitViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var showSettings = false
    @State private var showAddHabit = false
    @State private var selectedHabitForEdit: Habit?
    @State private var selectedHabitForDetail: Habit?
    @State private var habitGridData: [UUID: [Date: Bool]] = [:]

    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.habits.isEmpty {
                    EmptyStateView(onAddHabit: { showAddHabit = true })
                } else {
                    habitListView
                }
            }
            .navigationTitle(todayDateString)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedHabitForDetail) { habit in
                HabitDetailGridView(
                    habit: habit,
                    repository: SwiftDataHabitRepository(modelContext: modelContext)
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CompactSyncStatusView()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel(String(localized: "설정"))
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showAddHabit) {
                HabitEditView(habit: nil)
            }
            .sheet(item: $selectedHabitForEdit) { habit in
                HabitEditView(habit: habit)
            }
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
            .task {
                await viewModel.loadHabits()
                await loadAllGridData()
            }
        }
    }

    // MARK: - Subviews

    private var habitListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Date subtitle
                Text("오늘의 습관")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                // Habit cards
                ForEach(viewModel.habits, id: \.id) { habit in
                    HabitCardView(
                        habit: habit,
                        completionData: habitGridData[habit.id] ?? [:],
                        isTodayCompleted: viewModel.isHabitCompleted(habit, on: Date()),
                        onToggle: {
                            Task {
                                await viewModel.toggleHabit(habit)
                                await loadGridData(for: habit)
                            }
                        },
                        onLongPress: {
                            selectedHabitForEdit = habit
                        },
                        onCardTap: {
                            selectedHabitForDetail = habit
                        }
                    )
                    .padding(.horizontal)
                }

                // Add habit button (if under limit)
                if viewModel.canAddHabit {
                    addHabitButton
                        .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await viewModel.loadHabits()
            await loadAllGridData()
        }
    }

    private var addHabitButton: some View {
        Button {
            showAddHabit = true
        } label: {
            HStack {
                Image(systemName: "plus")
                    .font(.headline)
                Text("습관 추가")
                    .font(.headline)
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.UI.cardHeight - 20)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cardCornerRadius)
                    .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
        .accessibilityLabel(String(localized: "습관 추가"))
    }

    // MARK: - Helpers

    private var todayDateString: String {
        Date().fullFormattedWithWeekday
    }

    private func loadAllGridData() async {
        for habit in viewModel.habits {
            await loadGridData(for: habit)
        }
    }

    private func loadGridData(for habit: Habit) async {
        let data = await viewModel.fetchMiniGridData(for: habit)
        habitGridData[habit.id] = data
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(HabitViewModel(repository: PreviewHabitRepository()))
        .modelContainer(PersistenceController.preview.container)
}

// MARK: - Preview Repository

/// Mock repository for previews
@MainActor
class PreviewHabitRepository: HabitRepository {
    var habits: [Habit] = [
        Habit(title: "독서", colorHex: "#FF6B6B", iconSymbol: "book.fill", orderIndex: 0),
        Habit(title: "운동", colorHex: "#4D96FF", iconSymbol: "figure.walk", orderIndex: 1),
        Habit(title: "영양제", colorHex: "#6BCB77", iconSymbol: "pills.fill", orderIndex: 2)
    ]

    func fetchHabits() async throws -> [Habit] { habits }
    func saveHabit(_ habit: Habit) async throws { habits.append(habit) }
    func deleteHabit(_ habit: Habit) async throws { habits.removeAll { $0.id == habit.id } }
    func updateHabitOrder(_ habits: [Habit]) async throws { self.habits = habits }
    func toggleLog(for habitId: UUID, on date: Date) async throws -> HabitLog { HabitLog(date: date) }
    func fetchLogs(for habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] { [] }
    func fetchLog(for habitId: UUID, on date: Date) async throws -> HabitLog? { nil }
    func fetchAllLogs(for habitId: UUID) async throws -> [HabitLog] { [] }
    func habitCount() async throws -> Int { habits.count }
}
