//
//  GridStyleSettings.swift
//  MonoGrid
//
//  Pro Business Model - Grid Style Customization Settings
//  Created on 2026-01-27.
//

import Foundation

/// Pro 사용자를 위한 그리드 스타일 설정
struct GridStyleSettings: Codable, Equatable {
    // MARK: - Properties

    /// Grid cell corner radius (0-20)
    var cornerRadius: CGFloat

    /// Grid cell border width (0-5)
    var borderWidth: CGFloat

    // MARK: - Range Constants

    static let cornerRadiusRange: ClosedRange<CGFloat> = 0...20
    static let borderWidthRange: ClosedRange<CGFloat> = 0...5

    // MARK: - Default Values

    static let `default` = GridStyleSettings(
        cornerRadius: 2,
        borderWidth: 0
    )

    // MARK: - Initialization

    init(cornerRadius: CGFloat = 2, borderWidth: CGFloat = 0) {
        self.cornerRadius = cornerRadius.clamped(to: Self.cornerRadiusRange)
        self.borderWidth = borderWidth.clamped(to: Self.borderWidthRange)
    }

    // MARK: - Computed Properties

    /// Whether the settings differ from default
    var isCustomized: Bool {
        self != Self.default
    }

    /// Description for accessibility
    var accessibilityDescription: String {
        "모서리 반경 \(Int(cornerRadius)), 테두리 두께 \(Int(borderWidth))"
    }
}

// MARK: - CGFloat Clamping Extension

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
