//
//  PaywallViewModel.swift
//  MonoGrid
//
//  Pro Business Model - Paywall Presentation State
//  Created on 2026-01-25.
//

import Foundation
import Observation
import SwiftUI

/// Paywall 화면 상태 관리
@Observable
@MainActor
final class PaywallViewModel {
    // MARK: - State

    var selectedProduct: ProProduct = .lifetime
    var isAnimating: Bool = false

    // Feature list animation
    var visibleFeatures: [ProFeature] = []
    var allFeatures: [ProFeature] = ProFeature.allCases

    // MARK: - Computed Properties

    var products: [ProProduct] {
        ProProduct.allCases
    }

    var lifetimeProduct: ProProduct { .lifetime }
    var monthlyProduct: ProProduct { .monthly }

    // MARK: - Methods

    func selectProduct(_ product: ProProduct) {
        guard selectedProduct != product else { return }
        selectedProduct = product
        HapticManager.shared.selectionChanged()
    }

    func startFeatureAnimation() {
        // Prevent duplicate animations
        guard !isAnimating else { return }

        visibleFeatures = []
        isAnimating = true

        // Staggered animation for feature list
        for (index, feature) in allFeatures.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) { [weak self] in
                guard let self = self, self.isAnimating else { return }
                // Prevent duplicates
                guard !self.visibleFeatures.contains(feature) else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.visibleFeatures.append(feature)
                }
            }
        }

        // Animation complete
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(allFeatures.count) * 0.1) { [weak self] in
            self?.isAnimating = false
        }
    }

    func reset() {
        selectedProduct = .lifetime
        visibleFeatures = []
        isAnimating = false
    }
}
