//
//  GridDataCache.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation

/// In-memory LRU cache for grid data with session-based expiration
/// Thread-safe implementation for concurrent access
/// Performance optimized: 과거 데이터는 무기한, 오늘 데이터만 갱신
actor GridDataCache {
    // MARK: - Types

    /// 캐시 전략
    enum CacheStrategy {
        case sessionBased     // 앱 활성 중 무기한
        case timeBased        // 시간 기반 만료
        case hybrid           // 과거 데이터는 무기한, 오늘 데이터만 갱신
    }

    /// Cache entry wrapping the data with metadata
    private struct CacheEntry {
        let data: [Date: Bool]
        let timestamp: Date
        let key: String
        let containsToday: Bool  // 오늘 데이터 포함 여부

        func isExpired(appActive: Bool) -> Bool {
            // 앱 활성 중이고 과거 데이터만 있으면 만료 안 함
            if appActive && !containsToday {
                return false
            }

            // 오늘 데이터는 30초 후 만료
            if containsToday {
                return Date().timeIntervalSince(timestamp) > GridDataCache.todayDataExpiration
            }

            // 과거 데이터는 1시간 후 만료 (앱 비활성 시)
            return Date().timeIntervalSince(timestamp) > GridDataCache.historicalDataExpiration
        }
    }

    /// Cache key components
    struct CacheKey: Hashable, CustomStringConvertible {
        let habitId: UUID
        let rangeType: RangeType
        let year: Int?
        let month: Int?
        let weekStart: Date?

        enum RangeType: String {
            case yearly
            case monthly
            case weekly
            case custom
        }

        var description: String {
            var key = "\(habitId.uuidString)_\(rangeType.rawValue)"
            if let year = year { key += "_\(year)" }
            if let month = month { key += "_\(month)" }
            if let weekStart = weekStart { key += "_\(weekStart.timeIntervalSince1970)" }
            return key
        }

        static func yearly(habitId: UUID, year: Int) -> CacheKey {
            CacheKey(habitId: habitId, rangeType: .yearly, year: year, month: nil, weekStart: nil)
        }

        static func monthly(habitId: UUID, year: Int, month: Int) -> CacheKey {
            CacheKey(habitId: habitId, rangeType: .monthly, year: year, month: month, weekStart: nil)
        }

        static func weekly(habitId: UUID, weekStart: Date) -> CacheKey {
            CacheKey(habitId: habitId, rangeType: .weekly, year: nil, month: nil, weekStart: weekStart)
        }
    }

    // MARK: - Constants

    /// Default expiration time in seconds (5 minutes) - legacy, use specific TTLs below
    static let defaultExpiration: TimeInterval = 5 * 60

    /// 오늘 날짜 데이터 TTL (실시간성 보장)
    static let todayDataExpiration: TimeInterval = 30  // 30초

    /// 과거 데이터 TTL (불변이므로 길게)
    static let historicalDataExpiration: TimeInterval = 3600  // 1시간

    /// 최대 캐시 엔트리 (연간 뷰 지원 강화: 20 → 50)
    static let defaultMaxEntries = 50

    // MARK: - Properties

    /// Cached entries keyed by string representation
    private var cache: [String: CacheEntry] = [:]

    /// LRU order tracking (most recent at the end)
    private var accessOrder: [String] = []

    /// Maximum number of cache entries
    private let maxEntries: Int

    /// Expiration time in seconds
    private let expiration: TimeInterval

    /// 앱 활성화 상태 (세션 기반 캐싱에 사용)
    private var isAppActive: Bool = true

    /// 현재 캐시 전략
    private let strategy: CacheStrategy

    // MARK: - Singleton

    static let shared = GridDataCache(strategy: .hybrid)

    // MARK: - Initialization

    init(
        maxEntries: Int = defaultMaxEntries,
        expiration: TimeInterval = defaultExpiration,
        strategy: CacheStrategy = .hybrid
    ) {
        self.maxEntries = maxEntries
        self.expiration = expiration
        self.strategy = strategy
    }

    // MARK: - Session Lifecycle

    /// 앱 상태 변경 시 호출
    func handleAppStateChange(isActive: Bool) {
        self.isAppActive = isActive
        if !isActive {
            // 백그라운드 진입 시 만료된 캐시 정리
            purgeExpired()
        }
    }

    // MARK: - Public Methods

    /// Retrieves cached data for a key if available and not expired
    /// - Parameter key: The cache key
    /// - Returns: Cached data or nil if not found/expired
    func get(for key: CacheKey) -> [Date: Bool]? {
        let keyString = key.description

        guard let entry = cache[keyString], !entry.isExpired(appActive: isAppActive) else {
            // Remove expired entry if exists
            if cache[keyString] != nil {
                cache.removeValue(forKey: keyString)
                accessOrder.removeAll { $0 == keyString }
            }
            return nil
        }

        // Update LRU order
        updateAccessOrder(for: keyString)

        return entry.data
    }

    /// Stores data in the cache
    /// - Parameters:
    ///   - data: The grid data to cache
    ///   - key: The cache key
    func set(_ data: [Date: Bool], for key: CacheKey) {
        let keyString = key.description

        // 오늘 데이터 포함 여부 확인
        let today = SharedInstances.today
        let containsToday = data.keys.contains { date in
            SharedInstances.calendar.isDate(date, inSameDayAs: today)
        }

        // Create entry with containsToday flag
        let entry = CacheEntry(
            data: data,
            timestamp: Date(),
            key: keyString,
            containsToday: containsToday
        )

        // If key already exists, just update
        if cache[keyString] != nil {
            cache[keyString] = entry
            updateAccessOrder(for: keyString)
            return
        }

        // Evict if at capacity
        while cache.count >= maxEntries {
            evictOldest()
        }

        // Add new entry
        cache[keyString] = entry
        accessOrder.append(keyString)
    }

    /// Invalidates cache entries for a specific habit
    /// Call this when habit data changes
    /// - Parameter habitId: The habit UUID
    func invalidate(habitId: UUID) {
        let prefix = habitId.uuidString
        let keysToRemove = cache.keys.filter { $0.hasPrefix(prefix) }

        for key in keysToRemove {
            cache.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
        }
    }

    /// Invalidates all cache entries
    func invalidateAll() {
        cache.removeAll()
        accessOrder.removeAll()
    }

    /// Removes expired entries from the cache
    func purgeExpired() {
        let expiredKeys = cache.filter { $0.value.isExpired(appActive: isAppActive) }.map { $0.key }

        for key in expiredKeys {
            cache.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
        }
    }

    // MARK: - Prefetch Support

    /// 인접 기간 프리페치
    func prefetchAdjacent(
        for key: CacheKey,
        using fetcher: @escaping () async throws -> [Date: Bool]
    ) {
        Task.detached(priority: .utility) {
            _ = try? await fetcher()
        }
    }

    /// Returns current cache statistics
    func stats() -> (entryCount: Int, hitRate: Double) {
        (cache.count, 0.0)  // Hit rate tracking could be added if needed
    }

    // MARK: - Private Methods

    /// Updates the access order for LRU tracking
    private func updateAccessOrder(for key: String) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }

    /// Evicts the oldest (least recently used) entry
    private func evictOldest() {
        guard let oldestKey = accessOrder.first else { return }
        cache.removeValue(forKey: oldestKey)
        accessOrder.removeFirst()
    }
}

