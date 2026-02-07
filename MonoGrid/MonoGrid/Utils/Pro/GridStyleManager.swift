//
//  GridStyleManager.swift
//  MonoGrid
//
//  Pro Business Model - Grid Style Settings Manager
//  Created on 2026-01-27.
//

import Foundation
import Observation

/// 그리드 스타일 설정을 관리하는 매니저
@Observable
@MainActor
final class GridStyleManager {
    // MARK: - Singleton

    static let shared = GridStyleManager()

    // MARK: - Storage Keys

    private static let storageKey = "gridStyleSettings"

    /// App Group identifier for sharing with widgets
    private static let appGroupId = "group.com.suyoung.monogrid"

    /// Shared UserDefaults for app and widget access
    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
    }

    // MARK: - State

    /// Current grid style settings
    private(set) var settings: GridStyleSettings {
        didSet {
            save()
        }
    }

    // MARK: - Initialization

    private init() {
        self.settings = Self.load()
    }

    // MARK: - Public Methods

    /// Update corner radius
    func setCornerRadius(_ value: CGFloat) {
        settings = GridStyleSettings(
            cornerRadius: value,
            borderWidth: settings.borderWidth
        )
    }

    /// Update border width
    func setBorderWidth(_ value: CGFloat) {
        settings = GridStyleSettings(
            cornerRadius: settings.cornerRadius,
            borderWidth: value
        )
    }

    /// Reset to default settings
    func reset() {
        settings = .default
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        Self.sharedDefaults.set(data, forKey: Self.storageKey)
        Self.sharedDefaults.synchronize()
    }

    private static func load() -> GridStyleSettings {
        guard let data = sharedDefaults.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(GridStyleSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    // MARK: - Static Accessors (for widgets)

    /// Static method for widgets to read current settings without instantiating manager
    static func currentSettings() -> GridStyleSettings {
        return load()
    }
}
