//
//  ProFeatureGate.swift
//  MonoGrid
//
//  Pro Business Model - Feature Gating Utility
//  Created on 2026-01-25.
//

import SwiftUI

/// Pro 기능 게이팅을 위한 유틸리티
@MainActor
struct ProFeatureGate {
    /// Pro 기능 접근 가능 여부 확인
    static func canAccess(_ feature: ProFeature) -> Bool {
        LicenseManager.shared.hasProAccess
    }

    /// Pro 색상 여부 확인
    static func isProColor(_ colorHex: String) -> Bool {
        ProColors.proOnlyColors.contains(colorHex.uppercased())
    }

    /// Pro 아이콘 여부 확인
    static func isProIcon(_ iconName: String) -> Bool {
        ProIcons.proOnlyIcons.contains(iconName)
    }
}

// MARK: - Pro Locked View Modifier

/// Pro 기능 래퍼 View Modifier
struct ProLockedModifier: ViewModifier {
    let feature: ProFeature
    @Environment(ProViewModel.self) private var proViewModel

    func body(content: Content) -> some View {
        content
            .overlay {
                if !proViewModel.hasProAccess {
                    LockedFeatureOverlay(feature: feature)
                }
            }
            .onTapGesture {
                if !proViewModel.hasProAccess {
                    HapticManager.shared.lightImpact()
                    _ = proViewModel.requestAccess(to: feature)
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Pro 기능에 잠금 오버레이 추가
    func proLocked(_ feature: ProFeature) -> some View {
        modifier(ProLockedModifier(feature: feature))
    }

    /// 조건부 Pro 잠금
    func proLockedIf(_ condition: Bool, feature: ProFeature) -> some View {
        Group {
            if condition {
                self.modifier(ProLockedModifier(feature: feature))
            } else {
                self
            }
        }
    }
}

// MARK: - Pro Gated Button

/// Pro 기능을 위한 버튼 래퍼
struct ProGatedButton<Label: View>: View {
    let feature: ProFeature
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @Environment(ProViewModel.self) private var proViewModel

    var body: some View {
        Button {
            if proViewModel.requestAccess(to: feature) {
                action()
            }
        } label: {
            label()
        }
    }
}
