//
//  ProViewModel.swift
//  MonoGrid
//
//  Pro Business Model - Main Pro State Manager
//  Created on 2026-01-25.
//

import Foundation
import Observation
import SwiftUI

/// Pro 기능 전체 상태 관리
@Observable
@MainActor
final class ProViewModel {
    // MARK: - Dependencies

    private let licenseManager: LicenseManager
    private let analyticsService: AnalyticsService

    // MARK: - State

    var subscriptionState: SubscriptionState {
        licenseManager.currentState
    }

    var hasProAccess: Bool {
        licenseManager.hasProAccess
    }

    var currentLicense: ProLicense? {
        licenseManager.currentLicense
    }

    var showPaywall: Bool = false
    var paywallTrigger: ProFeature?
    private var paywallOpenedAt: Date?

    var showGraceBanner: Bool {
        if case .gracePeriod = subscriptionState { return true }
        return false
    }

    var gracePeriodDaysRemaining: Int {
        if case .gracePeriod(_, let days) = subscriptionState {
            return days
        }
        return 0
    }

    // MARK: - Initialization

    init(
        licenseManager: LicenseManager = .shared,
        analyticsService: AnalyticsService = .shared
    ) {
        self.licenseManager = licenseManager
        self.analyticsService = analyticsService
    }

    // MARK: - Feature Gating

    /// Pro 기능 접근 시도 시 호출
    /// - Returns: true if access granted, false if paywall shown
    @discardableResult
    func requestAccess(to feature: ProFeature) -> Bool {
        if hasProAccess {
            return true
        }

        // Prevent showing paywall if already showing
        guard !showPaywall else { return false }

        // Paywall 표시
        paywallTrigger = feature
        paywallOpenedAt = Date()
        showPaywall = true

        // Analytics
        analyticsService.track(.paywallViewed(trigger: feature))

        // Haptic feedback
        HapticManager.shared.lightImpact()

        return false
    }

    /// Paywall 닫기
    func dismissPaywall() {
        if let trigger = paywallTrigger, let openedAt = paywallOpenedAt {
            let timeSpent = Date().timeIntervalSince(openedAt)
            analyticsService.track(.paywallDismissed(trigger: trigger, timeSpent: timeSpent))
        }

        showPaywall = false
        paywallTrigger = nil
        paywallOpenedAt = nil
    }

    // MARK: - License Operations

    func onPurchaseCompleted(license: ProLicense) {
        licenseManager.saveLicense(license)
        dismissPaywall()

        let isFirstPurchase = !licenseManager.hasProAccess

        analyticsService.track(.purchaseCompleted(
            productType: license.type == .lifetime ? "lifetime" : "monthly",
            price: license.type == .lifetime ? ProConstants.lifetimePrice : ProConstants.monthlyPrice,
            isFirstPurchase: isFirstPurchase
        ))

        // Success haptic
        HapticManager.shared.success()
    }

    /// Restore purchases using RevenueCat
    func restorePurchases() async throws -> Bool {
        analyticsService.track(.restoreAttempted)

        let restored = try await licenseManager.restorePurchases()

        if restored {
            analyticsService.track(.restoreCompleted(
                productType: licenseManager.currentLicense?.type.rawValue ?? "unknown"
            ))
            dismissPaywall()
            HapticManager.shared.success()
        }

        return restored
    }

    /// Legacy restore method for compatibility (not used with RevenueCat)
    @available(*, deprecated, message: "Use restorePurchases() instead")
    func restorePurchase(email: String) async throws -> Bool {
        return try await restorePurchases()
    }

    func verifyLicenseOnLaunch() async {
        await licenseManager.verifyOnLaunch()
    }

    func forceSync() async {
        await licenseManager.forceSync()
    }

    /// Refresh Pro status (used after promo code redemption)
    func refreshProStatus() async {
        await licenseManager.verifyOnLaunch()
    }
}
