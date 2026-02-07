//
//  LicenseType.swift
//  MonoGrid
//
//  Pro Business Model - License Type Definition
//  Created on 2026-01-25.
//

import Foundation

/// 라이선스 타입
enum LicenseType: String, Codable, CaseIterable {
    case lifetime = "lifetime"
    case monthly = "monthly"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .lifetime:
            return "Lifetime"
        case .monthly:
            return "Monthly"
        }
    }

    /// Description for settings
    var description: String {
        switch self {
        case .lifetime:
            return "한 번 구매로 영원히 사용"
        case .monthly:
            return "월간 구독"
        }
    }
}
