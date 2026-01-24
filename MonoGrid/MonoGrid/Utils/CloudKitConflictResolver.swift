//
//  CloudKitConflictResolver.swift
//  MonoGrid
//
//  Created on 2026-01-24.
//

import Foundation
import SwiftData

/// CloudKit conflict resolution utilities
enum CloudKitConflictResolver {

    // MARK: - Habit Conflict Resolution

    /// Resolve Habit entity conflict using Last-Writer-Wins strategy
    /// - Parameters:
    ///   - local: Local Habit
    ///   - remote: Remote Habit data
    /// - Returns: Resolution result with winner
    static func resolveHabitConflict(
        local: Habit,
        remote: HabitDTO
    ) -> ConflictResolution<Habit> {
        // Compare updatedAt timestamps
        if local.updatedAt > remote.updatedAt {
            // Local is newer → keep local, push to remote
            return .keepLocal(local)
        } else if remote.updatedAt > local.updatedAt {
            // Remote is newer → update local with remote data
            local.title = remote.title
            local.colorHex = remote.colorHex
            local.iconSymbol = remote.iconSymbol
            local.orderIndex = remote.orderIndex
            local.updatedAt = remote.updatedAt
            return .acceptRemote(local)
        } else {
            // Same timestamp (very rare) → prefer local
            return .keepLocal(local)
        }
    }

    // MARK: - HabitLog Conflict Resolution

    /// Resolve HabitLog entity conflict using OR Merge strategy
    /// User intent preservation: if either side marked complete, keep as complete
    /// - Parameters:
    ///   - local: Local HabitLog
    ///   - remote: Remote HabitLog data
    /// - Returns: Resolution result with merged state
    static func resolveHabitLogConflict(
        local: HabitLog,
        remote: HabitLogDTO
    ) -> ConflictResolution<HabitLog> {
        // Case 1: Same completion state → use newer timestamp
        if local.isCompleted == remote.isCompleted {
            if remote.updatedAt > local.updatedAt {
                local.updatedAt = remote.updatedAt
                return .acceptRemote(local)
            }
            return .keepLocal(local)
        }

        // Case 2: OR Merge - if either is true, result is true
        // Preserves user's completion intent
        if local.isCompleted || remote.isCompleted {
            local.isCompleted = true
            local.updatedAt = max(local.updatedAt, remote.updatedAt)
            return .merged(local)
        }

        // Case 3: Both false (handled above, but for safety)
        return .keepLocal(local)
    }

    // MARK: - Batch Conflict Resolution

    /// Resolve multiple Habit conflicts
    static func resolveHabitConflicts(
        locals: [Habit],
        remotes: [HabitDTO]
    ) -> [ConflictResolution<Habit>] {
        let remoteMap = Dictionary(uniqueKeysWithValues: remotes.map { ($0.id, $0) })

        return locals.compactMap { local in
            guard let remote = remoteMap[local.id] else {
                // No conflict - local only
                return nil
            }
            return resolveHabitConflict(local: local, remote: remote)
        }
    }

    /// Resolve multiple HabitLog conflicts
    static func resolveHabitLogConflicts(
        locals: [HabitLog],
        remotes: [HabitLogDTO]
    ) -> [ConflictResolution<HabitLog>] {
        let remoteMap = Dictionary(uniqueKeysWithValues: remotes.map { ($0.id, $0) })

        return locals.compactMap { local in
            guard let remote = remoteMap[local.id] else {
                // No conflict - local only
                return nil
            }
            return resolveHabitLogConflict(local: local, remote: remote)
        }
    }
}

// MARK: - Conflict Resolution Result

/// Result of conflict resolution
enum ConflictResolution<T> {
    /// Keep local data, push to remote
    case keepLocal(T)

    /// Accept remote data, update local
    case acceptRemote(T)

    /// Merged both (e.g., OR merge for completion state)
    case merged(T)

    /// Winner description for logging
    var winner: String {
        switch self {
        case .keepLocal:
            return "local"
        case .acceptRemote:
            return "remote"
        case .merged:
            return "merged"
        }
    }

    /// Get resolved value
    var value: T {
        switch self {
        case .keepLocal(let value),
             .acceptRemote(let value),
             .merged(let value):
            return value
        }
    }
}

// MARK: - Data Transfer Objects

/// DTO for remote Habit data
struct HabitDTO {
    let id: UUID
    let title: String
    let colorHex: String
    let iconSymbol: String
    let orderIndex: Int
    let createdAt: Date
    let updatedAt: Date

    /// Create from CKRecord fields (future use)
    init(
        id: UUID,
        title: String,
        colorHex: String,
        iconSymbol: String,
        orderIndex: Int,
        createdAt: Date = Date(),
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.iconSymbol = iconSymbol
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// DTO for remote HabitLog data
struct HabitLogDTO {
    let id: UUID
    let date: Date
    let isCompleted: Bool
    let updatedAt: Date
    let habitId: UUID

    /// Create from CKRecord fields (future use)
    init(
        id: UUID,
        date: Date,
        isCompleted: Bool,
        updatedAt: Date,
        habitId: UUID
    ) {
        self.id = id
        self.date = date
        self.isCompleted = isCompleted
        self.updatedAt = updatedAt
        self.habitId = habitId
    }
}

// MARK: - Conflict Statistics

/// Conflict resolution statistics for monitoring
struct ConflictStatistics {
    var totalConflicts: Int = 0
    var localWins: Int = 0
    var remoteWins: Int = 0
    var merges: Int = 0

    mutating func record<T>(_ resolution: ConflictResolution<T>) {
        totalConflicts += 1
        switch resolution {
        case .keepLocal:
            localWins += 1
        case .acceptRemote:
            remoteWins += 1
        case .merged:
            merges += 1
        }
    }

    var summary: String {
        "Conflicts: \(totalConflicts) (local: \(localWins), remote: \(remoteWins), merged: \(merges))"
    }
}
