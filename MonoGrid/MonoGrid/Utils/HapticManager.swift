//
//  HapticManager.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import UIKit

/// Manager for haptic feedback throughout the app
final class HapticManager {
    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Generators

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        // Prepare generators for better response time
        prepareGenerators()
    }

    // MARK: - Preparation

    /// Prepares all haptic generators
    func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Impact Feedback

    /// Light impact feedback
    func lightImpact() {
        impactLight.impactOccurred()
    }

    /// Medium impact feedback (default for habit toggle)
    func mediumImpact() {
        impactMedium.impactOccurred()
    }

    /// Heavy impact feedback
    func heavyImpact() {
        impactHeavy.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Success notification (habit created)
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning notification (habit deleted)
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error notification
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Selection change feedback (scroll to edge, picker change)
    func selectionChanged() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - App-Specific Haptics

    /// Haptic for toggling a habit (medium impact)
    func habitToggle() {
        mediumImpact()
    }

    /// Haptic for creating a new habit (success notification)
    func habitCreated() {
        success()
    }

    /// Haptic for deleting a habit (warning notification)
    func habitDeleted() {
        warning()
    }

    /// Haptic for reaching scroll edge
    func scrollEdge() {
        selectionChanged()
    }
}
