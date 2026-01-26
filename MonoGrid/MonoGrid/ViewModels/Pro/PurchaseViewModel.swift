//
//  PurchaseViewModel.swift
//  MonoGrid
//
//  Pro Business Model - Purchase Flow State Manager
//  Created on 2026-01-25.
//

import Foundation
import Observation
import SwiftUI

/// 구매 플로우 상태 관리
@Observable
@MainActor
final class PurchaseViewModel {
    // MARK: - Dependencies

    private let polarRepository: PolarRepository
    private let checkoutCoordinator: PolarCheckoutCoordinator
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
    var restoreEmail: String = ""
    var showRestoreInput: Bool = false

    // MARK: - Initialization

    init(
        polarRepository: PolarRepository = PolarAPIRepository(),
        checkoutCoordinator: PolarCheckoutCoordinator = PolarCheckoutCoordinator(),
        analyticsService: AnalyticsService = .shared
    ) {
        self.polarRepository = polarRepository
        self.checkoutCoordinator = checkoutCoordinator
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
            // 1. Create checkout session
            let session = try await polarRepository.createCheckoutSession(
                productId: product.polarProductId,
                successUrl: ProConstants.checkoutSuccessURL,
                cancelUrl: ProConstants.checkoutCancelURL
            )

            isLoading = false

            // 2. Start checkout flow
            guard let checkoutURL = URL(string: session.url) else {
                throw CheckoutError.invalidCallback
            }

            let result = try await checkoutCoordinator.startCheckout(checkoutURL: checkoutURL)

            // 3. Handle result
            switch result {
            case .success(let customerId):
                await handlePurchaseSuccess(product: product, customerId: customerId)

            case .cancelled:
                isPurchasing = false
            }

        } catch {
            handlePurchaseError(product: product, error: error)
        }
    }

    func cancelPurchase() {
        checkoutCoordinator.cancelCheckout()
        isPurchasing = false
        isLoading = false
    }

    // MARK: - Restore

    func startRestore() {
        showRestoreInput = true
    }

    func submitRestore(email: String, proViewModel: ProViewModel) async throws -> Bool {
        guard !isRestoring else { return false }
        guard isValidEmail(email) else {
            errorMessage = "유효한 이메일 주소를 입력해주세요"
            showError = true
            return false
        }

        isRestoring = true
        errorMessage = nil

        defer { isRestoring = false }

        do {
            let restored = try await proViewModel.restorePurchase(email: email)

            if restored {
                showRestoreInput = false
                return true
            } else {
                errorMessage = "해당 이메일로 구매 내역을 찾을 수 없습니다"
                showError = true
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
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

    private func handlePurchaseSuccess(product: ProProduct, customerId: String?) async {
        // Create license
        let license = ProLicense(
            type: product.licenseType,
            purchaseDate: Date(),
            expirationDate: product == .monthly ? Calendar.current.date(byAdding: .month, value: 1, to: Date()) : nil,
            polarCustomerId: customerId ?? "unknown",
            polarSubscriptionId: product == .monthly ? "pending" : nil,
            lastVerifiedAt: Date()
        )

        purchasedLicense = license
        showSuccess = true
        isPurchasing = false

        HapticManager.shared.success()
    }

    private func handlePurchaseError(product: ProProduct, error: Error) {
        isPurchasing = false
        isLoading = false

        let errorCode: String
        if let polarError = error as? PolarError {
            errorMessage = polarError.errorDescription
            errorCode = String(describing: polarError)
        } else if let checkoutError = error as? CheckoutError {
            errorMessage = checkoutError.errorDescription
            errorCode = String(describing: checkoutError)
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

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
