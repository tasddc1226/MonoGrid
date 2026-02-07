//
//  GracePeriodBanner.swift
//  MonoGrid
//
//  Pro Business Model - Grace Period Warning Banner
//  Created on 2026-01-25.
//

import SwiftUI

/// 결제 실패 유예 기간 경고 배너
struct GracePeriodBanner: View {
    let daysRemaining: Int
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ProColors.warningColor)

                // Message
                VStack(alignment: .leading, spacing: 2) {
                    Text("결제 정보 확인 필요")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(remainingText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ProColors.warningColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(ProColors.warningColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("결제 정보 확인 필요, \(remainingText)")
        .accessibilityHint("탭하여 결제 정보 업데이트")
    }

    private var remainingText: String {
        if daysRemaining <= 0 {
            return "오늘 중으로 결제 정보를 업데이트해주세요"
        } else if daysRemaining == 1 {
            return "내일까지 결제 정보를 업데이트해주세요"
        } else {
            return "\(daysRemaining)일 내로 결제 정보를 업데이트해주세요"
        }
    }
}

// MARK: - Compact Banner

/// 컴팩트한 유예 기간 배너
struct CompactGracePeriodBanner: View {
    let daysRemaining: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(ProColors.warningColor)

            Text("결제 확인 필요 (\(daysRemaining)일)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ProColors.warningColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(ProColors.warningColor.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        GracePeriodBanner(daysRemaining: 3) {
            print("Tapped")
        }

        GracePeriodBanner(daysRemaining: 1) {
            print("Tapped")
        }

        GracePeriodBanner(daysRemaining: 0) {
            print("Tapped")
        }

        Divider()

        CompactGracePeriodBanner(daysRemaining: 2)
    }
    .padding()
}
