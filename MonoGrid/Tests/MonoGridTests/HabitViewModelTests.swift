//
//  HabitViewModelTests.swift
//  MonoGridTests
//
//  Created on 2026-01-23.
//

import Testing
import Foundation
@testable import MonoGrid

@Suite("HabitViewModel Tests")
struct HabitViewModelTests {

    // MARK: - Setup

    @MainActor
    func createSUT() -> (HabitViewModel, MockHabitRepository) {
        let mockRepository = MockHabitRepository()
        let viewModel = HabitViewModel(repository: mockRepository)
        return (viewModel, mockRepository)
    }

    // MARK: - Create Habit Tests

    @Test("Create habit with valid data succeeds")
    @MainActor
    func test_createHabit_success() async throws {
        let (sut, _) = createSUT()

        let habit = try await sut.createHabit(
            title: "Reading",
            colorHex: "#FF6B6B",
            iconSymbol: "book.fill"
        )

        #expect(habit.title == "Reading")
        #expect(habit.colorHex == "#FF6B6B")
        #expect(habit.iconSymbol == "book.fill")
    }

    @Test("Create habit with empty title fails")
    @MainActor
    func test_createHabit_emptyTitle_fails() async throws {
        let (sut, _) = createSUT()

        await #expect(throws: HabitError.invalidData) {
            try await sut.createHabit(
                title: "   ",
                colorHex: "#FF6B6B",
                iconSymbol: "book.fill"
            )
        }
    }

    @Test("Creating 4th habit fails with limit error")
    @MainActor
    func test_createHabit_maxLimitReached() async throws {
        let (sut, mockRepo) = createSUT()

        // Setup: 3 existing habits
        mockRepo.habits = [
            Habit(title: "H1", orderIndex: 0),
            Habit(title: "H2", orderIndex: 1),
            Habit(title: "H3", orderIndex: 2)
        ]

        await sut.loadHabits()

        await #expect(throws: HabitError.maxLimitReached) {
            try await sut.createHabit(
                title: "H4",
                colorHex: "#000000",
                iconSymbol: "star"
            )
        }
    }

    // MARK: - Toggle Tests

    @Test("Toggle habit creates new log when none exists")
    @MainActor
    func test_toggleTodayLog_noExisting() async throws {
        let (sut, mockRepo) = createSUT()
        let habit = Habit(title: "Test")
        mockRepo.habits = [habit]

        await sut.loadHabits()
        await sut.toggleHabit(habit)

        #expect(mockRepo.toggleLogCalled == true)
    }

    // MARK: - Computed Properties Tests

    @Test("canAddHabit returns true when under limit")
    @MainActor
    func test_canAddHabit_underLimit() async {
        let (sut, mockRepo) = createSUT()
        mockRepo.habits = [Habit(title: "H1"), Habit(title: "H2")]

        await sut.loadHabits()

        #expect(sut.canAddHabit == true)
    }

    @Test("canAddHabit returns false when at limit")
    @MainActor
    func test_canAddHabit_atLimit() async {
        let (sut, mockRepo) = createSUT()
        mockRepo.habits = [
            Habit(title: "H1"),
            Habit(title: "H2"),
            Habit(title: "H3")
        ]

        await sut.loadHabits()

        #expect(sut.canAddHabit == false)
    }

    // MARK: - Delete Tests

    @Test("Delete habit removes it from habits list")
    @MainActor
    func test_deleteHabit() async throws {
        let (sut, mockRepo) = createSUT()
        let habit = Habit(title: "ToDelete")
        mockRepo.habits = [habit]

        await sut.loadHabits()
        #expect(sut.habits.count == 1)

        try await sut.deleteHabit(habit)
        #expect(mockRepo.deleteHabitCalled == true)
    }
}

// MARK: - Mock Repository

@MainActor
class MockHabitRepository: HabitRepository {
    var habits: [Habit] = []
    var logs: [HabitLog] = []

    var saveHabitCalled = false
    var deleteHabitCalled = false
    var toggleLogCalled = false

    func fetchHabits() async throws -> [Habit] {
        return habits.sorted { $0.orderIndex < $1.orderIndex }
    }

    func saveHabit(_ habit: Habit) async throws {
        saveHabitCalled = true
        if habits.count >= 3 && !habits.contains(where: { $0.id == habit.id }) {
            throw HabitError.maxLimitReached
        }
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        } else {
            habits.append(habit)
        }
    }

    func deleteHabit(_ habit: Habit) async throws {
        deleteHabitCalled = true
        habits.removeAll { $0.id == habit.id }
        logs.removeAll { $0.habit?.id == habit.id }
    }

    func updateHabitOrder(_ habits: [Habit]) async throws {
        self.habits = habits
    }

    @discardableResult
    func toggleLog(for habitId: UUID, on date: Date) async throws -> HabitLog {
        toggleLogCalled = true

        guard date.isWithin7Days() else {
            throw HabitError.dateOutOfRange
        }

        let targetDate = Calendar.current.startOfDay(for: date)

        if let existingLog = logs.first(where: { $0.habit?.id == habitId && $0.date == targetDate }) {
            existingLog.toggle()
            return existingLog
        }

        let habit = habits.first { $0.id == habitId }
        let newLog = HabitLog(date: targetDate, isCompleted: true, habit: habit)
        logs.append(newLog)
        return newLog
    }

    func fetchLogs(for habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        return logs.filter { log in
            log.habit?.id == habitId &&
            log.date >= startDate &&
            log.date <= endDate
        }
    }

    func fetchLog(for habitId: UUID, on date: Date) async throws -> HabitLog? {
        let targetDate = Calendar.current.startOfDay(for: date)
        return logs.first { $0.habit?.id == habitId && $0.date == targetDate }
    }

    func fetchAllLogs(for habitId: UUID) async throws -> [HabitLog] {
        return logs.filter { $0.habit?.id == habitId }
    }

    func habitCount() async throws -> Int {
        return habits.count
    }
}
