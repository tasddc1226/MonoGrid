//
//  ProProduct.swift
//  MonoGrid
//
//  Pro Business Model - Product Definitions
//  Created on 2026-01-25.
//

import Foundation

/// Polar 상품 정의
enum ProProduct: String, CaseIterable, Identifiable {
    case lifetime = "monogrid_pro_lifetime"
    case monthly = "monogrid_pro_monthly"

    var id: String { rawValue }

    var polarProductId: String {
        rawValue
    }

    var price: Decimal {
        switch self {
        case .lifetime: return 10.00
        case .monthly: return 2.99
        }
    }

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
