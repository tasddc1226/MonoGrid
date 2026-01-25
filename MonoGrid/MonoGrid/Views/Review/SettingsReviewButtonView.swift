//
//  SettingsReviewButtonView.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import SwiftUI

/// Button for settings screen to open App Store review page
struct SettingsReviewButtonView: View {
    // MARK: - State

    @State private var showingError = false

    // MARK: - Body

    var body: some View {
        Button(action: openAppStoreReview) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("앱스토어에서 평가하기")
                        .font(.body)
                        .foregroundColor(.primary)

                    Text("앱이 마음에 드셨다면 평가를 남겨주세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .accessibilityLabel("앱스토어에서 평가하기")
        .accessibilityHint("앱스토어 리뷰 작성 페이지로 이동합니다")
        .alert("앱스토어를 열 수 없습니다", isPresented: $showingError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("기기 설정을 확인해주세요.")
        }
    }

    // MARK: - Actions

    private func openAppStoreReview() {
        // Haptic feedback
        HapticManager.shared.lightImpact()

        guard AppReviewManager.shared.canOpenAppStoreReviewPage() else {
            showingError = true
            return
        }

        AppReviewManager.shared.openAppStoreReviewPage()
    }
}

// MARK: - Preview

#Preview {
    List {
        Section(header: Text("정보")) {
            SettingsReviewButtonView()
        }
    }
}
