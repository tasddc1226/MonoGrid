//
//  PaywallFeatureList.swift
//  MonoGrid
//
//  Pro Business Model - Paywall Feature List Component
//  Created on 2026-01-25.
//

import SwiftUI

/// Paywall에 표시되는 Pro 기능 목록
struct PaywallFeatureList: View {
    let features: [ProFeature]
    var animated: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                FeatureRow(feature: feature)
                    .opacity(animated ? 1 : 1)
                    .offset(x: animated ? 0 : -20)
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: ProFeature

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: feature.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.displayName), \(feature.description)")
    }
}

// MARK: - Compact Feature List

/// 컴팩트한 기능 목록 (간단한 체크리스트)
struct CompactFeatureList: View {
    let features: [ProFeature]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(features) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)

                    Text(feature.displayName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        PaywallFeatureList(features: ProFeature.allCases)

        Divider()

        CompactFeatureList(features: ProFeature.allCases)
    }
    .padding()
}
