//
//  PersistenceController.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import Foundation
import SwiftData
import CloudKit

/// Singleton controller for managing SwiftData persistence with App Groups and CloudKit
@MainActor
final class PersistenceController {
    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Properties

    /// The main model container
    let container: ModelContainer

    /// The main model context
    var mainContext: ModelContext {
        container.mainContext
    }

    /// CloudKit sync enabled status
    private(set) var isCloudKitEnabled: Bool = false

    /// CloudKit account status
    private(set) var cloudKitAccountStatus: CKAccountStatus = .couldNotDetermine

    /// CloudKit initialization error (for debugging)
    private(set) var cloudKitInitError: Error?

    // MARK: - Initialization

    private init() {
        // Define schema
        let schema = Schema([
            Habit.self,
            HabitLog.self
        ])

        // Log diagnostic info
        Self.logDiagnosticInfo()

        #if DEBUG
        // Use in-memory store for previews/testing if needed
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            let inMemoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                container = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                isCloudKitEnabled = false
                print("✅ [PersistenceController] In-memory container created (UI testing)")
                return
            } catch {
                fatalError("Failed to create in-memory container: \(error)")
            }
        }

        if ProcessInfo.processInfo.arguments.contains("--no-cloudkit") {
            let localConfig = Self.createLocalConfiguration(schema: schema)
            do {
                container = try ModelContainer(for: schema, configurations: [localConfig])
                isCloudKitEnabled = false
                print("✅ [PersistenceController] Local container created (--no-cloudkit)")
                return
            } catch {
                fatalError("Failed to create local container: \(error)")
            }
        }
        #endif

        // Check if CloudKit should be attempted
        guard Constants.isCloudKitSyncEnabled else {
            print("ℹ️ [PersistenceController] CloudKit disabled by Constants")
            let localConfig = Self.createLocalConfiguration(schema: schema)
            do {
                container = try ModelContainer(for: schema, configurations: [localConfig])
                isCloudKitEnabled = false
                print("✅ [PersistenceController] Local container created")
            } catch {
                fatalError("Failed to create local container: \(error)")
            }
            return
        }

        // Try CloudKit with detailed error handling
        do {
            let cloudKitConfig = Self.createCloudKitConfiguration(schema: schema)
            print("🔄 [PersistenceController] Attempting CloudKit container...")
            container = try ModelContainer(for: schema, configurations: [cloudKitConfig])
            isCloudKitEnabled = true
            print("✅ [PersistenceController] CloudKit container created successfully")
        } catch {
            // Detailed error logging
            cloudKitInitError = error
            Self.logDetailedError(error)

            // Fallback to local-only
            print("⚠️ [PersistenceController] Falling back to local-only storage")
            do {
                let localConfig = Self.createLocalConfiguration(schema: schema)
                container = try ModelContainer(for: schema, configurations: [localConfig])
                isCloudKitEnabled = false
                print("✅ [PersistenceController] Local fallback container created")
            } catch let localError {
                Self.logDetailedError(localError)
                fatalError("Failed to create ModelContainer even with local storage: \(localError)")
            }
        }

        // Check CloudKit account status asynchronously
        Task {
            await checkCloudKitAccountStatus()
        }
    }

    // MARK: - Diagnostic Methods

    private static func logDiagnosticInfo() {
        print("📊 [PersistenceController] Diagnostic Info:")
        print("   - CloudKit enabled in Constants: \(Constants.isCloudKitSyncEnabled)")
        print("   - Container ID: \(Constants.cloudKitContainerIdentifier)")
        print("   - App Group: \(Constants.appGroupIdentifier)")

        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) {
            print("   - App Group URL: \(containerURL.path)")
            let storeURL = containerURL.appendingPathComponent("MonoGrid.sqlite")
            let exists = FileManager.default.fileExists(atPath: storeURL.path)
            print("   - SQLite exists: \(exists)")
        } else {
            print("   - ⚠️ App Group URL: NOT AVAILABLE")
        }

        #if targetEnvironment(simulator)
        print("   - Environment: Simulator")
        #else
        print("   - Environment: Device")
        #endif
    }

    private static func logDetailedError(_ error: Error) {
        print("❌ [PersistenceController] Error Details:")
        print("   - Type: \(type(of: error))")
        print("   - Description: \(error.localizedDescription)")

        let nsError = error as NSError
        print("   - Domain: \(nsError.domain)")
        print("   - Code: \(nsError.code)")

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            print("   - Underlying: \(underlying)")
        }

        // Check for specific SwiftData/CloudKit errors
        if nsError.domain == "SwiftDataError" {
            print("   - ⚠️ SwiftData error - possible schema mismatch or CloudKit sync issue")
        }

        if nsError.domain == "CKErrorDomain" {
            print("   - ⚠️ CloudKit error - check iCloud account and container setup")
        }
    }

    // MARK: - Configuration Methods

    /// Create CloudKit-enabled configuration
    private static func createCloudKitConfiguration(schema: Schema) -> ModelConfiguration {
        let cloudKitDB: ModelConfiguration.CloudKitDatabase = .private(Constants.cloudKitContainerIdentifier)

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) else {
            print("⚠️ [PersistenceController] No App Group, using default location with CloudKit")
            return ModelConfiguration(
                schema: schema,
                allowsSave: true,
                cloudKitDatabase: cloudKitDB
            )
        }

        let storeURL = containerURL.appendingPathComponent("MonoGrid.sqlite")
        print("📁 [PersistenceController] Store URL: \(storeURL.path)")

        return ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: cloudKitDB
        )
    }

    /// Create local-only configuration (simulator/testing/fallback)
    private static func createLocalConfiguration(schema: Schema) -> ModelConfiguration {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) else {
            print("⚠️ [PersistenceController] No App Group, using default location (local)")
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

    // MARK: - CloudKit Account Management

    /// Check CloudKit account status
    func checkCloudKitAccountStatus() async {
        guard Constants.isCloudKitSyncEnabled else {
            isCloudKitEnabled = false
            cloudKitAccountStatus = .couldNotDetermine
            return
        }

        do {
            let status = try await CKContainer(
                identifier: Constants.cloudKitContainerIdentifier
            ).accountStatus()

            await MainActor.run {
                self.cloudKitAccountStatus = status
                self.isCloudKitEnabled = (status == .available)
            }
        } catch {
            await MainActor.run {
                self.cloudKitAccountStatus = .couldNotDetermine
                self.isCloudKitEnabled = false
            }
        }
    }

    // MARK: - Preview Support

    /// Creates a preview container with sample data
    @MainActor
    static var preview: PersistenceController = {
        let controller = PersistenceController.previewInstance

        // Add sample data
        let context = controller.mainContext

        let habit1 = Habit(title: "독서", colorHex: "#FF6B6B", iconSymbol: "book.fill", orderIndex: 0)
        let habit2 = Habit(title: "운동", colorHex: "#4D96FF", iconSymbol: "figure.walk", orderIndex: 1)
        let habit3 = Habit(title: "영양제", colorHex: "#6BCB77", iconSymbol: "pills.fill", orderIndex: 2)

        context.insert(habit1)
        context.insert(habit2)
        context.insert(habit3)

        // Add some sample logs
        let today = Calendar.current.startOfDay(for: Date())
        for i in 0..<14 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) {
                if Bool.random() {
                    let log1 = HabitLog(date: date, isCompleted: true, habit: habit1)
                    context.insert(log1)
                }
                if Bool.random() {
                    let log2 = HabitLog(date: date, isCompleted: true, habit: habit2)
                    context.insert(log2)
                }
                if Bool.random() {
                    let log3 = HabitLog(date: date, isCompleted: true, habit: habit3)
                    context.insert(log3)
                }
            }
        }

        return controller
    }()

    /// Creates an in-memory preview instance
    private static var previewInstance: PersistenceController = {
        let schema = Schema([Habit.self, HabitLog.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let controller = PersistenceController(container: container)
            return controller
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    /// Private initializer for preview
    private init(container: ModelContainer) {
        self.container = container
    }
}
