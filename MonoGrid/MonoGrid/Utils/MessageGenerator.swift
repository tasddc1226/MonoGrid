//
//  MessageGenerator.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import Foundation

/// Utility for generating personalized notification messages
enum MessageGenerator {
    // MARK: - Public API

    /// Generates a personalized notification message based on user's progress
    /// - Parameters:
    ///   - currentStreak: Current consecutive days streak
    ///   - weeklyCompletionRate: This week's completion rate (0.0-1.0)
    ///   - incompleteHabitsCount: Number of incomplete habits for today
    ///   - userName: Optional user name for personalization
    /// - Returns: A NotificationMessage with title, body, and badge count
    static func generateMessage(
        currentStreak: Int,
        weeklyCompletionRate: Double,
        incompleteHabitsCount: Int,
        userName: String? = nil
    ) -> NotificationMessage {
        let title = generateTitle(
            streak: currentStreak,
            weeklyRate: weeklyCompletionRate
        )

        let body = generateBody(
            streak: currentStreak,
            weeklyRate: weeklyCompletionRate,
            userName: userName
        )

        return NotificationMessage(
            title: title,
            body: body,
            badgeCount: incompleteHabitsCount
        )
    }

    // MARK: - Private Helpers

    private static func generateTitle(
        streak: Int,
        weeklyRate: Double
    ) -> String {
        switch (streak, weeklyRate) {
        case (let s, _) where s >= 7:
            return "🔥 \(s)일 연속 달성 중!"
        case (let s, _) where s >= 3:
            return "\(s)일 연속 달성 중이에요!"
        case (_, let r) where r >= 0.8:
            return "이번 주 \(Int(r * 100))% 달성! 대단해요!"
        case (0, _):
            return "다시 시작해볼까요?"
        default:
            return "오늘의 습관을 기록해보세요!"
        }
    }

    private static func generateBody(
        streak: Int,
        weeklyRate: Double,
        userName: String?
    ) -> String {
        let prefix = userName.map { "\($0)님, " } ?? ""

        switch (streak, weeklyRate) {
        case (let s, _) where s >= 3:
            return "\(prefix)오늘도 이어가볼까요?"
        case (0, _):
            return "\(prefix)오늘부터 새로운 연속 기록을 시작해보세요!"
        case (_, let r) where r >= 0.8:
            return "\(prefix)꾸준한 습관이 만들어지고 있어요!"
        default:
            return "\(prefix)작은 습관이 큰 변화를 만들어요."
        }
    }
}
