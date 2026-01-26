//
//  PolarRepository.swift
//  MonoGrid
//
//  Pro Business Model - Polar API Repository Protocol
//  Created on 2026-01-25.
//

import Foundation

/// Polar API 통신을 위한 Repository 프로토콜
protocol PolarRepository {
    /// 체크아웃 세션 생성
    func createCheckoutSession(
        productId: String,
        successUrl: String,
        cancelUrl: String
    ) async throws -> CheckoutSession

    /// 이메일로 라이선스 조회 (복원용)
    func fetchLicense(email: String) async throws -> PolarLicenseResponse?

    /// 구독 상태 조회
    func fetchSubscriptionStatus(subscriptionId: String) async throws -> PolarSubscriptionResponse

    /// 구독 해지
    func cancelSubscription(subscriptionId: String) async throws -> Bool
}

// MARK: - Response Models

/// 체크아웃 세션 응답
struct CheckoutSession: Codable {
    let id: String
    let url: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case expiresAt = "expires_at"
    }
}

/// Polar 라이선스 응답
struct PolarLicenseResponse: Codable {
    let customerId: String
    let productId: String
    let subscriptionId: String?
    let status: String
    let currentPeriodEnd: Date?
    let purchasedAt: Date

    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case productId = "product_id"
        case subscriptionId = "subscription_id"
        case status
        case currentPeriodEnd = "current_period_end"
        case purchasedAt = "purchased_at"
    }
}

/// Polar 구독 상태 응답
struct PolarSubscriptionResponse: Codable {
    let id: String
    let status: String  // "active", "canceled", "past_due", "expired"
    let currentPeriodEnd: Date
    let cancelAtPeriodEnd: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
    }

    /// 구독이 활성 상태인지
    var isActive: Bool {
        status == "active" || status == "past_due"
    }
}
