//
//  PurchaseViewModel.swift
//  MonoGrid
//
//  Pro Business Model - Purchase Flow State Manager
//  Created on 2026-01-25.
//  Updated on 2026-01-26 for RevenueCat integration.
//

import Foundation
import Observation
import SwiftUI
import RevenueCat

/// 구매 플로우 상태 관리
@Observable
@MainActor
final class PurchaseViewModel {
    // MARK: - Dependencies

    private let revenueCatManager: RevenueCatManager
    private let analyticsService: AnalyticsService

    // MARK: - State

    var isLoading: Bool = false
    var isPurchasing: Bool = false
    var selectedProduct: ProProduct?
    var errorMessage: String?
    var showError: Bool = false
    var showSuccess: Bool = false
    var purchasedLicense: ProLicense?

    // Restore
    var isRestoring: Bool = false
    var restoreEmail: String = ""  // Not used with RevenueCat, kept for UI compatibility
    var showRestoreInput: Bool = false

    // MARK: - Initialization

    init(
        revenueCatManager: RevenueCatManager = .shared,
        analyticsService: AnalyticsService = .shared
    ) {
        self.revenueCatManager = revenueCatManager
        self.analyticsService = analyticsService
    }

    // MARK: - Purchase

    func startPurchase(product: ProProduct) async {
        guard !isPurchasing else { return }

        isPurchasing = true
        isLoading = true
        selectedProduct = product
        errorMessage = nil

        // Analytics
        analyticsService.track(.purchaseStarted(
            productType: product.title.lowercased(),
            price: product.price
        ))

        do {
            // Purchase through RevenueCat
            let customerInfo = try await revenueCatManager.purchase(product: product)

            // Handle success
            await handlePurchaseSuccess(product: product, customerInfo: customerInfo)

        } catch let error as RevenueCatError {
            handlePurchaseError(product: product, error: error)
        } catch {
            handlePurchaseError(product: product, error: error)
        }
    }

    func cancelPurchase() {
        isPurchasing = false
        isLoading = false
    }

    // MARK: - Restore

    func startRestore() {
        // RevenueCat doesn't need email, restore directly
        Task {
            await performRestore()
        }
    }

    func performRestore() async {
        guard !isRestoring else { return }

        isRestoring = true
        isLoading = true
        errorMessage = nil

        analyticsService.track(.restoreAttempted)

        do {
            let customerInfo = try await revenueCatManager.restorePurchases()

            if revenueCatManager.hasProAccess {
                // Restore successful
                let license = ProLicense.fromRevenueCat(
                    type: revenueCatManager.hasLifetime ? .lifetime : .monthly,
                    userId: revenueCatManager.currentUserId ?? "unknown",
                    expirationDate: revenueCatManager.expirationDate
                )

                purchasedLicense = license
                showSuccess = true

                analyticsService.track(.restoreCompleted(
                    productType: license.type.rawValue
                ))

                HapticManager.shared.success()
            } else {
                // No purchases found
                errorMessage = "구매 내역을 찾을 수 없습니다"
                showError = true
                HapticManager.shared.warning()
            }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
        }

        isRestoring = false
        isLoading = false
    }

    func submitRestore(email: String, proViewModel: ProViewModel) async throws -> Bool {
        // RevenueCat doesn't need email - restore is automatic
        await performRestore()
        return revenueCatManager.hasProAccess
    }

    func cancelRestore() {
        showRestoreInput = false
        restoreEmail = ""
    }

    // MARK: - Error Handling

    func dismissError() {
        showError = false
        errorMessage = nil
    }

    // MARK: - Success

    func dismissSuccess() {
        showSuccess = false
        purchasedLicense = nil
    }

    // MARK: - Private

    private func handlePurchaseSuccess(product: ProProduct, customerInfo: CustomerInfo) async {
        // Create license from RevenueCat info
        let license = ProLicense.fromRevenueCat(
            type: product.licenseType,
            userId: revenueCatManager.currentUserId ?? "unknown",
            expirationDate: product == .monthly ? revenueCatManager.expirationDate : nil
        )

        purchasedLicense = license
        showSuccess = true
        isPurchasing = false
        isLoading = false

        analyticsService.track(.purchaseCompleted(
            productType: product.title.lowercased(),
            price: product.price,
            isFirstPurchase: true
        ))

        HapticManager.shared.success()
    }

    private func handlePurchaseError(product: ProProduct, error: Error) {
        isPurchasing = false
        isLoading = false

        let errorCode: String

        if let rcError = error as? RevenueCatError {
            switch rcError {
            case .userCancelled:
                // User cancelled - don't show error
                return
            default:
                errorMessage = rcError.errorDescription
                errorCode = String(describing: rcError)
            }
        } else {
            errorMessage = error.localizedDescription
            errorCode = "unknown"
        }

        showError = true

        analyticsService.track(.purchaseFailed(
            productType: product.title.lowercased(),
            errorCode: errorCode
        ))

        HapticManager.shared.warning()
    }
}
