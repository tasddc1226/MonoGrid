//
//  PaywallView.swift
//  MonoGrid
//
//  Pro Business Model - Main Paywall Modal View
//  Created on 2026-01-25.
//  Updated on 2026-01-26 for RevenueCat integration.
//

import SwiftUI

/// 메인 Paywall 모달 뷰
struct PaywallView: View {
    @Environment(ProViewModel.self) private var proViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var paywallViewModel = PaywallViewModel()
    @State private var purchaseViewModel = PurchaseViewModel()

    // Single presentation state to prevent conflicts
    @State private var activeSheet: PaywallSheet?

    enum PaywallSheet: Identifiable {
        case success(ProLicense)

        var id: String {
            switch self {
            case .success: return "success"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Feature list
                featureSection

                // Product buttons
                productSection

                // Restore link
                restoreSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pro 업그레이드")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            paywallViewModel.startFeatureAnimation()
        }
        .alert("오류", isPresented: $purchaseViewModel.showError) {
            Button("확인") {
                purchaseViewModel.dismissError()
            }
        } message: {
            Text(purchaseViewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다")
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .success(let license):
                PurchaseSuccessView(license: license) {
                    proViewModel.onPurchaseCompleted(license: license)
                    purchaseViewModel.dismissSuccess()
                    activeSheet = nil
                    dismiss()
                }
            }
        }
        .onChange(of: purchaseViewModel.showSuccess) { _, show in
            if show, let license = purchaseViewModel.purchasedLicense, activeSheet == nil {
                activeSheet = .success(license)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Pro badge
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(ProColors.proBadgeGradient)

            Text("MonoGrid Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("더 많은 기능으로 습관을 관리하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Feature Section

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pro 기능")
                .font(.headline)

            PaywallFeatureList(
                features: paywallViewModel.visibleFeatures,
                animated: true
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Product Section

    private var productSection: some View {
        VStack(spacing: 12) {
            // Lifetime (Recommended)
            PurchaseButton(
                product: .lifetime,
                isSelected: paywallViewModel.selectedProduct == .lifetime,
                isLoading: purchaseViewModel.isPurchasing && purchaseViewModel.selectedProduct == .lifetime
            ) {
                paywallViewModel.selectProduct(.lifetime)
                Task {
                    await purchaseViewModel.startPurchase(product: .lifetime)
                }
            }

            // Monthly
            PurchaseButton(
                product: .monthly,
                isSelected: paywallViewModel.selectedProduct == .monthly,
                isLoading: purchaseViewModel.isPurchasing && purchaseViewModel.selectedProduct == .monthly
            ) {
                paywallViewModel.selectProduct(.monthly)
                Task {
                    await purchaseViewModel.startPurchase(product: .monthly)
                }
            }
        }
    }

    // MARK: - Restore Section

    private var restoreSection: some View {
        VStack(spacing: 8) {
            Button {
                // RevenueCat restore is automatic - no email needed
                purchaseViewModel.startRestore()
            } label: {
                if purchaseViewModel.isRestoring {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("이전 구매 복원")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .disabled(purchaseViewModel.isRestoring)

            Text("구매 관련 문의: support@monogrid.app")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environment(ProViewModel())
}
