//
//  DateExtensionTests.swift
//  MonoGridTests
//
//  Created on 2026-01-23.
//

import Testing
import Foundation
@testable import MonoGrid

@Suite("Date Extension Tests")
struct DateExtensionTests {

    // MARK: - startOfDay Tests

    @Test("startOfDay normalizes time to midnight")
    func test_startOfDay_normalizes() {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 23
        components.hour = 14
        components.minute = 30
        components.second = 45

        guard let date = Calendar.current.date(from: components) else {
            Issue.record("Failed to create test date")
            return
        }

        let startOfDay = date.startOfDay

        let resultComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)
        #expect(resultComponents.hour == 0)
        #expect(resultComponents.minute == 0)
        #expect(resultComponents.second == 0)
    }

    // MARK: - isToday Tests

    @Test("isToday returns true for today")
    func test_isToday_positive() {
        let today = Date()
        #expect(today.isToday == true)
    }

    @Test("isToday returns false for yesterday")
    func test_isToday_negative() {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            Issue.record("Failed to create yesterday date")
            return
        }
        #expect(yesterday.isToday == false)
    }

    // MARK: - isWithin7Days Tests

    @Test("isWithin7Days returns true for today")
    func test_isWithin7Days_today() {
        let today = Date()
        #expect(today.isWithin7Days() == true)
    }

    @Test("isWithin7Days returns true for day 7")
    func test_isWithin7Days_boundary() {
        guard let day7 = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            Issue.record("Failed to create day 7 date")
            return
        }
        #expect(day7.isWithin7Days() == true)
    }

    @Test("isWithin7Days returns false for day 8")
    func test_isWithin7Days_outsideBoundary() {
        guard let day8 = Calendar.current.date(byAdding: .day, value: -8, to: Date()) else {
            Issue.record("Failed to create day 8 date")
            return
        }
        #expect(day8.isWithin7Days() == false)
    }

    // MARK: - dayOfWeekMondayFirst Tests

    @Test("dayOfWeekMondayFirst returns 0 for Monday")
    func test_dayOfWeekMondayFirst_monday() {
        // Create a known Monday: January 20, 2026
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 20

        guard let monday = Calendar.current.date(from: components) else {
            Issue.record("Failed to create Monday date")
            return
        }

        #expect(monday.dayOfWeekMondayFirst == 0)
    }

    @Test("dayOfWeekMondayFirst returns 6 for Sunday")
    func test_dayOfWeekMondayFirst_sunday() {
        // Create a known Sunday: January 26, 2026
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 26

        guard let sunday = Calendar.current.date(from: components) else {
            Issue.record("Failed to create Sunday date")
            return
        }

        #expect(sunday.dayOfWeekMondayFirst == 6)
    }

    // MARK: - Date Generation Tests

    @Test("past days generates correct count")
    func test_pastDays_count() {
        let dates = Date.past(days: 14)
        #expect(dates.count == 14)
    }

    @Test("past year generates 365 dates")
    func test_pastYear_count() {
        let dates = Date.pastYear()
        #expect(dates.count == 365)
    }

    @Test("past days are in correct order (newest first)")
    func test_pastDays_order() {
        let dates = Date.past(days: 3)

        #expect(dates.count == 3)

        // First date should be today
        #expect(dates[0].isToday == true)

        // Dates should be in descending order (newest first)
        for i in 0..<(dates.count - 1) {
            #expect(dates[i] > dates[i + 1])
        }
    }

    // MARK: - Formatting Tests

    @Test("shortFormatted returns non-empty string")
    func test_shortFormatted() {
        let date = Date()
        let formatted = date.shortFormatted

        #expect(formatted.isEmpty == false)
    }

    @Test("longFormatted returns non-empty string")
    func test_longFormatted() {
        let date = Date()
        let formatted = date.longFormatted

        #expect(formatted.isEmpty == false)
    }

    // MARK: - Adding Days Tests

    @Test("adding days works correctly")
    func test_addingDays() {
        let today = Date().startOfDay

        let tomorrow = today.adding(days: 1).startOfDay
        let expectedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!.startOfDay

        #expect(tomorrow == expectedTomorrow)
    }
}
