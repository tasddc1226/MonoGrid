//
//  HabitEditView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// View for creating or editing a habit
struct HabitEditView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(HabitViewModel.self) private var viewModel

    // MARK: - Properties

    /// Habit to edit (nil for new habit)
    let habit: Habit?

    // MARK: - State

    @State private var title: String = ""
    @State private var selectedColorHex: String = Constants.colorPresets[0].hex
    @State private var selectedIcon: String = Constants.iconPresets[0]
    @State private var showDeleteConfirmation = false
    @State private var isSaving = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed

    private var isNewHabit: Bool {
        habit == nil
    }

    private var navigationTitle: String {
        isNewHabit ? String(localized: "습관 추가") : String(localized: "습관 편집")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    private var selectedColor: Color {
        AppColors.habitColor(hex: selectedColorHex, for: colorScheme)
    }

    private var previewBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : selectedColor.opacity(0.15)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Preview section
                Section {
                    previewCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // Name section
                Section(header: Text("습관 이름")) {
                    TextField("예: 독서, 운동", text: $title)
                        .textInputAutocapitalization(.sentences)
                }

                // Icon section
                Section(header: Text("아이콘")) {
                    IconPickerView(
                        selectedIcon: $selectedIcon,
                        color: selectedColor
                    )
                }

                // Color section
                Section(header: Text("색상")) {
                    ColorPickerView(selectedColorHex: $selectedColorHex)
                }

                // Delete section (only for existing habits)
                if !isNewHabit {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("습관 삭제", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveHabit()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "정말 삭제하시겠어요?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("삭제", role: .destructive) {
                    deleteHabit()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("기록도 함께 삭제됩니다")
            }
            .onAppear {
                loadHabitData()
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    // MARK: - Subviews

    private var previewCard: some View {
        VStack(spacing: 16) {
            // Large icon preview
            ZStack {
                Circle()
                    .fill(previewBackgroundColor)
                    .frame(width: 80, height: 80)

                Image(systemName: selectedIcon)
                    .font(.system(size: 36))
                    .foregroundColor(selectedColor)
            }

            // Title preview
            Text(title.isEmpty ? "습관 이름" : title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(title.isEmpty ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Actions

    private func loadHabitData() {
        if let habit = habit {
            title = habit.title
            selectedColorHex = habit.colorHex
            selectedIcon = habit.iconSymbol
        }
    }

    private func saveHabit() {
        isSaving = true

        Task {
            do {
                if let habit = habit {
                    // Update existing habit
                    try await viewModel.updateHabit(
                        habit,
                        title: title,
                        colorHex: selectedColorHex,
                        iconSymbol: selectedIcon
                    )
                } else {
                    // Create new habit
                    _ = try await viewModel.createHabit(
                        title: title,
                        colorHex: selectedColorHex,
                        iconSymbol: selectedIcon
                    )
                    HapticManager.shared.habitCreated()
                }

                dismiss()
            } catch {
                isSaving = false
                // Error will be shown via viewModel.errorMessage
            }
        }
    }

    private func deleteHabit() {
        guard let habit = habit else { return }

        isSaving = true

        Task {
            do {
                try await viewModel.deleteHabit(habit)
                HapticManager.shared.habitDeleted()
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }
}

// MARK: - Preview

#Preview("New Habit") {
    HabitEditView(habit: nil)
        .environment(HabitViewModel(repository: PreviewHabitRepository()))
}

#Preview("Edit Habit") {
    HabitEditView(habit: Habit(title: "독서", colorHex: "#FF6B6B", iconSymbol: "book.fill"))
        .environment(HabitViewModel(repository: PreviewHabitRepository()))
}
