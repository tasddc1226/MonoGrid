//
//  RevenueCatManager.swift
//  MonoGrid
//
//  Pro Business Model - RevenueCat Integration Manager
//  Created on 2026-01-26.
//

import Foundation
import RevenueCat
import Observation

/// RevenueCat error types
enum RevenueCatError: LocalizedError {
    case notConfigured
    case purchaseFailed(String)
    case restoreFailed(String)
    case noProductsAvailable
    case networkError
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "RevenueCat이 초기화되지 않았습니다"
        case .purchaseFailed(let message):
            return "구매 실패: \(message)"
        case .restoreFailed(let message):
            return "복원 실패: \(message)"
        case .noProductsAvailable:
            return "상품 정보를 불러올 수 없습니다"
        case .networkError:
            return "네트워크 오류가 발생했습니다"
        case .userCancelled:
            return "구매가 취소되었습니다"
        }
    }
}

/// RevenueCat Manager - handles all RevenueCat SDK interactions
@Observable
@MainActor
final class RevenueCatManager {
    static let shared = RevenueCatManager()

    // MARK: - Properties

    private(set) var isConfigured = false
    private(set) var offerings: Offerings?
    private(set) var customerInfo: CustomerInfo?
    private(set) var isLoading = false

    // Product IDs
    static let lifetimeProductId = "monogrid_pro_lifetime"
    static let monthlyProductId = "monogrid_pro_monthly"

    // MARK: - Initialization

    private init() {}

    // MARK: - API Keys

    /// RevenueCat API Keys
    private enum APIKeys {
        // Test Store key for Debug builds (Simulator, Development)
        static let test = "test_dhYpLJFtZuBTPhRVssmkIlxQhza"
        // Production key for Release builds (TestFlight, App Store)
        static let production = "appl_DQTDytTwRzFXrmzqErEgHSqxRlj"

        static var current: String {
            #if DEBUG
            return test
            #else
            return production
            #endif
        }
    }

    // MARK: - Configuration

    /// Configure RevenueCat on app launch
    func configure() {
        guard !isConfigured else { return }

        let apiKey = APIKeys.current

        #if DEBUG
        Purchases.logLevel = .debug
        print("RevenueCatManager: Using \(apiKey.hasPrefix("test_") ? "TEST" : "PRODUCTION") API key")
        #else
        Purchases.logLevel = .error
        #endif

        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true

        #if DEBUG
        print("RevenueCatManager: Configured successfully")
        #endif

        // Fetch initial customer info
        Task {
            await refreshCustomerInfo()
        }
    }

    // MARK: - Subscription Status

    /// Check if user has active Pro subscription
    var hasProAccess: Bool {
        guard let customerInfo = customerInfo else { return false }
        return customerInfo.entitlements["pro"]?.isActive == true
    }

    /// Check if user has lifetime purchase
    var hasLifetime: Bool {
        guard let customerInfo = customerInfo else { return false }
        // Check for non-consumable lifetime product via entitlement or purchased products
        return customerInfo.entitlements["pro_lifetime"]?.isActive == true ||
               customerInfo.allPurchasedProductIdentifiers.contains(Self.lifetimeProductId)
    }

    /// Check if user has monthly subscription
    var hasMonthly: Bool {
        guard let customerInfo = customerInfo else { return false }
        return customerInfo.entitlements["pro_monthly"]?.isActive == true
    }

    /// Get subscription expiration date (for monthly)
    var expirationDate: Date? {
        guard let customerInfo = customerInfo else { return nil }
        return customerInfo.entitlements["pro"]?.expirationDate ??
               customerInfo.entitlements["pro_monthly"]?.expirationDate
    }

    /// Refresh customer info from RevenueCat
    func refreshCustomerInfo() async {
        guard isConfigured else { return }

        do {
            customerInfo = try await Purchases.shared.customerInfo()
            #if DEBUG
            print("RevenueCatManager: Customer info refreshed - Pro access: \(hasProAccess)")
            #endif
        } catch {
            #if DEBUG
            print("RevenueCatManager: Failed to refresh customer info: \(error)")
            #endif
        }
    }

    // MARK: - Offerings

    /// Fetch available offerings for paywall
    func fetchOfferings() async throws -> Offerings {
        guard isConfigured else { throw RevenueCatError.notConfigured }

        isLoading = true
        defer { isLoading = false }

        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            return offerings
        } catch {
            throw RevenueCatError.networkError
        }
    }

    /// Get package for product type
    func getPackage(for productType: ProProduct) -> Package? {
        guard let offerings = offerings,
              let current = offerings.current else { return nil }

        switch productType {
        case .lifetime:
            return current.lifetime ?? current.package(identifier: Self.lifetimeProductId)
        case .monthly:
            return current.monthly ?? current.package(identifier: Self.monthlyProductId)
        }
    }

    // MARK: - Purchase

    /// Purchase a package
    func purchase(package: Package) async throws -> CustomerInfo {
        guard isConfigured else { throw RevenueCatError.notConfigured }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)

            if result.userCancelled {
                throw RevenueCatError.userCancelled
            }

            customerInfo = result.customerInfo
            return result.customerInfo
        } catch let error as RevenueCatError {
            throw error
        } catch {
            if let rcError = error as? RevenueCat.ErrorCode {
                if rcError == .purchaseCancelledError {
                    throw RevenueCatError.userCancelled
                }
            }
            throw RevenueCatError.purchaseFailed(error.localizedDescription)
        }
    }

    /// Purchase by product type
    func purchase(product: ProProduct) async throws -> CustomerInfo {
        // First ensure offerings are loaded
        if offerings == nil {
            _ = try await fetchOfferings()
        }

        guard let package = getPackage(for: product) else {
            throw RevenueCatError.noProductsAvailable
        }

        return try await purchase(package: package)
    }

    // MARK: - Restore

    /// Restore purchases
    func restorePurchases() async throws -> CustomerInfo {
        guard isConfigured else { throw RevenueCatError.notConfigured }

        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            return customerInfo
        } catch {
            throw RevenueCatError.restoreFailed(error.localizedDescription)
        }
    }

    // MARK: - User Management

    /// Log in a user (for account linking)
    func logIn(userId: String) async throws {
        guard isConfigured else { throw RevenueCatError.notConfigured }

        let (customerInfo, _) = try await Purchases.shared.logIn(userId)
        self.customerInfo = customerInfo
    }

    /// Log out current user
    func logOut() async throws {
        guard isConfigured else { throw RevenueCatError.notConfigured }

        customerInfo = try await Purchases.shared.logOut()
    }

    /// Get current user ID
    var currentUserId: String? {
        guard isConfigured else { return nil }
        return Purchases.shared.appUserID
    }
}
