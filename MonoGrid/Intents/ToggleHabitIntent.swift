//
//  ToggleHabitIntent.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import AppIntents
import SwiftData
import WidgetKit

/// App Intent for toggling a habit's completion status
struct ToggleHabitIntent: AppIntent {
    // MARK: - Metadata

    static var title: LocalizedStringResource = "습관 체크"
    static var description = IntentDescription("선택한 습관의 오늘 완료 상태를 전환합니다")

    // Use this intent with widgets
    static var openAppWhenRun: Bool = false

    // MARK: - Parameters

    @Parameter(title: "습관")
    var habit: HabitEntity?

    /// Used by widget buttons (direct ID passing)
    /// Must be @Parameter to be serialized when intent passes through system
    @Parameter(title: "습관 ID")
    var habitId: String?

    // MARK: - Initialization

    init() {}

    init(habitId: String) {
        self.habitId = habitId
    }

    // MARK: - Perform

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Determine which habit to toggle
        let targetId: String
        if let habitId = habitId {
            targetId = habitId
        } else if let habit = habit {
            targetId = habit.id
        } else {
            throw IntentError.habitNotSpecified
        }

        // Use SharedModelContainer for consistent CloudKit-enabled configuration
        guard let context = await MainActor.run(body: {
            SharedModelContainer.getSharedContext()
        }) else {
            throw IntentError.containerNotFound
        }

        do {

            // Find the habit
            guard let habitUUID = UUID(uuidString: targetId) else {
                throw IntentError.invalidHabitId
            }

            let habitDescriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { $0.id == habitUUID }
            )

            guard let habitModel = try context.fetch(habitDescriptor).first else {
                throw IntentError.habitNotFound
            }

            // Toggle today's log
            let today = Calendar.current.startOfDay(for: Date())

            let logDescriptor = FetchDescriptor<HabitLog>(
                predicate: #Predicate { log in
                    log.habit?.id == habitUUID && log.date == today
                }
            )

            let existingLog = try context.fetch(logDescriptor).first

            let newState: Bool
            let logId: UUID
            let isUpdate: Bool

            if let log = existingLog {
                log.isCompleted.toggle()
                log.updatedAt = Date()
                newState = log.isCompleted
                logId = log.id
                isUpdate = true
            } else {
                let newLog = HabitLog(date: today, isCompleted: true, habit: habitModel)
                context.insert(newLog)
                newState = true
                logId = newLog.id
                isUpdate = false
            }

            try context.save()

            // Enqueue sync change for CloudKit
            let pendingChange = SyncQueue.PendingChange(
                id: UUID(),
                entityType: .habitLog,
                entityId: logId,
                changeType: isUpdate ? .update : .insert,
                timestamp: Date(),
                retryCount: 0
            )
            await SyncQueue.shared.enqueue(pendingChange)

            // Refresh widgets
            WidgetCenter.shared.reloadAllTimelines()

            // Return result
            let message = newState
                ? String(localized: "\(habitModel.title) 완료!")
                : String(localized: "\(habitModel.title) 미완료로 변경")

            return .result(dialog: IntentDialog(stringLiteral: message))

        } catch let error as IntentError {
            throw error
        } catch {
            throw IntentError.toggleFailed
        }
    }
}

// MARK: - Control Center Support (iOS 18+)

@available(iOS 18.0, *)
extension ToggleHabitIntent: ControlConfigurationIntent {
    // Allows this intent to be used in Control Center
}
