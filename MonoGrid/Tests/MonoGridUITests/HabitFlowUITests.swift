//
//  HabitFlowUITests.swift
//  MonoGridUITests
//
//  Created on 2026-01-23.
//

import XCTest

final class HabitFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Onboarding Tests

    func test_onboarding_skipButton() throws {
        // Skip onboarding if shown
        let skipButton = app.buttons["건너뛰기"]
        if skipButton.waitForExistence(timeout: 2) {
            skipButton.tap()
        }

        // Verify we're on the home screen
        let homeTitle = app.navigationBars.element
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 2))
    }

    // MARK: - Habit Creation Tests

    func test_createFirstHabit() throws {
        skipOnboardingIfNeeded()

        // Tap add habit button
        let addButton = app.buttons["습관 추가"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        addButton.tap()

        // Enter habit name
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("독서")

        // Select an icon (first available)
        let iconButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'book'")).firstMatch
        if iconButton.exists {
            iconButton.tap()
        }

        // Save
        let saveButton = app.buttons["저장"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()

        // Verify habit appears on home screen
        let habitText = app.staticTexts["독서"]
        XCTAssertTrue(habitText.waitForExistence(timeout: 2))
    }

    // MARK: - Habit Toggle Tests

    func test_toggleHabitCheckbox() throws {
        skipOnboardingIfNeeded()
        createSampleHabitIfNeeded()

        // Find and tap checkbox
        let checkbox = app.buttons.matching(NSPredicate(format: "label CONTAINS '완료' OR label CONTAINS '미완료'")).firstMatch

        if checkbox.waitForExistence(timeout: 2) {
            let initialLabel = checkbox.label
            checkbox.tap()

            // Wait for UI update
            sleep(1)

            // Verify state changed
            let newLabel = checkbox.label
            XCTAssertNotEqual(initialLabel, newLabel)
        }
    }

    // MARK: - Settings Tests

    func test_navigateToSettings() throws {
        skipOnboardingIfNeeded()

        // Tap settings button
        let settingsButton = app.buttons["설정"]
        if settingsButton.waitForExistence(timeout: 2) {
            settingsButton.tap()

            // Verify settings view appears
            let settingsTitle = app.navigationBars["설정"]
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Helper Methods

    private func skipOnboardingIfNeeded() {
        let skipButton = app.buttons["건너뛰기"]
        if skipButton.waitForExistence(timeout: 1) {
            skipButton.tap()
        }
    }

    private func createSampleHabitIfNeeded() {
        // Check if there's already a habit
        if app.staticTexts["첫 번째 습관을 추가하세요"].exists {
            // Create a habit
            let addButton = app.buttons["습관 추가"]
            if addButton.waitForExistence(timeout: 2) {
                addButton.tap()

                let nameField = app.textFields.firstMatch
                if nameField.waitForExistence(timeout: 2) {
                    nameField.tap()
                    nameField.typeText("테스트")
                }

                let saveButton = app.buttons["저장"]
                if saveButton.exists {
                    saveButton.tap()
                }

                sleep(1) // Wait for save
            }
        }
    }
}
