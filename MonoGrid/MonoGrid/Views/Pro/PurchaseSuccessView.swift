//
//  PurchaseSuccessView.swift
//  MonoGrid
//
//  Pro Business Model - Purchase Success Celebration View
//  Created on 2026-01-25.
//

import SwiftUI

/// 구매 성공 축하 화면
struct PurchaseSuccessView: View {
    let license: ProLicense
    let onDismiss: () -> Void

    @State private var showCheckmark = false
    @State private var showContent = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success animation
            ZStack {
                // Background circle
                Circle()
                    .fill(ProColors.successColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showCheckmark ? 1 : 0.5)

                // Checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ProColors.successColor)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .rotationEffect(.degrees(showCheckmark ? 0 : -90))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)

            // Content
            VStack(spacing: 16) {
                Text("환영합니다! 🎉")
                    .font(.title)
                    .fontWeight(.bold)

                Text("MonoGrid Pro로 업그레이드되었습니다")
                    .font(.headline)
                    .foregroundColor(.secondary)

                // License info
                VStack(spacing: 8) {
                    LicenseInfoRow(
                        title: "라이선스",
                        value: license.type == .lifetime ? "Lifetime" : "Monthly"
                    )

                    LicenseInfoRow(
                        title: "구매일",
                        value: formattedDate(license.purchaseDate)
                    )

                    if license.type == .monthly, let nextBilling = license.nextBillingDate {
                        LicenseInfoRow(
                            title: "다음 결제",
                            value: formattedDate(nextBilling)
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)

            Spacer()

            // Pro features unlocked
            VStack(alignment: .leading, spacing: 12) {
                Text("잠금 해제된 기능")
                    .font(.headline)
                    .padding(.horizontal)

                CompactFeatureList(features: ProFeature.allCases)
                    .padding(.horizontal)
            }
            .opacity(showContent ? 1 : 0)

            Spacer()

            // Dismiss button
            Button(action: onDismiss) {
                Text("시작하기")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ProColors.lifetimeButtonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(0.6), value: showButton)
        }
        .padding()
        .onAppear {
            showCheckmark = true
            showContent = true
            showButton = true
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

// MARK: - License Info Row

struct LicenseInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    PurchaseSuccessView(
        license: ProLicense(
            type: .lifetime,
            purchaseDate: Date(),
            expirationDate: nil,
            polarCustomerId: "cus_123",
            polarSubscriptionId: nil,
            lastVerifiedAt: Date()
        ),
        onDismiss: {}
    )
}
