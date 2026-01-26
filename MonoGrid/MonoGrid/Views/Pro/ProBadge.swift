//
//  ProBadge.swift
//  MonoGrid
//
//  Pro Business Model - Pro Badge Component
//  Created on 2026-01-25.
//

import SwiftUI

/// Pro 배지 컴포넌트
struct ProBadge: View {
    var style: Style = .standard

    enum Style {
        case standard   // 일반 크기
        case compact    // 작은 크기
        case large      // 큰 크기
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "crown.fill")
                .font(.system(size: fontSize, weight: .bold))

            Text("Pro")
                .font(.system(size: fontSize, weight: .bold))
        }
        .foregroundStyle(ProColors.proBadgeGradient)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.15))
        )
        .accessibilityLabel("Pro 전용")
    }

    private var fontSize: CGFloat {
        switch style {
        case .standard: return 10
        case .compact: return 8
        case .large: return 14
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .standard: return 6
        case .compact: return 4
        case .large: return 10
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .standard: return 3
        case .compact: return 2
        case .large: return 5
        }
    }
}

// MARK: - Inline Pro Badge

/// 인라인 Pro 배지 (텍스트 옆에 사용)
struct InlineProBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8))

            Text("Pro")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(ProColors.proBadgeGradient)
        )
    }
}

// MARK: - Recommended Badge

/// 추천 배지 (Lifetime용)
struct RecommendedBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))

            Text("추천")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(Color(hex: "#FFD700"))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color(hex: "#FFD700").opacity(0.2))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ProBadge(style: .compact)
        ProBadge(style: .standard)
        ProBadge(style: .large)

        Divider()

        InlineProBadge()

        Divider()

        RecommendedBadge()
    }
    .padding()
}
