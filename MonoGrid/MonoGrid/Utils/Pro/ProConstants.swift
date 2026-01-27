//
//  ProConstants.swift
//  MonoGrid
//
//  Pro Business Model - Constants and Configuration
//  Created on 2026-01-25.
//  Updated on 2026-01-26 for RevenueCat integration.
//

import Foundation

enum ProConstants {
    // MARK: - RevenueCat Configuration

    /// RevenueCat API Key (loaded from Info.plist via xcconfig)
    static var revenueCatAPIKey: String {
        Bundle.main.infoDictionary?["RevenueCatAPIKey"] as? String ?? ""
    }

    /// RevenueCat Product IDs
    static let lifetimeProductId = "monogrid_pro_lifetime"
    static let monthlyProductId = "monogrid_pro_monthly"

    /// RevenueCat Entitlement IDs
    static let proEntitlementId = "pro"
    static let proLifetimeEntitlementId = "pro_lifetime"
    static let proMonthlyEntitlementId = "pro_monthly"

    // MARK: - Keychain Configuration

    /// Keychain service identifier
    static let keychainService = "com.suyoung.monogrid.license"

    /// Keychain account for license
    static let keychainLicenseAccount = "pro_license"

    // MARK: - Subscription Settings

    /// Grace period days for payment failures
    static let gracePeriodDays = 3

    /// Cache duration for license check (seconds)
    static let licenseCacheDuration: TimeInterval = 60

    /// Background sync interval (seconds)
    static let syncIntervalSeconds: TimeInterval = 3600 // 1 hour

    // MARK: - Prices (Display only - actual prices come from RevenueCat)

    /// Lifetime price (default, actual price from App Store)
    static let lifetimePrice: Decimal = 10.00

    /// Monthly price (default, actual price from App Store)
    static let monthlyPrice: Decimal = 2.99

    // MARK: - Feature List

    /// All Pro features for paywall display
    static let allProFeatures: [ProFeature] = ProFeature.allCases

    // MARK: - UserDefaults Keys

    enum UserDefaultsKeys {
        static let analyticsEnabled = "analytics_enabled"
        static let analyticsEventQueue = "analytics_event_queue"
        static let lastLicenseSync = "last_license_sync"
    }
}
