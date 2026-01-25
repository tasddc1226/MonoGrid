//
//  NotificationSettingsView.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import SwiftUI

/// Settings screen for managing notification preferences
struct NotificationSettingsView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var viewModel = NotificationSettingsViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Permission Warning Section
                if viewModel.shouldShowPermissionWarning {
                    permissionDeniedSection
                }

                // Toggle Section
                Section {
                    notificationToggle
                } header: {
                    Text("알림 설정")
                } footer: {
                    if !viewModel.shouldShowPermissionWarning {
                        Text("매일 설정한 시간에 습관 체크 알림을 받습니다")
                    }
                }

                // Time Setting Section
                if viewModel.isEnabled && viewModel.isSystemPermissionGranted {
                    Section(header: Text("알림 시간")) {
                        timeSettingRow
                    }

                    // Preview Section
                    if let message = viewModel.previewMessage {
                        Section(header: Text("알림 미리보기")) {
                            NotificationPreviewCard(message: message)
                        }
                    }
                }
            }
            .navigationTitle("알림")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showTimePicker) {
                NotificationTimePickerSheet(
                    selectedTime: $viewModel.scheduledTime
                )
                .presentationDetents([.height(320)])
            }
            .task {
                await viewModel.refreshPermissionStatus()
            }
            .onAppear {
                // Configure with environment repository if available
                Task {
                    await viewModel.loadPreviewMessage()
                }
            }
        }
    }

    // MARK: - Permission Denied Section

    @ViewBuilder
    private var permissionDeniedSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.slash.fill")
                        .foregroundColor(.orange)
                        .font(.title2)

                    Text("알림이 비활성화됨")
                        .font(.headline)
                }

                Text("시스템 설정에서 MonoGrid의 알림을 허용해주세요.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    viewModel.openSystemSettings()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("시스템 설정 열기")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Notification Toggle

    @ViewBuilder
    private var notificationToggle: some View {
        Toggle(isOn: $viewModel.isEnabled) {
            Label {
                Text("습관 알림")
            } icon: {
                Image(systemName: "bell.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .onChange(of: viewModel.isEnabled) { _, newValue in
            HapticManager.shared.lightImpact()
            if newValue && !viewModel.isSystemPermissionGranted {
                // Request permission if not granted
                Task {
                    let granted = await viewModel.requestPermission()
                    if !granted {
                        viewModel.isEnabled = false
                    }
                }
            }
        }
    }

    // MARK: - Time Setting Row

    @ViewBuilder
    private var timeSettingRow: some View {
        Button {
            viewModel.showTimePicker = true
        } label: {
            HStack {
                Label {
                    Text("알림 시간")
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentColor)
                }

                Spacer()

                Text(viewModel.formattedTime)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Preview

#Preview {
    NotificationSettingsView()
}
