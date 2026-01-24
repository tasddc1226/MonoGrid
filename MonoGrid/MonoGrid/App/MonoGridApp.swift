//
//  MonoGridApp.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI
import SwiftData

/// Main entry point for the MonoGrid app
@main
struct MonoGridApp: App {
    // MARK: - State

    @State private var onboardingViewModel = OnboardingViewModel()
    @State private var themeManager = ThemeManager.shared

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(onboardingViewModel)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
        .modelContainer(PersistenceController.shared.container)
    }
}

/// Root content view that handles onboarding vs main app flow
struct ContentView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if onboardingViewModel.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

/// Main tab view containing the primary app content
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var habitViewModel: HabitViewModel?

    var body: some View {
        Group {
            if let viewModel = habitViewModel {
                HomeView()
                    .environment(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        setupViewModel()
                    }
            }
        }
    }

    private func setupViewModel() {
        let repository = SwiftDataHabitRepository(modelContext: modelContext)
        habitViewModel = HabitViewModel(repository: repository)
    }
}
