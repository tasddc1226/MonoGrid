//
//  ProColors.swift
//  MonoGrid
//
//  Pro Business Model - Pro Color Palette Definitions
//  Created on 2026-01-25.
//

import SwiftUI

/// Pro 컬러 팔레트 정의
enum ProColors {
    // MARK: - Free Colors (6 colors - same as existing)

    /// 무료 사용자용 기본 컬러
    static let freeColors: [String] = [
        "#FF6B6B",  // Coral
        "#FFA94D",  // Orange
        "#FFD93D",  // Yellow
        "#6BCB77",  // Green
        "#4D96FF",  // Blue
        "#9B5DE5"   // Purple
    ]

    // MARK: - Pro Only Colors (6 additional colors)

    /// Pro 전용 시그니처 컬러
    static let proOnlyColors: [String] = [
        "#FF1744",  // Vivid Red
        "#00BFA5",  // Teal
        "#651FFF",  // Deep Purple
        "#FF9100",  // Amber
        "#00E5FF",  // Cyan
        "#F50057"   // Pink
    ]

    // MARK: - All Colors

    /// 모든 컬러 (Free + Pro)
    static var allColors: [String] {
        freeColors + proOnlyColors
    }

    // MARK: - Color Info

    /// 컬러 이름 (한국어)
    static func colorName(for hex: String) -> String {
        switch hex.uppercased() {
        // Free colors
        case "#FF6B6B": return "코랄"
        case "#FFA94D": return "오렌지"
        case "#FFD93D": return "옐로우"
        case "#6BCB77": return "그린"
        case "#4D96FF": return "블루"
        case "#9B5DE5": return "퍼플"
        // Pro colors
        case "#FF1744": return "비비드 레드"
        case "#00BFA5": return "틸"
        case "#651FFF": return "딥 퍼플"
        case "#FF9100": return "앰버"
        case "#00E5FF": return "시안"
        case "#F50057": return "핑크"
        default: return "커스텀"
        }
    }

    /// Pro 컬러인지 확인
    static func isProColor(_ hex: String) -> Bool {
        proOnlyColors.contains(hex.uppercased())
    }

    // MARK: - Pro Theme Colors

    /// Pro 배지 그라데이션
    static let proBadgeGradient = LinearGradient(
        colors: [
            Color(hex: "#FFD700"),  // Gold
            Color(hex: "#FFA500")   // Orange
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Lifetime 버튼 그라데이션
    static let lifetimeButtonGradient = LinearGradient(
        colors: [
            Color(hex: "#FFD700"),  // Gold
            Color(hex: "#FF8C00")   // Dark Orange
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Monthly 버튼 그라데이션
    static let monthlyButtonGradient = LinearGradient(
        colors: [
            Color(hex: "#9B5DE5"),  // Purple
            Color(hex: "#6366F1")   // Indigo
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// 성공 색상
    static let successColor = Color(hex: "#4CAF50")

    /// 경고 색상 (Grace period)
    static let warningColor = Color(hex: "#FF9800")
}

// MARK: - Color Extension for Convenience

extension Color {
    /// Pro Badge 색상
    static var proBadge: Color {
        Color(hex: "#FFD700")
    }

    /// Pro Accent 색상
    static var proAccent: Color {
        Color(hex: "#FFD700")
    }
}
