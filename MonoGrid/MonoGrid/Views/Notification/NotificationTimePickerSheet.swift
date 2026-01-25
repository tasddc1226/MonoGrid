//
//  NotificationTimePickerSheet.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import SwiftUI

/// Bottom sheet for selecting notification time
struct NotificationTimePickerSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Binding

    @Binding var selectedTime: Date

    // MARK: - State

    @State private var tempTime: Date

    // MARK: - Initialization

    init(selectedTime: Binding<Date>) {
        self._selectedTime = selectedTime
        self._tempTime = State(initialValue: selectedTime.wrappedValue)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Text("알림 시간 설정")
                    .font(.headline)
                    .padding(.top, 20)

                // Time Picker
                DatePicker(
                    "",
                    selection: $tempTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal)

                Spacer()

                // Save Button
                Button {
                    saveTime()
                } label: {
                    Text("저장")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.UI.primaryButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func saveTime() {
        selectedTime = tempTime
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NotificationTimePickerSheet(
        selectedTime: .constant(Date())
    )
}
