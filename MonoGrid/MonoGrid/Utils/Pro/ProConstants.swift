//
//  ProConstants.swift
//  MonoGrid
//
//  Pro Business Model - Constants and Configuration
//  Created on 2026-01-25.
//

import Foundation

enum ProConstants {
    // MARK: - Polar Configuration

    /// Polar API Key (Keychain에서 로드하거나 환경변수 사용)
    static var polarAPIKey: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["POLAR_API_KEY"] ?? "pol_test_placeholder"
        #else
        return KeychainHelper.shared.loadAPIKey() ?? ""
        #endif
    }

    /// Polar API Base URL
    static let polarBaseURL = "https://api.polar.sh/v1"

    /// Polar Product IDs
    static let lifetimeProductId = "monogrid_pro_lifetime"
    static let monthlyProductId = "monogrid_pro_monthly"

    // MARK: - Checkout URLs

    /// Checkout success URL
    static let checkoutSuccessURL = "monogrid://checkout/success"

    /// Checkout cancel URL
    static let checkoutCancelURL = "monogrid://checkout/cancel"

    /// URL Scheme
    static let urlScheme = "monogrid"

    // MARK: - Keychain Configuration

    /// Keychain service identifier
    static let keychainService = "com.suyoung.monogrid.license"

    /// Keychain account for license
    static let keychainLicenseAccount = "pro_license"

    /// Keychain account for API key
    static let keychainAPIKeyAccount = "polar_api_key"

    // MARK: - Subscription Settings

    /// Grace period days for payment failures
    static let gracePeriodDays = 3

    /// Cache duration for license check (seconds)
    static let licenseCacheDuration: TimeInterval = 60

    /// Background sync interval (seconds)
    static let syncIntervalSeconds: TimeInterval = 3600 // 1 hour

    // MARK: - Prices

    /// Lifetime price
    static let lifetimePrice: Decimal = 10.00

    /// Monthly price
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
