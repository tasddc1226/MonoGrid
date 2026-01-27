//
//  ProLicense.swift
//  MonoGrid
//
//  Pro Business Model - License Data Model
//  Created on 2026-01-25.
//  Updated on 2026-01-26 for RevenueCat integration.
//

import Foundation

/// 라이선스 정보를 담는 모델
/// Keychain에 Codable로 직렬화하여 저장 (프로모 코드용)
/// RevenueCat 구매는 RevenueCatManager가 직접 관리
struct ProLicense: Codable, Equatable {
    let type: LicenseType
    let purchaseDate: Date
    let expirationDate: Date?      // nil for Lifetime
    let userId: String             // RevenueCat user ID or promo code ID
    let subscriptionId: String?    // nil for Lifetime
    let lastVerifiedAt: Date
    let source: LicenseSource      // Where the license came from

    /// License source
    enum LicenseSource: String, Codable {
        case revenueCat = "revenuecat"
        case promoCode = "promo_code"
    }

    /// 라이선스 유효성 검증 (로컬)
    var isValid: Bool {
        switch type {
        case .lifetime:
            return true
        case .monthly:
            guard let expiration = expirationDate else { return false }
            // 3일 유예 기간 포함
            let graceDate = Calendar.current.date(byAdding: .day, value: 3, to: expiration)!
            return Date() < graceDate
        }
    }

    /// 유예 기간 중인지 확인
    var isInGracePeriod: Bool {
        guard type == .monthly, let expiration = expirationDate else { return false }
        return Date() > expiration && isValid
    }

    /// 유예 기간 남은 일수
    var gracePeriodDaysRemaining: Int {
        guard isInGracePeriod, let expiration = expirationDate else { return 0 }
        let graceEnd = Calendar.current.date(byAdding: .day, value: 3, to: expiration)!
        let days = Calendar.current.dateComponents([.day], from: Date(), to: graceEnd).day ?? 0
        return max(0, days)
    }

    /// 다음 결제일 (Monthly only)
    var nextBillingDate: Date? {
        guard type == .monthly else { return nil }
        return expirationDate
    }

    // MARK: - Factory Methods

    /// Create license from RevenueCat purchase
    static func fromRevenueCat(
        type: LicenseType,
        userId: String,
        expirationDate: Date?
    ) -> ProLicense {
        ProLicense(
            type: type,
            purchaseDate: Date(),
            expirationDate: expirationDate,
            userId: userId,
            subscriptionId: type == .monthly ? "revenuecat_subscription" : nil,
            lastVerifiedAt: Date(),
            source: .revenueCat
        )
    }

    /// Create license from promo code
    static func fromPromoCode(promoId: String) -> ProLicense {
        ProLicense(
            type: .lifetime,
            purchaseDate: Date(),
            expirationDate: nil,
            userId: promoId,
            subscriptionId: nil,
            lastVerifiedAt: Date(),
            source: .promoCode
        )
    }
}
