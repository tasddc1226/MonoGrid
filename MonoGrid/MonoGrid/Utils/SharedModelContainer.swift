//
//  SharedModelContainer.swift
//  MonoGrid
//
//  Created on 2026-01-24.
//

import Foundation
import SwiftData

/// Factory for shared ModelContainer across App, Widget, and Intent
/// Prevents duplicate container creation and ensures consistent configuration
@MainActor
final class SharedModelContainer {

    // MARK: - Singleton

    static let shared = SharedModelContainer()

    // MARK: - Properties

    /// Cached container instance
    private var cachedContainer: ModelContainer?

    /// Schema definition
    private let schema = Schema([Habit.self, HabitLog.self])

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Get shared ModelContainer
    /// Returns cached instance if already created
    func getContainer() throws -> ModelContainer {
        if let cached = cachedContainer {
            return cached
        }

        let container = try createContainer()
        cachedContainer = container
        return container
    }

    /// Create new ModelContext (for read-only operations)
    func createContext() throws -> ModelContext {
        let container = try getContainer()
        return ModelContext(container)
    }

    /// Invalidate cache (for testing)
    func invalidateCache() {
        cachedContainer = nil
    }

    // MARK: - Private Methods

    private func createContainer() throws -> ModelContainer {
        // Check if CloudKit should be attempted
        guard Constants.isCloudKitSyncEnabled else {
            print("ℹ️ [SharedModelContainer] CloudKit disabled, using local storage")
            let localConfig = createLocalConfiguration()
            return try ModelContainer(for: schema, configurations: [localConfig])
        }

        // First try with CloudKit
        do {
            let cloudKitConfig = createCloudKitConfiguration()
            print("🔄 [SharedModelContainer] Attempting CloudKit container...")
            let container = try ModelContainer(for: schema, configurations: [cloudKitConfig])
            print("✅ [SharedModelContainer] CloudKit container created")
            return container
        } catch {
            // CloudKit failed - log detailed error
            logDetailedError(error)
            print("⚠️ [SharedModelContainer] Falling back to local-only storage")

            let localConfig = createLocalConfiguration()
            let container = try ModelContainer(for: schema, configurations: [localConfig])
            print("✅ [SharedModelContainer] Local fallback container created")
            return container
        }
    }

    private func createCloudKitConfiguration() -> ModelConfiguration {
        let cloudKitDB: ModelConfiguration.CloudKitDatabase = .private(Constants.cloudKitContainerIdentifier)

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) else {
            print("⚠️ [SharedModelContainer] No App Group, using default location")
            return ModelConfiguration(
                schema: schema,
                allowsSave: true,
                cloudKitDatabase: cloudKitDB
            )
        }

        let storeURL = containerURL.appendingPathComponent("MonoGrid.sqlite")
        return ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: cloudKitDB
        )
    }

    private func createLocalConfiguration() -> ModelConfiguration {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) else {
            return ModelConfiguration(
                schema: schema,
                allowsSave: true,
                cloudKitDatabase: .none
            )
        }

        let storeURL = containerURL.appendingPathComponent("MonoGrid.sqlite")
        return ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
    }

    private func logDetailedError(_ error: Error) {
        print("❌ [SharedModelContainer] Error Details:")
        print("   - Type: \(type(of: error))")
        print("   - Description: \(error.localizedDescription)")

        let nsError = error as NSError
        print("   - Domain: \(nsError.domain)")
        print("   - Code: \(nsError.code)")

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            print("   - Underlying: \(underlying)")
        }
    }
}

// MARK: - Extension Target Convenience Accessors

extension SharedModelContainer {

    /// Widget/Intent convenience accessor (synchronous)
    /// Extensions may have limited async support
    static func getSharedContainer() -> ModelContainer? {
        try? shared.getContainer()
    }

    /// Widget/Intent convenience context creator
    static func getSharedContext() -> ModelContext? {
        guard let container = getSharedContainer() else { return nil }
        return ModelContext(container)
    }

    /// Background context for widget timeline provider
    /// Creates a new ModelContext that can be used outside MainActor
    /// Note: ModelContext is not Sendable, but we create a new one for each background operation
    static func getBackgroundContext() -> ModelContext? {
        guard let container = getSharedContainer() else { return nil }
        return ModelContext(container)
    }
}
