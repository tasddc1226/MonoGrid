//
//  ProLicense.swift
//  MonoGrid
//
//  Pro Business Model - License Data Model
//  Created on 2026-01-25.
//

import Foundation

/// 라이선스 정보를 담는 모델
/// Keychain에 Codable로 직렬화하여 저장
struct ProLicense: Codable, Equatable {
    let type: LicenseType
    let purchaseDate: Date
    let expirationDate: Date?      // nil for Lifetime
    let polarCustomerId: String
    let polarSubscriptionId: String?  // nil for Lifetime
    let lastVerifiedAt: Date

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
}
