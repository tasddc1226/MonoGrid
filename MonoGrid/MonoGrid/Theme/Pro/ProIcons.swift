//
//  ProIcons.swift
//  MonoGrid
//
//  Pro Business Model - Pro App Icon Definitions
//  Created on 2026-01-25.
//

import Foundation

/// Pro 앱 아이콘 정의
enum ProIcons {
    // MARK: - Free Icons

    /// 무료 사용자용 기본 아이콘
    static let freeIcons: [AppIconOption] = [
        AppIconOption(
            id: "default",
            name: "기본",
            iconName: nil,  // Primary icon
            isPro: false
        ),
        AppIconOption(
            id: "dark",
            name: "다크",
            iconName: "AppIcon-Dark",
            isPro: false
        )
    ]

    // MARK: - Pro Icons

    /// Pro 전용 앱 아이콘
    static let proOnlyIcons: [String] = [
        "AppIcon-Gold",
        "AppIcon-Gradient",
        "AppIcon-Minimal",
        "AppIcon-Neon",
        "AppIcon-Retro"
    ]

    /// Pro 전용 아이콘 옵션
    static let proIconOptions: [AppIconOption] = [
        AppIconOption(
            id: "gold",
            name: "골드",
            iconName: "AppIcon-Gold",
            isPro: true
        ),
        AppIconOption(
            id: "gradient",
            name: "그라데이션",
            iconName: "AppIcon-Gradient",
            isPro: true
        ),
        AppIconOption(
            id: "minimal",
            name: "미니멀",
            iconName: "AppIcon-Minimal",
            isPro: true
        ),
        AppIconOption(
            id: "neon",
            name: "네온",
            iconName: "AppIcon-Neon",
            isPro: true
        ),
        AppIconOption(
            id: "retro",
            name: "레트로",
            iconName: "AppIcon-Retro",
            isPro: true
        )
    ]

    // MARK: - All Icons

    /// 모든 아이콘 옵션
    static var allIconOptions: [AppIconOption] {
        freeIcons + proIconOptions
    }

    // MARK: - Helpers

    /// Pro 아이콘인지 확인
    static func isProIcon(_ iconName: String) -> Bool {
        proOnlyIcons.contains(iconName)
    }
}

// MARK: - App Icon Option Model

/// 앱 아이콘 옵션
struct AppIconOption: Identifiable, Equatable {
    let id: String
    let name: String
    let iconName: String?  // nil for default icon
    let isPro: Bool

    /// 아이콘 이미지 이름 (Preview용)
    var previewImageName: String {
        iconName ?? "AppIcon"
    }
}
