//
//  ProUpgradeBanner.swift
//  MonoGrid
//
//  Pro Business Model - Upgrade Banner for Home Screen
//  Created on 2026-01-25.
//

import SwiftUI

/// Pro 업그레이드 배너 (홈 화면 상단에 표시)
struct ProUpgradeBanner: View {
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Crown icon
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ProColors.proBadgeGradient)
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("MonoGrid Pro로 업그레이드")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        ProBadge(style: .compact)
                    }

                    Text("12가지 컬러 · 고급 통계 · 앱 아이콘")
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
                    .fill(bannerBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.4),
                                Color.orange.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("MonoGrid Pro로 업그레이드")
        .accessibilityHint("탭하여 Pro 기능 확인")
    }

    private var bannerBackground: Color {
        colorScheme == .dark
            ? Color(.systemGray6)
            : Color.white
    }
}

// MARK: - Compact Banner

/// 컴팩트한 Pro 업그레이드 배너
struct CompactProUpgradeBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(ProColors.proBadgeGradient)

                Text("Pro 업그레이드")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ProUpgradeBanner {
            print("Banner tapped")
        }
        .padding(.horizontal)

        CompactProUpgradeBanner {
            print("Compact banner tapped")
        }
        .padding(.horizontal)
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}
