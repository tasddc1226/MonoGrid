//
//  IntentErrors.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation

/// Custom errors for App Intents
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case habitNotSpecified
    case habitNotFound
    case invalidHabitId
    case containerNotFound
    case toggleFailed
    case noHabitsExist

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .habitNotSpecified:
            return LocalizedStringResource("습관을 선택해주세요")
        case .habitNotFound:
            return LocalizedStringResource("습관을 찾을 수 없습니다")
        case .invalidHabitId:
            return LocalizedStringResource("잘못된 습관 ID입니다")
        case .containerNotFound:
            return LocalizedStringResource("데이터에 접근할 수 없습니다")
        case .toggleFailed:
            return LocalizedStringResource("습관 상태를 변경할 수 없습니다")
        case .noHabitsExist:
            return LocalizedStringResource("등록된 습관이 없습니다")
        }
    }
}
