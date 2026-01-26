//
//  PurchaseButton.swift
//  MonoGrid
//
//  Pro Business Model - Purchase Button Component
//  Created on 2026-01-25.
//

import SwiftUI

/// 구매 버튼 컴포넌트
struct PurchaseButton: View {
    let product: ProProduct
    let isSelected: Bool
    let isLoading: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Product info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.title)
                            .font(.headline)
                            .fontWeight(.bold)

                        if product.isRecommended {
                            RecommendedBadge()
                        }
                    }

                    Text(product.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Price
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: shadowColor.opacity(0.3),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .accessibilityLabel("\(product.title), \(product.displayPrice)")
        .accessibilityHint(product.isRecommended ? "추천 옵션" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch product {
        case .lifetime:
            ProColors.lifetimeButtonGradient
        case .monthly:
            ProColors.monthlyButtonGradient
        }
    }

    private var shadowColor: Color {
        switch product {
        case .lifetime:
            return Color(hex: "#FFD700")
        case .monthly:
            return Color(hex: "#9B5DE5")
        }
    }
}

// MARK: - Mini Purchase Button

/// 작은 구매 버튼 (설정 화면용)
struct MiniPurchaseButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12))

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(ProColors.lifetimeButtonGradient)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PurchaseButton(
            product: .lifetime,
            isSelected: true,
            isLoading: false
        ) {}

        PurchaseButton(
            product: .monthly,
            isSelected: false,
            isLoading: false
        ) {}

        PurchaseButton(
            product: .lifetime,
            isSelected: true,
            isLoading: true
        ) {}

        Divider()

        MiniPurchaseButton(title: "Pro 업그레이드") {}
    }
    .padding()
    .background(Color(.systemBackground))
}
