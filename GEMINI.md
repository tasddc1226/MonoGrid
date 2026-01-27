# MonoGrid - Gemini Context

## Project Overview

**MonoGrid** is a minimalist, native iOS habit tracker built with **SwiftUI** and **SwiftData**. Its core philosophy is "Invisible Tracking," allowing users to log habits via Home Screen Widgets, Lock Screen Widgets, and Siri Shortcuts without opening the main app. It features a GitHub-style contribution graph visualization.

*   **Platform:** iOS 17.0+
*   **Language:** Swift 5.9+
*   **Key Frameworks:** SwiftUI, SwiftData, CloudKit, WidgetKit, AppIntents.
*   **Localization:** Korean (Primary), English.

## Architecture & Conventions

The project follows a clean **MVVM (Model-View-ViewModel)** architecture with a **Repository Pattern** to abstract data access.

### 1. Directory Structure
*   `MonoGrid/MonoGrid/App`: App entry point (`MonoGridApp.swift`) and `PersistenceController`.
*   `MonoGrid/MonoGrid/Models`: SwiftData models (`Habit`, `HabitLog`).
*   `MonoGrid/MonoGrid/ViewModels`: Business logic (`HabitViewModel`, `OnboardingViewModel`). Use `@Observable` (Observation framework).
*   `MonoGrid/MonoGrid/Views`: SwiftUI views. `HomeView` is the main dashboard.
*   `MonoGrid/MonoGrid/Repository`: Data access layer (`HabitRepository`, `SwiftDataHabitRepository`).
*   `MonoGrid/MonoGridWidget`: WidgetKit extension for Home/Lock screen widgets.
*   `MonoGrid/Intents`: App Intents for Shortcuts and interactive widgets (`ToggleHabitIntent`).

### 2. Data Flow
`View` ⮕ `ViewModel` ⮕ `Repository` ⮕ `SwiftData (Context)` ⮕ `CloudKit (Sync)`

*   **SwiftData:** Used for local persistence and automatic CloudKit syncing (`NSPersistentCloudKitContainer` equivalent behavior via `ModelContainer`).
*   **SyncEngine:** A custom actor (`MonoGrid/Utils/SyncEngine.swift`) monitors sync status and manages a retry queue (`SyncQueue`) for UI feedback, though SwiftData handles the actual sync.
*   **Limits:** Hard limit of **3 habits** per user to maintain focus.

### 3. Key Components
*   **Habit:** Core model. Contains title, color, icon, and relationship to `HabitLog`.
*   **HabitLog:** Records a completion event for a specific date.
*   **ToggleHabitIntent:** The App Intent used by Widgets and Shortcuts to toggle habits without opening the app.

## Build & Run

### Requirements
*   Xcode 15.0+
*   iOS 17.0+ Simulator/Device

### Commands
Standard Xcode build commands apply.

```bash
# Open the project
open MonoGrid.xcodeproj

# Build via xcodebuild (optional CLI usage)
xcodebuild -scheme MonoGrid -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Configuration
*   **Project Generation:** The presence of `project.yml` suggests usage of `XcodeGen`, but `MonoGrid.xcodeproj` is committed.
*   **Entitlements:** iCloud (CloudKit) and App Groups are configured for data sharing between the main app and widgets.

## Development Guidelines

1.  **Strict MVVM:** Views should not access `ModelContext` directly for complex logic; delegate to ViewModels.
2.  **Repository Pattern:** All SwiftData operations (fetch, save, delete) must go through `HabitRepository`.
3.  **Widgets:** Ensure `WidgetCenter.shared.reloadAllTimelines()` is called after data changes in the main app to keep widgets in sync.
4.  **Date Handling:** Always use `Calendar.current.startOfDay(for: date)` when saving logs to ignore time components.
5.  **Localization:** All user-facing strings must be localized (see `Localizable.xcstrings`).
