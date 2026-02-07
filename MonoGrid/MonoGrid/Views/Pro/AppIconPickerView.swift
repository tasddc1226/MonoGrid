//
//  AppIconPickerView.swift
//  MonoGrid
//
//  Pro Business Model - App Icon Selection UI
//  Created on 2026-01-27.
//

import SwiftUI
import UIKit

/// 앱 아이콘 선택 화면
struct AppIconPickerView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProViewModel.self) private var proViewModel

    // MARK: - State

    @State private var selectedIconId: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isChangingIcon = false
    @State private var showPaywall = false

    // MARK: - Constants

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 16)
    ]

    // MARK: - Initialization

    init() {
        // Get current icon
        _selectedIconId = State(initialValue: Self.getCurrentIconId())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Free Icons Section
                    iconSection(
                        title: "기본 아이콘",
                        icons: ProIcons.freeIcons
                    )

                    // Pro Icons Section
                    iconSection(
                        title: "Pro 아이콘",
                        icons: ProIcons.proIconOptions,
                        isPro: true
                    )
                }
                .padding()
            }
            .navigationTitle("앱 아이콘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .alert("아이콘 변경 오류", isPresented: $showError) {
                Button("확인") {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showPaywall) {
                NavigationStack {
                    PaywallView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    showPaywall = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Icon Section

    @ViewBuilder
    private func iconSection(title: String, icons: [AppIconOption], isPro: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text(title)
                    .font(.headline)

                if isPro {
                    ProBadge(style: .compact)
                }
            }

            // Icon Grid
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(icons) { icon in
                    iconCell(icon, isLocked: isPro && !proViewModel.hasProAccess)
                }
            }
        }
    }

    // MARK: - Icon Cell

    @ViewBuilder
    private func iconCell(_ icon: AppIconOption, isLocked: Bool) -> some View {
        let isSelected = selectedIconId == icon.id

        Button {
            handleIconTap(icon, isLocked: isLocked)
        } label: {
            VStack(spacing: 8) {
                // Icon Preview
                ZStack {
                    iconPreview(for: icon)

                    // Lock overlay for Pro icons
                    if isLocked {
                        LockedFeatureOverlay(feature: .proAppIcons, style: .standard)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Selection indicator
                    if isSelected && !isLocked {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                    }
                }
                .frame(width: 72, height: 72)

                // Icon Name
                Text(icon.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .lineLimit(1)
            }
        }
        .disabled(isChangingIcon)
        .opacity(isChangingIcon && !isSelected ? 0.5 : 1)
    }

    // MARK: - Icon Preview

    @ViewBuilder
    private func iconPreview(for icon: AppIconOption) -> some View {
        // Try to load the actual icon image
        if let iconName = icon.iconName,
           let uiImage = UIImage(named: iconName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if icon.id == "default",
                  let uiImage = UIImage(named: "AppIcon") {
            // Default icon
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            // Placeholder for icons not yet added
            placeholderIcon(for: icon)
        }
    }

    @ViewBuilder
    private func placeholderIcon(for icon: AppIconOption) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(iconPlaceholderColor(for: icon))
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 28))
                    Text(icon.id.prefix(1).uppercased())
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
            }
    }

    private func iconPlaceholderColor(for icon: AppIconOption) -> Color {
        switch icon.id {
        case "default":
            return .accentColor
        case "dark":
            return .black
        case "gold":
            return Color(red: 0.83, green: 0.68, blue: 0.21)
        case "gradient":
            return Color(red: 0.5, green: 0.2, blue: 0.8)
        case "minimal":
            return .gray
        case "neon":
            return Color(red: 0.0, green: 1.0, blue: 0.6)
        case "retro":
            return Color(red: 0.8, green: 0.4, blue: 0.2)
        default:
            return .secondary
        }
    }

    // MARK: - Actions

    private func handleIconTap(_ icon: AppIconOption, isLocked: Bool) {
        if isLocked {
            // Show paywall for locked icons
            HapticManager.shared.warning()
            showPaywall = true
            return
        }

        // Don't change if already selected
        guard selectedIconId != icon.id else { return }

        changeAppIcon(to: icon)
    }

    private func changeAppIcon(to icon: AppIconOption) {
        isChangingIcon = true

        Task {
            do {
                try await setAlternateIcon(iconName: icon.iconName)
                await MainActor.run {
                    selectedIconId = icon.id
                    isChangingIcon = false
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    isChangingIcon = false
                    errorMessage = "아이콘을 변경할 수 없습니다. 나중에 다시 시도해주세요."
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func setAlternateIcon(iconName: String?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Helpers

    private static func getCurrentIconId() -> String {
        guard let currentIconName = UIApplication.shared.alternateIconName else {
            return "default"
        }

        // Find matching icon by iconName
        if let matchedIcon = ProIcons.allIconOptions.first(where: { $0.iconName == currentIconName }) {
            return matchedIcon.id
        }

        return "default"
    }
}

// MARK: - Preview

#Preview {
    AppIconPickerView()
        .environment(ProViewModel())
}
