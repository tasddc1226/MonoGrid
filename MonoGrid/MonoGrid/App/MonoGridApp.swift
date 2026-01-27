//
//  MonoGridApp.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI
import SwiftData
import UserNotifications
import Combine

/// Main entry point for the MonoGrid app
@main
struct MonoGridApp: App {
    // MARK: - State

    @State private var onboardingViewModel = OnboardingViewModel()
    @State private var themeManager = ThemeManager.shared
    @State private var navigationState = AppNavigationState()
    @State private var reviewViewModel = ReviewRequestViewModel()
    @State private var proViewModel = ProViewModel()
    @StateObject private var reviewManager = AppReviewManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(onboardingViewModel)
                    .environment(navigationState)
                    .environment(reviewViewModel)
                    .environment(proViewModel)
                    .preferredColorScheme(themeManager.currentTheme.colorScheme)
                    .task {
                        // Verify Pro license on launch
                        await proViewModel.verifyLicenseOnLaunch()
                    }
                    .onReceive(appDelegate.notificationResponsePublisher) { response in
                        navigationState.handleNotificationResponse(response)
                    }
                    .task {
                        // Clear badge on app launch
                        await NotificationManager.shared.clearBadge()
                    }

                // Review request dialog overlay
                if reviewManager.showingPreConfirmation || reviewManager.showingTransition {
                    ReviewRequestDialogView(viewModel: reviewViewModel)
                        .zIndex(100)
                }
            }
        }
        .modelContainer(PersistenceController.shared.container)
    }
}

// MARK: - App Delegate

/// App delegate for handling notification delegate setup
final class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationResponsePublisher = PassthroughSubject<UNNotificationResponse, Never>()
    private var notificationDelegate: NotificationDelegate?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize RevenueCat
        RevenueCatManager.shared.configure()

        // Set up notification delegate
        notificationDelegate = NotificationDelegate(publisher: notificationResponsePublisher)
        UNUserNotificationCenter.current().delegate = notificationDelegate
        return true
    }
}

// MARK: - Notification Delegate

/// Handles notification presentation and response
/// Uses completion handler pattern for reliable main thread execution
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let responsePublisher: PassthroughSubject<UNNotificationResponse, Never>

    init(publisher: PassthroughSubject<UNNotificationResponse, Never>) {
        self.responsePublisher = publisher
        super.init()
    }

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    /// Handle notification tap - uses completion handler for main thread safety
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Ensure UI update happens on main thread
        DispatchQueue.main.async { [weak self] in
            self?.responsePublisher.send(response)
            completionHandler()
        }
    }
}

// MARK: - Root Content View

/// Root content view that handles onboarding vs main app flow
struct ContentView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(AppNavigationState.self) private var navigationState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if onboardingViewModel.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onChange(of: navigationState.pendingDeepLink) { _, deepLink in
            handleDeepLink(deepLink)
        }
    }

    private func handleDeepLink(_ deepLink: AppNavigationState.DeepLink?) {
        guard let deepLink = deepLink else { return }

        // Handle deep link navigation
        switch deepLink {
        case .today:
            // Navigate to today's habits view (default home view)
            break
        case .settings, .notificationSettings:
            // These are handled at a lower level in the navigation stack
            break
        }

        // Clear the deep link after handling
        navigationState.clearDeepLink()
    }
}

// MARK: - Main Tab View

/// Main tab view containing the primary app content
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigationState.self) private var navigationState
    @Environment(ProViewModel.self) private var proViewModel
    @State private var habitViewModel: HabitViewModel?

    var body: some View {
        Group {
            if let viewModel = habitViewModel {
                HomeView()
                    .environment(viewModel)
                    // PaywallView is now presented via fullScreenCover in HomeView
                    .sheet(isPresented: Binding(
                        get: { viewModel.showNotificationPermission },
                        set: { viewModel.showNotificationPermission = $0 }
                    )) {
                        NotificationPermissionSheet(
                            onAllow: {
                                await NotificationManager.shared.requestPermission()
                            },
                            onLater: {
                                // Just dismiss, user can enable later in settings
                            }
                        )
                        .presentationDetents([.medium])
                    }
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
