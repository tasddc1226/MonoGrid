//
//  LicenseManager.swift
//  MonoGrid
//
//  Pro Business Model - License Verification and State Management
//  Created on 2026-01-25.
//  Updated on 2026-01-26 for RevenueCat integration.
//

import Foundation
import Observation
import Network
import RevenueCat

/// 라이선스 검증 및 상태 관리
/// RevenueCat을 primary source로 사용, Keychain은 프로모 코드용 백업
@Observable
@MainActor
final class LicenseManager {
    static let shared = LicenseManager()

    // MARK: - Properties

    private(set) var currentState: SubscriptionState = .free
    private(set) var currentLicense: ProLicense?
    private(set) var isVerifying: Bool = false

    private let licenseRepository: LicenseRepository
    private let revenueCatManager: RevenueCatManager
    private let networkMonitor = NWPathMonitor()
    private var isOnline = true

    // Cache
    private var cacheTimestamp: Date?

    // MARK: - Initialization

    init(
        licenseRepository: LicenseRepository = KeychainLicenseRepository(),
        revenueCatManager: RevenueCatManager = .shared
    ) {
        self.licenseRepository = licenseRepository
        self.revenueCatManager = revenueCatManager

        setupNetworkMonitoring()
    }

    // MARK: - Public Methods

    /// Pro 기능 접근 가능 여부
    var hasProAccess: Bool {
        // 캐시 유효성 확인
        if let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < ProConstants.licenseCacheDuration {
            return currentState.hasProAccess
        }

        // 캐시 갱신
        updateStateFromSources()
        cacheTimestamp = Date()
        return currentState.hasProAccess
    }

    /// 앱 실행 시 호출 - 라이선스 검증
    func verifyOnLaunch() async {
        isVerifying = true
        defer { isVerifying = false }

        // 1. RevenueCat에서 상태 확인
        await revenueCatManager.refreshCustomerInfo()

        // 2. 상태 업데이트
        updateStateFromSources()

        // 3. 온라인이면 동기화
        if isOnline {
            await syncWithRevenueCat()
        }
    }

    /// 라이선스 저장 (프로모 코드용)
    func saveLicense(_ license: ProLicense) {
        do {
            try licenseRepository.save(license)
            currentLicense = license
            cacheTimestamp = Date()
            updateState(from: license)
        } catch {
            #if DEBUG
            print("License save failed: \(error)")
            #endif
        }
    }

    /// 구매 복원 (RevenueCat 사용)
    func restorePurchases() async throws -> Bool {
        isVerifying = true
        defer { isVerifying = false }

        do {
            let customerInfo = try await revenueCatManager.restorePurchases()
            updateStateFromRevenueCat(customerInfo: customerInfo)
            return currentState.hasProAccess
        } catch {
            throw error
        }
    }

    /// 라이선스 삭제 (로그아웃/만료 시)
    func clearLicense() {
        licenseRepository.delete()
        currentLicense = nil
        currentState = .free
        cacheTimestamp = nil
    }

    /// 강제 동기화
    func forceSync() async {
        await syncWithRevenueCat()
    }

    // MARK: - Private Methods

    private func updateStateFromSources() {
        // Priority 1: RevenueCat (actual purchases)
        if revenueCatManager.hasProAccess {
            updateStateFromRevenueCat()
            return
        }

        // Priority 2: Local license (promo codes)
        if let license = licenseRepository.load(), license.isValid {
            currentLicense = license
            updateState(from: license)
            return
        }

        // No valid license
        currentState = .free
        currentLicense = nil
    }

    private func updateStateFromRevenueCat(customerInfo: CustomerInfo? = nil) {
        let info = customerInfo ?? revenueCatManager.customerInfo
        guard let info = info else {
            currentState = .free
            return
        }

        // Check entitlements - RevenueCat's recommended approach
        let hasLifetimeEntitlement = info.entitlements["pro_lifetime"]?.isActive == true
        let hasMonthlyEntitlement = info.entitlements["pro_monthly"]?.isActive == true
        let hasProEntitlement = info.entitlements["pro"]?.isActive == true

        if hasLifetimeEntitlement || (hasProEntitlement && !hasMonthlyEntitlement) {
            // Lifetime purchase
            currentState = .proLifetime(since: info.originalPurchaseDate ?? Date())
            currentLicense = .fromRevenueCat(
                type: .lifetime,
                userId: revenueCatManager.currentUserId ?? "unknown",
                expirationDate: nil
            )
        } else if hasMonthlyEntitlement || hasProEntitlement {
            // Monthly subscription
            if let expiration = revenueCatManager.expirationDate {
                if Date() > expiration {
                    // In grace period
                    let graceEnd = Calendar.current.date(byAdding: .day, value: 3, to: expiration)!
                    if Date() < graceEnd {
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: graceEnd).day ?? 0
                        currentState = .gracePeriod(expiresAt: expiration, daysRemaining: days)
                    } else {
                        currentState = .expired
                    }
                } else {
                    currentState = .proMonthly(expiresAt: expiration, renewable: true)
                }
                currentLicense = .fromRevenueCat(
                    type: .monthly,
                    userId: revenueCatManager.currentUserId ?? "unknown",
                    expirationDate: expiration
                )
            }
        } else {
            currentState = .free
            currentLicense = nil
        }
    }

    private func updateState(from license: ProLicense) {
        if license.isValid {
            switch license.type {
            case .lifetime:
                currentState = .proLifetime(since: license.purchaseDate)
            case .monthly:
                if license.isInGracePeriod {
                    currentState = .gracePeriod(
                        expiresAt: license.expirationDate!,
                        daysRemaining: license.gracePeriodDaysRemaining
                    )
                } else {
                    currentState = .proMonthly(
                        expiresAt: license.expirationDate!,
                        renewable: true
                    )
                }
            }
        } else {
            currentState = .expired
            // 만료된 라이선스 삭제
            clearLicense()
        }
    }

    private func syncWithRevenueCat() async {
        await revenueCatManager.refreshCustomerInfo()
        updateStateFromRevenueCat()
    }

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOffline = self?.isOnline == false
                self?.isOnline = path.status == .satisfied

                // 오프라인 → 온라인 전환 시 동기화
                if wasOffline && self?.isOnline == true {
                    await self?.syncWithRevenueCat()
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    deinit {
        networkMonitor.cancel()
    }
}
