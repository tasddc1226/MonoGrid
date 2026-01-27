//
//  SettingsView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI
import WidgetKit

/// Settings screen for managing habits and app preferences
struct SettingsView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(HabitViewModel.self) private var viewModel
    @Environment(ProViewModel.self) private var proViewModel
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var selectedHabit: Habit?
    @State private var showResetConfirmation = false
    @State private var showAbout = false
    @State private var showOnboarding = false
    @State private var selectedTheme: ThemeMode = ThemeManager.shared.currentTheme
    @State private var showGridStyleSettings = false

    // Promo Code State
    @State private var promoCode: String = ""
    @State private var showPromoResult = false
    @State private var promoResultMessage: String = ""
    @State private var promoResultIsSuccess = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Pro Section
                proSection

                // Promo Code Section (only for non-Pro users)
                promoCodeSection

                // Habit Management Section
                Section(header: Text("습관 관리")) {
                    if viewModel.habits.isEmpty {
                        Text("등록된 습관이 없습니다")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.habits, id: \.id) { habit in
                            habitRow(habit)
                        }
                        .onMove(perform: moveHabits)
                    }
                }

                // Appearance Section
                Section(header: Text("화면")) {
                    // Theme Selection
                    Picker(selection: $selectedTheme) {
                        ForEach(ThemeMode.allCases) { theme in
                            Label(theme.displayName, systemImage: theme.iconName)
                                .tag(theme)
                        }
                    } label: {
                        Label("테마", systemImage: "paintbrush")
                    }
                    .onChange(of: selectedTheme) { _, newValue in
                        ThemeManager.shared.currentTheme = newValue
                        // Refresh widgets to apply new theme
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }

                // iCloud Sync Section
                iCloudSyncSection

                // Notification Section
                Section(header: Text("알림")) {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label {
                            Text("알림 설정")
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }

                // General Section
                Section(header: Text("일반")) {
                    // Language (follows system)
                    HStack {
                        Label("언어", systemImage: "globe")
                        Spacer()
                        Text("시스템 설정")
                            .foregroundColor(.secondary)
                    }
                }

                // Info Section
                Section(header: Text("정보")) {
                    Button {
                        showOnboarding = true
                    } label: {
                        Label("사용법 안내", systemImage: "play.rectangle")
                    }

                    Button {
                        showAbout = true
                    } label: {
                        Label("앱 정보", systemImage: "info.circle")
                    }

                    // App Store review button
                    SettingsReviewButtonView()

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("모든 데이터 초기화", systemImage: "trash")
                    }
                }

                // Version Footer
                Section {
                    EmptyView()
                } footer: {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            if proViewModel.hasProAccess {
                                HStack(spacing: 4) {
                                    Text("MonoGrid")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    ProBadge(style: .compact)
                                    Text("v1.1")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("MonoGrid v1.1")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(item: $selectedHabit) { habit in
                HabitEditView(habit: habit)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showGridStyleSettings) {
                GridStyleSettingsView()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingContainerView()
            }
            .confirmationDialog(
                "모든 데이터 초기화",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("초기화", role: .destructive) {
                    resetAllData()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text(resetWarningMessage)
            }
            .alert(
                promoResultIsSuccess ? "프로모션 코드 적용 완료" : "오류",
                isPresented: $showPromoResult
            ) {
                Button("확인") {
                    if promoResultIsSuccess {
                        promoCode = ""
                    }
                }
            } message: {
                Text(promoResultMessage)
            }
        }
    }

    // MARK: - Sync Monitor

    private var syncMonitor: SyncStatusMonitor { SyncStatusMonitor.shared }

    // MARK: - Reset Warning Message

    private var resetWarningMessage: String {
        var messages: [String] = [
            "• 모든 습관과 기록이 영구적으로 삭제됩니다."
        ]

        // Add Pro-specific warnings based on subscription state
        switch proViewModel.subscriptionState {
        case .proMonthly, .gracePeriod:
            messages.append("• 구독이 해지됩니다. Polar에서 환불을 요청하실 수 있습니다.")
        case .proLifetime:
            messages.append("• Pro 권한이 해제됩니다.")
        case .free, .expired:
            break
        }

        messages.append("\n이 작업은 되돌릴 수 없습니다.")

        return messages.joined(separator: "\n")
    }

    // MARK: - Pro Section (Only shown for Pro users)

    @ViewBuilder
    private var proSection: some View {
        // Only show Pro section for users who have Pro access
        if proViewModel.hasProAccess {
            Section(header: Text("MonoGrid Pro")) {
                // Pro User Status
                HStack {
                    Image(systemName: proViewModel.subscriptionState.iconName)
                        .font(.title2)
                        .foregroundStyle(ProColors.proBadgeGradient)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Pro")
                                .font(.headline)
                            ProBadge(style: .compact)
                        }
                        Text(proViewModel.subscriptionState.statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Subscription Management (Monthly only)
                if proViewModel.subscriptionState.canManageSubscription {
                    Link(destination: URL(string: "https://polar.sh/settings/subscriptions")!) {
                        Label("구독 관리", systemImage: "creditcard")
                    }
                }

                // Upgrade to Lifetime (Monthly only)
                if proViewModel.subscriptionState.canUpgradeToLifetime {
                    Button {
                        proViewModel.showPaywall = true
                    } label: {
                        HStack {
                            Label("Lifetime으로 업그레이드", systemImage: "crown.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Grid Style Customization (Pro feature)
                Button {
                    showGridStyleSettings = true
                } label: {
                    HStack {
                        Label("그리드 스타일", systemImage: "square.grid.3x3")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Grace Period Banner
                if proViewModel.showGraceBanner {
                    GracePeriodBanner(daysRemaining: proViewModel.gracePeriodDaysRemaining) {
                        if let url = URL(string: "https://polar.sh/settings/payment") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        // Free users: Pro upgrade is shown on HomeView banner
    }

    // MARK: - Promo Code Section (Only for non-Pro users)

    @ViewBuilder
    private var promoCodeSection: some View {
        if !proViewModel.hasProAccess {
            Section(header: Text("프로모션 코드")) {
                HStack(spacing: 12) {
                    TextField("코드 입력", text: $promoCode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Button {
                        applyPromoCode()
                    } label: {
                        Text("적용")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(promoCode.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Promo Code Action

    private func applyPromoCode() {
        let result = PromoCodeManager.shared.redeemCode(
            promoCode,
            licenseManager: LicenseManager.shared
        )

        switch result {
        case .success:
            promoResultIsSuccess = true
            promoResultMessage = "MonoGrid Pro가 활성화되었습니다!\n모든 Pro 기능을 사용할 수 있습니다."
            // Refresh pro status
            Task {
                await proViewModel.refreshProStatus()
            }
            HapticManager.shared.success()

        case .invalid:
            promoResultIsSuccess = false
            promoResultMessage = "유효하지 않은 프로모션 코드입니다."
            HapticManager.shared.error()

        case .alreadyUsed:
            promoResultIsSuccess = false
            promoResultMessage = "이미 사용된 프로모션 코드입니다."
            HapticManager.shared.error()

        case .alreadyPro:
            promoResultIsSuccess = false
            promoResultMessage = "이미 Pro 사용자입니다."
            HapticManager.shared.warning()
        }

        showPromoResult = true
    }

    // MARK: - iCloud Sync Section

    @ViewBuilder
    private var iCloudSyncSection: some View {
        Section(header: Text("iCloud 동기화")) {
            // Sync status row
            HStack {
                SyncStatusView(showText: true)
                Spacer()
            }

            // Last sync time
            if syncMonitor.syncStatus != .unavailable {
                HStack {
                    Label("마지막 동기화", systemImage: "clock")
                    Spacer()
                    Text(syncMonitor.lastSyncDescription)
                        .foregroundColor(.secondary)
                }
            }

            // Manual sync button
            if syncMonitor.syncStatus.canTriggerSync || syncMonitor.syncStatus == .synced {
                Button {
                    syncMonitor.triggerSync()
                    HapticManager.shared.lightImpact()
                } label: {
                    HStack {
                        Label("지금 동기화", systemImage: "arrow.clockwise")
                        Spacer()
                        if syncMonitor.syncStatus == .syncing {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(syncMonitor.syncStatus == .syncing || !syncMonitor.isConnected)
            }

            // Error message
            if syncMonitor.syncStatus == .error, let errorMessage = syncMonitor.lastErrorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // iCloud unavailable warning
            if syncMonitor.syncStatus == .unavailable {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud를 사용할 수 없습니다")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("설정 > Apple ID > iCloud에서 iCloud Drive가 켜져 있는지 확인하세요.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Offline warning
            if syncMonitor.syncStatus == .offline {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.gray)
                    Text("오프라인 상태입니다. 인터넷에 연결되면 자동으로 동기화됩니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func habitRow(_ habit: Habit) -> some View {
        Button {
            selectedHabit = habit
        } label: {
            HStack {
                Image(systemName: habit.iconSymbol)
                    .font(.title3)
                    .foregroundColor(Color(hex: habit.colorHex))
                    .frame(width: 32)

                Text(habit.title)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func moveHabits(from source: IndexSet, to destination: Int) {
        Task {
            await viewModel.reorderHabits(from: source, to: destination)
        }
    }

    private func resetAllData() {
        Task {
            // 1. Delete all habits and their records
            for habit in viewModel.habits {
                try? await viewModel.deleteHabit(habit)
            }

            // 2. Clear Pro license from Keychain
            LicenseManager.shared.clearLicense()

            // 3. Clear promo code usage history
            PromoCodeManager.shared.clearUsedCodes()

            // 4. Refresh Pro status
            await proViewModel.refreshProStatus()

            // 5. Haptic feedback
            HapticManager.shared.warning()
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        // App Icon placeholder
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        VStack(spacing: 4) {
                            Text("MonoGrid")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("버전 1.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .listRowBackground(Color.clear)

                Section(header: Text("소개")) {
                    Text("MonoGrid는 GitHub Contribution Graph 스타일의 미니멀 습관 트래커입니다. 최대 3개의 핵심 습관만 관리하며, 앱 실행 없이도 위젯과 단축어로 기록할 수 있습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("핵심 가치")) {
                    Label("집중 - 3개의 핵심 습관", systemImage: "target")
                    Label("Invisible - 위젯/단축어로 기록", systemImage: "rectangle.stack")
                    Label("시각화 - GitHub 스타일 그리드", systemImage: "square.grid.3x3")
                }
            }
            .navigationTitle("앱 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Onboarding Container View

/// Container for viewing onboarding from settings
struct OnboardingContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var onboardingViewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            OnboardingView()
                .environment(onboardingViewModel)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
        }
        .onChange(of: onboardingViewModel.hasCompletedOnboarding) { _, completed in
            if completed {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(HabitViewModel(repository: PreviewHabitRepository()))
}
