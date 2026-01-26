//
//  AnalyticsService.swift
//  MonoGrid
//
//  Pro Business Model - Analytics Event Tracking
//  Created on 2026-01-25.
//

import Foundation

// MARK: - Analytics Events

/// 분석 이벤트 정의
enum AnalyticsEvent {
    case paywallViewed(trigger: ProFeature)
    case purchaseStarted(productType: String, price: Decimal)
    case purchaseCompleted(productType: String, price: Decimal, isFirstPurchase: Bool)
    case purchaseFailed(productType: String, errorCode: String)
    case restoreAttempted
    case restoreCompleted(productType: String)
    case paywallDismissed(trigger: ProFeature, timeSpent: TimeInterval)

    var name: String {
        switch self {
        case .paywallViewed: return "paywall_viewed"
        case .purchaseStarted: return "purchase_started"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseFailed: return "purchase_failed"
        case .restoreAttempted: return "restore_attempted"
        case .restoreCompleted: return "restore_completed"
        case .paywallDismissed: return "paywall_dismissed"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .paywallViewed(let trigger):
            return [
                "trigger_feature": trigger.analyticsId,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .purchaseStarted(let productType, let price):
            return [
                "product_type": productType,
                "price": NSDecimalNumber(decimal: price).doubleValue
            ]
        case .purchaseCompleted(let productType, let price, let isFirst):
            return [
                "product_type": productType,
                "price": NSDecimalNumber(decimal: price).doubleValue,
                "is_first_purchase": isFirst
            ]
        case .purchaseFailed(let productType, let errorCode):
            return [
                "product_type": productType,
                "error_code": errorCode
            ]
        case .restoreAttempted:
            return [
                "timestamp": Date().timeIntervalSince1970
            ]
        case .restoreCompleted(let productType):
            return [
                "product_type": productType
            ]
        case .paywallDismissed(let trigger, let timeSpent):
            return [
                "trigger_feature": trigger.analyticsId,
                "time_spent_seconds": timeSpent
            ]
        }
    }
}

// MARK: - Analytics Service

/// 분석 서비스
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private let storage = UserDefaults.standard
    private let queueKey = ProConstants.UserDefaultsKeys.analyticsEventQueue
    private let maxQueueSize = 100

    private var isEnabled: Bool {
        storage.bool(forKey: ProConstants.UserDefaultsKeys.analyticsEnabled)
    }

    private init() {
        // 기본값: 분석 활성화
        if storage.object(forKey: ProConstants.UserDefaultsKeys.analyticsEnabled) == nil {
            storage.set(true, forKey: ProConstants.UserDefaultsKeys.analyticsEnabled)
        }
    }

    /// 이벤트 추적
    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }

        let eventData: [String: Any] = [
            "name": event.name,
            "parameters": event.parameters,
            "timestamp": Date().timeIntervalSince1970
        ]

        appendToQueue(eventData)

        #if DEBUG
        print("📊 Analytics: \(event.name) - \(event.parameters)")
        #endif
    }

    /// 분석 활성화/비활성화
    func setEnabled(_ enabled: Bool) {
        storage.set(enabled, forKey: ProConstants.UserDefaultsKeys.analyticsEnabled)
    }

    /// 큐에 쌓인 이벤트 조회
    func getQueuedEvents() -> [[String: Any]] {
        storage.array(forKey: queueKey) as? [[String: Any]] ?? []
    }

    /// 큐 비우기
    func clearQueue() {
        storage.removeObject(forKey: queueKey)
    }

    /// 큐에 쌓인 이벤트 전송 (추후 백엔드 구현 시)
    func flush() async {
        // TODO: 백엔드 API로 배치 전송
        // 현재는 로컬 저장만
    }

    // MARK: - Private

    private func appendToQueue(_ event: [String: Any]) {
        var queue = storage.array(forKey: queueKey) as? [[String: Any]] ?? []
        queue.append(event)

        // 최대 크기 유지
        if queue.count > maxQueueSize {
            queue = Array(queue.suffix(maxQueueSize))
        }

        storage.set(queue, forKey: queueKey)
    }
}
