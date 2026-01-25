//
//  NotificationSettingsViewModel.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import SwiftUI
import UserNotifications
import Observation

/// ViewModel for notification settings screen
/// Follows existing @Observable pattern
@MainActor
@Observable
final class NotificationSettingsViewModel {
    // MARK: - Dependencies

    private let notificationManager: NotificationManager
    private let storage: NotificationSettingsStorage
    private var habitRepository: HabitRepository?

    // MARK: - State

    var isEnabled: Bool {
        didSet {
            storage.isEnabled = isEnabled
            Task { await updateSchedule() }
        }
    }

    var scheduledTime: Date {
        didSet {
            storage.scheduledTime = scheduledTime
            if isEnabled {
                Task { await updateSchedule() }
            }
        }
    }

    var permissionStatus: UNAuthorizationStatus {
        notificationManager.permissionStatus
    }

    var previewMessage: NotificationMessage?
    var showPermissionSheet: Bool = false
    var showTimePicker: Bool = false
    var isLoading: Bool = false

    // MARK: - Computed Properties

    var isSystemPermissionGranted: Bool {
        permissionStatus == .authorized
    }

    var shouldShowPermissionWarning: Bool {
        permissionStatus == .denied
    }

    var formattedTime: String {
        scheduledTime.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Initialization

    init(
        notificationManager: NotificationManager = .shared,
        storage: NotificationSettingsStorage = .shared
    ) {
        self.notificationManager = notificationManager
        self.storage = storage
        self.isEnabled = storage.isEnabled
        self.scheduledTime = storage.scheduledTime
    }

    /// Configures the view model with a habit repository for streak data
    func configure(with repository: HabitRepository) {
        self.habitRepository = repository
        Task { await loadPreviewMessage() }
    }

    // MARK: - Actions

    /// Requests notification permission from the user
    /// - Returns: true if permission was granted
    func requestPermission() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let granted = await notificationManager.requestPermission()
        if granted {
            isEnabled = true
        }
        return granted
    }

    /// Opens the iOS system settings for this app
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Refreshes the permission status from the system
    func refreshPermissionStatus() async {
        await notificationManager.refreshPermissionStatus()
    }

    /// Loads preview message with current user stats
    func loadPreviewMessage() async {
        guard let repository = habitRepository else {
            // Use default message if no repository
            previewMessage = NotificationMessage(
                title: "오늘의 습관을 기록해보세요!",
                body: "작은 습관이 큰 변화를 만들어요.",
                badgeCount: 0
            )
            return
        }

        do {
            // Fetch stats from repository
            let stats = try await fetchNotificationStats(from: repository)

            previewMessage = MessageGenerator.generateMessage(
                currentStreak: stats.streak,
                weeklyCompletionRate: stats.weeklyRate,
                incompleteHabitsCount: stats.incompleteCount
            )
        } catch {
            // Use default message on error
            previewMessage = NotificationMessage(
                title: "오늘의 습관을 기록해보세요!",
                body: "작은 습관이 큰 변화를 만들어요.",
                badgeCount: 0
            )
        }
    }

    // MARK: - Private Methods

    private func updateSchedule() async {
        guard isEnabled, isSystemPermissionGranted else {
            notificationManager.cancelAllNotifications()
            return
        }

        await loadPreviewMessage()

        guard let message = previewMessage else { return }

        let hour = Calendar.current.component(.hour, from: scheduledTime)
        let minute = Calendar.current.component(.minute, from: scheduledTime)

        try? await notificationManager.scheduleDailyNotification(
            hour: hour,
            minute: minute,
            message: message
        )
    }

    private func fetchNotificationStats(from repository: HabitRepository) async throws -> (streak: Int, weeklyRate: Double, incompleteCount: Int) {
        let calendar = Calendar.current
        let today = Date()

        // Fetch habits
        let habits = try await repository.fetchHabits()

        guard !habits.isEmpty else {
            return (0, 0.0, 0)
        }

        // Calculate incomplete count for today
        var incompleteCount = 0
        for habit in habits {
            if !habit.isCompleted(on: today) {
                incompleteCount += 1
            }
        }

        // Calculate streak (consecutive days all habits completed)
        var streak = 0
        var checkDate = calendar.date(byAdding: .day, value: -1, to: today)!

        while true {
            var allCompleted = true
            for habit in habits {
                if !habit.isCompleted(on: checkDate) {
                    allCompleted = false
                    break
                }
            }

            if allCompleted {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }

            // Limit check to 365 days
            if streak >= 365 { break }
        }

        // Calculate weekly completion rate
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        var totalExpected = 0
        var totalCompleted = 0

        for dayOffset in 0..<7 {
            guard let checkDay = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            for habit in habits {
                totalExpected += 1
                if habit.isCompleted(on: checkDay) {
                    totalCompleted += 1
                }
            }
        }

        let weeklyRate = totalExpected > 0 ? Double(totalCompleted) / Double(totalExpected) : 0.0

        return (streak, weeklyRate, incompleteCount)
    }
}
