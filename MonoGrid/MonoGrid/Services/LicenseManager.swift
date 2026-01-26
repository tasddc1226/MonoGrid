//
//  LicenseManager.swift
//  MonoGrid
//
//  Pro Business Model - License Verification and State Management
//  Created on 2026-01-25.
//

import Foundation
import Observation
import Network

/// 라이선스 검증 및 상태 관리
@Observable
@MainActor
final class LicenseManager {
    static let shared = LicenseManager()

    // MARK: - Properties

    private(set) var currentState: SubscriptionState = .free
    private(set) var currentLicense: ProLicense?
    private(set) var isVerifying: Bool = false

    private let licenseRepository: LicenseRepository
    private let polarRepository: PolarRepository
    private let networkMonitor = NWPathMonitor()
    private var isOnline = true

    // Cache
    private var cacheTimestamp: Date?

    // MARK: - Initialization

    init(
        licenseRepository: LicenseRepository = KeychainLicenseRepository(),
        polarRepository: PolarRepository = PolarAPIRepository()
    ) {
        self.licenseRepository = licenseRepository
        self.polarRepository = polarRepository

        setupNetworkMonitoring()
        loadLocalLicense()
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
        loadLocalLicense()
        cacheTimestamp = Date()
        return currentState.hasProAccess
    }

    /// 앱 실행 시 호출 - 로컬 라이선스 검증
    func verifyOnLaunch() async {
        // 1. 로컬 라이선스 로드
        loadLocalLicense()

        // 2. 온라인이면 백그라운드에서 서버 검증
        if isOnline {
            await syncWithServer()
        }
    }

    /// 라이선스 저장 (구매 완료 후 호출)
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

    /// 라이선스 복원 (이메일 기반)
    func restoreLicense(email: String) async throws -> Bool {
        isVerifying = true
        defer { isVerifying = false }

        guard let polarLicense = try await polarRepository.fetchLicense(email: email) else {
            return false
        }

        let license = ProLicense(
            type: polarLicense.subscriptionId == nil ? .lifetime : .monthly,
            purchaseDate: polarLicense.purchasedAt,
            expirationDate: polarLicense.currentPeriodEnd,
            polarCustomerId: polarLicense.customerId,
            polarSubscriptionId: polarLicense.subscriptionId,
            lastVerifiedAt: Date()
        )

        saveLicense(license)
        return true
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
        await syncWithServer()
    }

    // MARK: - Private Methods

    private func loadLocalLicense() {
        guard let license = licenseRepository.load() else {
            currentState = .free
            return
        }

        currentLicense = license
        updateState(from: license)
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

    private func syncWithServer() async {
        guard let license = currentLicense else { return }

        // Lifetime은 서버 검증 불필요
        guard license.type == .monthly,
              let subscriptionId = license.polarSubscriptionId else { return }

        do {
            let subscription = try await polarRepository.fetchSubscriptionStatus(subscriptionId: subscriptionId)

            // 서버 상태와 로컬 상태 동기화
            let updatedLicense = ProLicense(
                type: license.type,
                purchaseDate: license.purchaseDate,
                expirationDate: subscription.currentPeriodEnd,
                polarCustomerId: license.polarCustomerId,
                polarSubscriptionId: subscriptionId,
                lastVerifiedAt: Date()
            )

            saveLicense(updatedLicense)

            // 구독이 만료/취소된 경우
            if !subscription.isActive {
                clearLicense()
            }
        } catch {
            // 네트워크 에러는 무시 (로컬 라이선스 유지)
            #if DEBUG
            print("Server sync failed: \(error)")
            #endif
        }
    }

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOffline = self?.isOnline == false
                self?.isOnline = path.status == .satisfied

                // 오프라인 → 온라인 전환 시 동기화
                if wasOffline && self?.isOnline == true {
                    await self?.syncWithServer()
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    deinit {
        networkMonitor.cancel()
    }
}
