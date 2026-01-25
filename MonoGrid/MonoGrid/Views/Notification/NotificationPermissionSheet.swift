//
//  NotificationPermissionSheet.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import SwiftUI

/// Pre-permission bottom sheet shown on first habit creation
struct NotificationPermissionSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let onAllow: () async -> Bool
    let onLater: () -> Void

    // MARK: - State

    @State private var isLoading = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 24)

            // Title
            Text("습관 리마인더를 받으시겠어요?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Description
            Text("매일 설정한 시간에 알림을 보내드려요.\n습관을 잊지 않고 체크할 수 있어요.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                // Allow Button
                Button {
                    Task {
                        isLoading = true
                        let granted = await onAllow()
                        isLoading = false
                        if granted {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("허용하기")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.UI.primaryButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                // Later Button
                Button {
                    onLater()
                    dismiss()
                } label: {
                    Text("나중에")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .interactiveDismissDisabled(isLoading)
    }
}

// MARK: - Preview

#Preview {
    NotificationPermissionSheet(
        onAllow: { true },
        onLater: {}
    )
}