// MARK: - Convenience Extensions

extension GridDataCache {
    /// Gets or fetches yearly data with caching
    func getOrFetch(
        habitId: UUID,
        year: Int,
        fetch: () async throws -> [Date: Bool]
    ) async throws -> [Date: Bool] {
        let key = CacheKey.yearly(habitId: habitId, year: year)

        if let cached = await get(for: key) {
            return cached
        }

        let data = try await fetch()
        await set(data, for: key)
        return data
    }

    /// Gets or fetches monthly data with caching
    func getOrFetch(
        habitId: UUID,
        year: Int,
        month: Int,
        fetch: () async throws -> [Date: Bool]
    ) async throws -> [Date: Bool] {
        let key = CacheKey.monthly(habitId: habitId, year: year, month: month)

        if let cached = await get(for: key) {
            return cached
        }

        let data = try await fetch()
        await set(data, for: key)
        return data
    }

    /// Gets or fetches weekly data with caching
    func getOrFetch(
        habitId: UUID,
        weekOf: Date,
        fetch: () async throws -> [Date: Bool]
    ) async throws -> [Date: Bool] {
        let weekStart = DateRangeCalculator.startOfWeek(for: weekOf)
        let key = CacheKey.weekly(habitId: habitId, weekStart: weekStart)

        if let cached = await get(for: key) {
            return cached
        }

        let data = try await fetch()
        await set(data, for: key)
        return data
    }
}
