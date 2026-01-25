//
//  ReviewRequestViewModel.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import SwiftUI
import UIKit

/// ViewModel for review request dialog UI state and actions
@MainActor
@Observable
final class ReviewRequestViewModel {
    // MARK: - Dependencies

    private let reviewManager: AppReviewManager

    // MARK: - Computed State

    /// Whether the dialog is showing
    var showingDialog: Bool {
        reviewManager.showingPreConfirmation
    }

    /// Whether the transition (thank you) view is showing
    var showingTransition: Bool {
        reviewManager.showingTransition
    }

    /// Current milestone number
    var currentMilestone: Int {
        reviewManager.currentMilestone
    }

    // MARK: - Initialization

    init(reviewManager: AppReviewManager = .shared) {
        self.reviewManager = reviewManager
    }

    // MARK: - Milestone Messages

    /// Emoji for the current milestone
    var milestoneEmoji: String {
        switch currentMilestone {
        case 7: return "🎉"
        case 14: return "🔥"
        case 30: return "🏆"
        default: return "✨"
        }
    }

    /// Title for the current milestone
    var milestoneTitle: String {
        "\(currentMilestone)일 연속 달성!"
    }

    /// Subtitle/congratulation message for the current milestone
    var milestoneSubtitle: String {
        switch currentMilestone {
        case 7:
            return "첫 번째 고비를 넘겼어요!"
        case 14:
            return "2주 동안 꾸준히 해냈어요!\n습관이 자리잡고 있네요 💪"
        case 30:
            return "한 달 동안 완벽했어요!\n당신은 진정한 습관 마스터! 🌟"
        default:
            return "대단한 성취예요!"
        }
    }

    // MARK: - Actions

    /// Handles positive response button tap
    func onPositiveResponse() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        reviewManager.handlePositiveResponse()
    }

    /// Handles negative response button tap
    func onNegativeResponse() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        reviewManager.handleNegativeResponse()
    }

    /// Handles dialog dismiss (same as negative response)
    func onDismiss() {
        onNegativeResponse()
    }
}
