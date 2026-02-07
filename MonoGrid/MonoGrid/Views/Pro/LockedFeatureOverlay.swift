//
//  LockedFeatureOverlay.swift
//  MonoGrid
//
//  Pro Business Model - Locked Feature Overlay Component
//  Created on 2026-01-25.
//

import SwiftUI

/// 잠금된 기능 위에 표시되는 오버레이
struct LockedFeatureOverlay: View {
    let feature: ProFeature
    var style: Style = .standard

    enum Style {
        case standard   // 일반 오버레이
        case compact    // 작은 아이콘만
        case badge      // 배지 형태
    }

    var body: some View {
        switch style {
        case .standard:
            standardOverlay
        case .compact:
            compactOverlay
        case .badge:
            badgeOverlay
        }
    }

    // MARK: - Standard Overlay

    private var standardOverlay: some View {
        ZStack {
            // 블러 배경
            Color.black.opacity(0.3)

            // 잠금 아이콘
            VStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text("Pro")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.6))
            )
        }
        .contentShape(Rectangle())
        .accessibilityLabel("\(feature.displayName), Pro 전용 기능, 잠김")
        .accessibilityHint("두 번 탭하여 Pro 구매 화면으로 이동")
    }

    // MARK: - Compact Overlay

    private var compactOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear

            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .padding(4)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                )
                .padding(4)
        }
        .accessibilityLabel("\(feature.displayName), Pro 전용")
    }

    // MARK: - Badge Overlay

    private var badgeOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear

            InlineProBadge()
                .padding(4)
        }
    }
}

// MARK: - Color Lock Overlay

/// 컬러 선택기용 잠금 오버레이
struct ColorLockOverlay: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.4))

            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Standard overlay
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue)
                .frame(width: 100, height: 100)

            LockedFeatureOverlay(feature: .signatureColors, style: .standard)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))

        // Compact overlay
        ZStack {
            Circle()
                .fill(Color.purple)
                .frame(width: 44, height: 44)

            LockedFeatureOverlay(feature: .proAppIcons, style: .compact)
        }

        // Badge overlay
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green)
                .frame(width: 120, height: 80)

            LockedFeatureOverlay(feature: .hdExport, style: .badge)
        }

        // Color lock
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 44, height: 44)

            ColorLockOverlay()
        }
    }
    .padding()
}
