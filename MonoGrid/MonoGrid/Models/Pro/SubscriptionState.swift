//
//  SubscriptionState.swift
//  MonoGrid
//
//  Pro Business Model - Subscription State Machine
//  Created on 2026-01-25.
//

import Foundation

/// 구독 상태 머신
enum SubscriptionState: Equatable {
    case free
    case proLifetime(since: Date)
    case proMonthly(expiresAt: Date, renewable: Bool)
    case gracePeriod(expiresAt: Date, daysRemaining: Int)
    case expired

    /// 상태 텍스트 (설정 화면용)
    var statusText: String {
        switch self {
        case .free:
            return "무료 버전 사용 중"
        case .proLifetime(let since):
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.locale = Locale(identifier: "ko_KR")
            return "Lifetime · \(formatter.string(from: since)) 구매"
        case .proMonthly(let expiresAt, _):
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.locale = Locale(identifier: "ko_KR")
            return "Monthly · 다음 결제: \(formatter.string(from: expiresAt))"
        case .gracePeriod(_, let days):
            return "결제 정보 확인 필요 (\(days)일 남음)"
        case .expired:
            return "구독 만료됨"
        }
    }

    /// Pro 기능 사용 가능 여부
    var hasProAccess: Bool {
        switch self {
        case .free, .expired:
            return false
        case .proLifetime, .proMonthly, .gracePeriod:
            return true
        }
    }

    /// 구독 관리 가능 여부 (Monthly only)
    var canManageSubscription: Bool {
        switch self {
        case .proMonthly, .gracePeriod:
            return true
        default:
            return false
        }
    }

    /// Lifetime 업그레이드 가능 여부
    var canUpgradeToLifetime: Bool {
        switch self {
        case .proMonthly, .gracePeriod:
            return true
        default:
            return false
        }
    }

    /// 아이콘 이름
    var iconName: String {
        switch self {
        case .free:
            return "person.crop.circle"
        case .proLifetime:
            return "crown.fill"
        case .proMonthly:
            return "star.fill"
        case .gracePeriod:
            return "exclamationmark.triangle.fill"
        case .expired:
            return "xmark.circle.fill"
        }
    }
}
