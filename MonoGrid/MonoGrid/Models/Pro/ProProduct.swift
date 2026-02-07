//
//  ProProduct.swift
//  MonoGrid
//
//  Pro Business Model - Product Definitions
//  Created on 2026-01-25.
//  Updated on 2026-01-26 for RevenueCat integration.
//

import Foundation

/// Pro 상품 정의
enum ProProduct: String, CaseIterable, Identifiable {
    case lifetime = "monogrid_pro_lifetime"
    case monthly = "monogrid_pro_monthly"

    var id: String { rawValue }

    /// RevenueCat Product ID
    var productId: String {
        rawValue
    }

    /// Default price (actual prices come from RevenueCat/App Store)
    var price: Decimal {
        switch self {
        case .lifetime: return 10.00
        case .monthly: return 2.99
        }
    }

    /// Display price
    var displayPrice: String {
        switch self {
        case .lifetime: return "$10"
        case .monthly: return "$2.99/월"
        }
    }

    var title: String {
        switch self {
        case .lifetime: return "Lifetime"
        case .monthly: return "Monthly"
        }
    }

    var subtitle: String {
        switch self {
        case .lifetime: return "한 번 구매로 영원히 사용"
        case .monthly: return "언제든 해지 가능"
        }
    }

    var isRecommended: Bool {
        self == .lifetime
    }

    var licenseType: LicenseType {
        switch self {
        case .lifetime: return .lifetime
        case .monthly: return .monthly
        }
    }
}
