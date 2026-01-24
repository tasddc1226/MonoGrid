//
//  SyncStatusView.swift
//  MonoGrid
//
//  Created on 2026-01-24.
//

import SwiftUI

/// Compact view displaying current sync status
struct SyncStatusView: View {
    // MARK: - Properties

    /// Show text label alongside icon
    var showText: Bool = true

    /// Sync status monitor
    private var syncMonitor: SyncStatusMonitor { SyncStatusMonitor.shared }

    // MARK: - Body

    var body: some View {
        Button {
            handleTap()
        } label: {
            HStack(spacing: 6) {
                statusIcon

                if showText {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(syncMonitor.syncStatus.description)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if syncMonitor.syncStatus == .synced,
                           let lastSync = syncMonitor.lastSyncDate {
                            Text(lastSyncText(lastSync))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if syncMonitor.syncStatus == .error,
                           let errorMessage = syncMonitor.lastErrorMessage {
                            Text(errorMessage)
                                .font(.caption2)
                                .foregroundColor(.red)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .foregroundColor(syncMonitor.syncStatus.color)
        }
        .buttonStyle(.plain)
        .disabled(!canInteract)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var statusIcon: some View {
        Image(systemName: syncMonitor.syncStatus.iconName)
            .font(.title3)
            .foregroundColor(syncMonitor.syncStatus.color)
            .modifier(SyncingAnimationModifier(isSyncing: syncMonitor.syncStatus == .syncing))
    }

    // MARK: - Helpers

    private var canInteract: Bool {
        syncMonitor.syncStatus.canTriggerSync
    }

    private func handleTap() {
        guard canInteract else { return }

        HapticManager.shared.lightImpact()
        syncMonitor.triggerSync()
    }

    private func lastSyncText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var accessibilityLabel: String {
        var label = syncMonitor.syncStatus.description
        if syncMonitor.syncStatus == .synced, let lastSync = syncMonitor.lastSyncDate {
            label += ", " + lastSyncText(lastSync)
        }
        return label
    }

    private var accessibilityHint: String {
        if canInteract {
            return String(localized: "탭하여 동기화 재시도")
        }
        return ""
    }
}

// MARK: - Syncing Animation Modifier

private struct SyncingAnimationModifier: ViewModifier {
    let isSyncing: Bool

    func body(content: Content) -> some View {
        if isSyncing {
            content
                .symbolEffect(.pulse, options: .repeating, isActive: true)
        } else {
            content
        }
    }
}

// MARK: - Compact Sync Status View (Icon Only)

/// Minimal sync status indicator for navigation bar
struct CompactSyncStatusView: View {
    private var syncMonitor: SyncStatusMonitor { SyncStatusMonitor.shared }

    var body: some View {
        SyncStatusView(showText: false)
    }
}

// MARK: - Preview

#Preview("Full") {
    VStack(spacing: 20) {
        SyncStatusView(showText: true)
        SyncStatusView(showText: false)
    }
    .padding()
}

#Preview("Compact") {
    NavigationStack {
        Text("Content")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CompactSyncStatusView()
                }
            }
    }
}
