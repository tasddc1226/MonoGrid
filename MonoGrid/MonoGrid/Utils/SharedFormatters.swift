//
//  SharedFormatters.swift
//  MonoGrid
//
//  Performance optimization: Static DateFormatter/Calendar instances
//  Created on 2026-01-25.
//

import Foundation

/// 앱 전역에서 재사용하는 포맷터/캘린더 인스턴스
/// 매번 생성하지 않고 공유하여 성능 향상
enum SharedInstances {
    // MARK: - Calendar

    /// 캐싱된 Calendar 인스턴스 (매번 Calendar.current 호출 방지)
    /// ~0.1ms/call 절약
    static let calendar: Calendar = {
        var cal = Calendar.current
        cal.locale = Locale.current
        return cal
    }()

    // MARK: - DateFormatters

    /// 월 레이블용 포맷터 (MMM)
    /// YearlyGridView에서 사용
    static let monthLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale.current
        return formatter
    }()

    /// 접근성 레이블용 포맷터 (M월 d일)
    /// 그리드 셀의 VoiceOver 레이블에 사용
    /// Note: ko_KR 고정 - MonoGrid는 한국어 전용 앱
    static let accessibilityDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        // Intentionally hardcoded: MonoGrid is a Korean-only app
        // UI strings, accessibility labels are all in Korean
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 기간 제목용 포맷터 (yyyy년 M월)
    /// GridViewModel.periodTitle에서 사용
    /// Note: ko_KR 고정 - MonoGrid는 한국어 전용 앱
    static let periodTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        // Intentionally hardcoded: MonoGrid is a Korean-only app
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 주간 범위용 포맷터 (M/d)
    /// GridViewModel.weekTitle에서 사용
    static let weekRangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()

    /// 요일 약어 포맷터
    /// GitHubGridView의 weekdayLabels에서 사용
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - Convenience Methods

    /// 오늘의 시작 시간 (캐시 고려)
    static var today: Date {
        calendar.startOfDay(for: Date())
    }

    /// 현재 연도
    static var currentYear: Int {
        calendar.component(.year, from: Date())
    }
}

// MARK: - Thread Safety Note
/*
 ⚠️ 중요: DateFormatter는 thread-safe하지 않습니다.

 DateFormatter.string(from:)은 내부 상태를 변경하므로
 여러 스레드에서 동시에 호출하면 race condition이 발생할 수 있습니다.

 현재 MonoGrid에서의 안전성:
 - SwiftUI View에서 사용: @MainActor 컨텍스트에서 단일 스레드 접근
 - Widget Extension: 별도 프로세스, 동시 접근 없음
 - 백그라운드 작업: Task.detached에서 새 DateFormatter 생성 권장

 만약 멀티스레드 환경에서 사용해야 한다면:
 1. Thread-local storage 사용
 2. 호출마다 새 인스턴스 생성
 3. Actor로 감싸기
 */
