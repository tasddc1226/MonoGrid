//
//  PerformanceFlags.swift
//  MonoGrid
//
//  Feature flags for performance optimizations
//  각 최적화를 독립적으로 활성화/비활성화 가능
//  Created on 2026-01-25.
//

import Foundation

/// 성능 최적화 기능 플래그
/// 문제 발생 시 개별 기능을 비활성화하여 롤백 가능
struct PerformanceFlags {
    // MARK: - Iteration 1: Quick Wins

    /// SharedInstances 사용 여부
    /// DateFormatter/Calendar 공유 인스턴스
    /// 효과: ~40% CPU 감소 on scroll
    static var useSharedFormatters: Bool = true

    /// 메모이제이션된 계산 속성 사용 여부
    /// YearlyGridView의 weekColumns, monthLabels 캐싱
    /// 효과: ~60% render time 감소
    static var useMemoizedComputedProperties: Bool = true

    // MARK: - Iteration 2: Core Features

    /// 세션 기반 캐시 사용 여부
    /// 과거 데이터 무기한 캐싱, 오늘 데이터만 갱신
    /// 효과: ~90% cache hit rate
    static var useSessionBasedCache: Bool = true

    /// 배치 쿼리 사용 여부
    /// N+1 쿼리 → 2 쿼리 최적화
    /// 효과: ~80% widget latency 감소
    static var useBatchQueries: Bool = true

    // MARK: - Iteration 3: Polish

    /// 인접 기간 프리페칭 활성화 여부
    /// 네비게이션 후 이전/다음 기간 미리 로드
    /// 효과: 체감 0ms 네비게이션
    static var enablePrefetching: Bool = true

    // MARK: - Debug

    /// 성능 로깅 활성화 (DEBUG 빌드만)
    #if DEBUG
    static var enablePerformanceLogging: Bool = true
    #else
    static var enablePerformanceLogging: Bool = false
    #endif

    // MARK: - Convenience

    /// 모든 최적화 비활성화 (디버깅용)
    static func disableAll() {
        useSharedFormatters = false
        useMemoizedComputedProperties = false
        useSessionBasedCache = false
        useBatchQueries = false
        enablePrefetching = false
    }

    /// 모든 최적화 활성화 (기본값)
    static func enableAll() {
        useSharedFormatters = true
        useMemoizedComputedProperties = true
        useSessionBasedCache = true
        useBatchQueries = true
        enablePrefetching = true
    }

    /// 현재 플래그 상태 출력
    static func printStatus() {
        #if DEBUG
        print("""
        === Performance Flags ===
        • SharedFormatters: \(useSharedFormatters)
        • MemoizedProperties: \(useMemoizedComputedProperties)
        • SessionBasedCache: \(useSessionBasedCache)
        • BatchQueries: \(useBatchQueries)
        • Prefetching: \(enablePrefetching)
        =========================
        """)
        #endif
    }
}

// MARK: - Performance Monitor

/// 성능 측정 유틸리티 (DEBUG 빌드만 활성화)
enum PerformanceMonitor {
    /// 작업 시간 측정
    static func measure<T>(_ label: String, operation: () throws -> T) rethrows -> T {
        #if DEBUG
        guard PerformanceFlags.enablePerformanceLogging else {
            return try operation()
        }

        let start = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        print("⏱️ [\(label)] \(String(format: "%.2f", elapsed))ms")
        return result
        #else
        return try operation()
        #endif
    }

    /// 비동기 작업 시간 측정
    static func measureAsync<T>(_ label: String, operation: () async throws -> T) async rethrows -> T {
        #if DEBUG
        guard PerformanceFlags.enablePerformanceLogging else {
            return try await operation()
        }

        let start = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        print("⏱️ [\(label)] \(String(format: "%.2f", elapsed))ms")
        return result
        #else
        return try await operation()
        #endif
    }

    /// 캐시 히트 로깅
    static func logCacheHit(_ key: String) {
        #if DEBUG
        guard PerformanceFlags.enablePerformanceLogging else { return }
        print("✅ [Cache HIT] \(key)")
        #endif
    }

    /// 캐시 미스 로깅
    static func logCacheMiss(_ key: String) {
        #if DEBUG
        guard PerformanceFlags.enablePerformanceLogging else { return }
        print("❌ [Cache MISS] \(key)")
        #endif
    }
}
