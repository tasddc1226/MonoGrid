//
//  SettingsView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI
import WidgetKit

/// Settings screen for managing habits and app preferences
struct SettingsView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(HabitViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var selectedHabit: Habit?
    @State private var showResetConfirmation = false
    @State private var showAbout = false
    @State private var selectedTheme: ThemeMode = ThemeManager.shared.currentTheme

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Habit Management Section
                Section(header: Text("습관 관리")) {
                    if viewModel.habits.isEmpty {
                        Text("등록된 습관이 없습니다")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.habits, id: \.id) { habit in
                            habitRow(habit)
                        }
                        .onMove(perform: moveHabits)
                    }
                }

                // Appearance Section
                Section(header: Text("화면")) {
                    // Theme Selection
                    Picker(selection: $selectedTheme) {
                        ForEach(ThemeMode.allCases) { theme in
                            Label(theme.displayName, systemImage: theme.iconName)
                                .tag(theme)
                        }
                    } label: {
                        Label("테마", systemImage: "paintbrush")
                    }
                    .onChange(of: selectedTheme) { _, newValue in
                        ThemeManager.shared.currentTheme = newValue
                        // Refresh widgets to apply new theme
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }

                // General Section
                Section(header: Text("일반")) {
                    // Language (follows system)
                    HStack {
                        Label("언어", systemImage: "globe")
                        Spacer()
                        Text("시스템 설정")
                            .foregroundColor(.secondary)
                    }

                    // iCloud Sync status
                    HStack {
                        Label("iCloud 동기화", systemImage: "icloud")
                        Spacer()
                        Text("켜짐")
                            .foregroundColor(.secondary)
                    }
                }

                // Info Section
                Section(header: Text("정보")) {
                    Button {
                        showAbout = true
                    } label: {
                        Label("앱 정보", systemImage: "info.circle")
                    }

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("모든 데이터 초기화", systemImage: "trash")
                    }
                }

                // Version Footer
                Section {
                    EmptyView()
                } footer: {
                    HStack {
                        Spacer()
                        Text("MonoGrid v1.0")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(item: $selectedHabit) { habit in
                HabitEditView(habit: habit)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .confirmationDialog(
                "모든 데이터를 삭제하시겠어요?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("삭제", role: .destructive) {
                    resetAllData()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("모든 습관과 기록이 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func habitRow(_ habit: Habit) -> some View {
        Button {
            selectedHabit = habit
        } label: {
            HStack {
                Image(systemName: habit.iconSymbol)
                    .font(.title3)
                    .foregroundColor(Color(hex: habit.colorHex))
                    .frame(width: 32)

                Text(habit.title)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func moveHabits(from source: IndexSet, to destination: Int) {
        Task {
            await viewModel.reorderHabits(from: source, to: destination)
        }
    }

    private func resetAllData() {
        Task {
            for habit in viewModel.habits {
                try? await viewModel.deleteHabit(habit)
            }
            HapticManager.shared.warning()
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        // App Icon placeholder
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        VStack(spacing: 4) {
                            Text("MonoGrid")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("버전 1.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .listRowBackground(Color.clear)

                Section(header: Text("소개")) {
                    Text("MonoGrid는 GitHub Contribution Graph 스타일의 미니멀 습관 트래커입니다. 최대 3개의 핵심 습관만 관리하며, 앱 실행 없이도 위젯과 단축어로 기록할 수 있습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("핵심 가치")) {
                    Label("집중 - 3개의 핵심 습관", systemImage: "target")
                    Label("Invisible - 위젯/단축어로 기록", systemImage: "rectangle.stack")
                    Label("시각화 - GitHub 스타일 그리드", systemImage: "square.grid.3x3")
                }
            }
            .navigationTitle("앱 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(HabitViewModel(repository: PreviewHabitRepository()))
}
