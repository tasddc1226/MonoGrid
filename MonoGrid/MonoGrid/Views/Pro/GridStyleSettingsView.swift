//
//  GridStyleSettingsView.swift
//  MonoGrid
//
//  Pro Business Model - Grid Style Customization UI
//  Created on 2026-01-27.
//

import SwiftUI
import WidgetKit

/// 그리드 스타일 커스터마이징 설정 화면
struct GridStyleSettingsView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var cornerRadius: CGFloat
    @State private var borderWidth: CGFloat

    // MARK: - Constants

    private let gridStyleManager = GridStyleManager.shared

    // MARK: - Sample Data for Preview

    private let sampleCompletionData: [Date: Bool] = {
        var data: [Date: Bool] = [:]
        let dates = Date.past(days: 14)
        for (index, date) in dates.enumerated() {
            // Create a nice pattern for preview
            data[Calendar.current.startOfDay(for: date)] = index % 3 != 0
        }
        return data
    }()

    // MARK: - Initialization

    init() {
        let settings = GridStyleManager.shared.settings
        _cornerRadius = State(initialValue: settings.cornerRadius)
        _borderWidth = State(initialValue: settings.borderWidth)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Preview Section
                previewSection

                // Corner Radius Section
                cornerRadiusSection

                // Border Width Section
                borderWidthSection

                // Reset Section
                resetSection
            }
            .navigationTitle("그리드 스타일")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        saveAndDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        Section {
            VStack(spacing: 16) {
                Text("미리보기")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Preview Card
                previewCard
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.habitCoral)

                Text("독서")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Preview checkbox
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.habitCoral)
            }

            Spacer()

            // Preview Mini Grid with custom styles
            previewMiniGrid
        }
        .padding(16)
        .frame(height: 120)
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(Constants.UI.cardCornerRadius)
        .shadow(
            color: AppColors.cardShadow(for: colorScheme),
            radius: Constants.UI.cardShadowRadius,
            x: 0,
            y: 2
        )
    }

    @ViewBuilder
    private var previewMiniGrid: some View {
        let dates = Date.past(days: 14).reversed()
        let cellSize: CGFloat = 6
        let cellGap: CGFloat = 2

        HStack(spacing: cellGap) {
            ForEach(Array(dates), id: \.self) { date in
                let isCompleted = sampleCompletionData[Calendar.current.startOfDay(for: date)] ?? false
                let cellColor: Color = isCompleted ? .habitCoral : AppColors.gridIncomplete(for: colorScheme)

                RoundedRectangle(cornerRadius: min(cornerRadius, cellSize / 2))
                    .fill(cellColor)
                    .frame(width: cellSize, height: cellSize)
                    .overlay {
                        if borderWidth > 0 {
                            RoundedRectangle(cornerRadius: min(cornerRadius, cellSize / 2))
                                .strokeBorder(
                                    Color.primary.opacity(0.3),
                                    lineWidth: min(borderWidth, 1)
                                )
                        }
                    }
            }
        }
    }

    // MARK: - Corner Radius Section

    @ViewBuilder
    private var cornerRadiusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("둥글기")
                    Spacer()
                    Text("\(Int(cornerRadius))")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: $cornerRadius,
                    in: GridStyleSettings.cornerRadiusRange,
                    step: 1
                ) {
                    Text("모서리 반경")
                } minimumValueLabel: {
                    Image(systemName: "square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onChange(of: cornerRadius) { _, newValue in
                    gridStyleManager.setCornerRadius(newValue)
                    HapticManager.shared.selectionChanged()
                    refreshWidgets()
                }
            }
        } header: {
            Text("모서리 반경")
        } footer: {
            Text("0은 각진 모서리, 20은 완전히 둥근 모서리입니다.")
        }
    }

    // MARK: - Border Width Section

    @ViewBuilder
    private var borderWidthSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("두께")
                    Spacer()
                    Text("\(Int(borderWidth))")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: $borderWidth,
                    in: GridStyleSettings.borderWidthRange,
                    step: 1
                ) {
                    Text("테두리 두께")
                } minimumValueLabel: {
                    Text("없음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("두껍게")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onChange(of: borderWidth) { _, newValue in
                    gridStyleManager.setBorderWidth(newValue)
                    HapticManager.shared.selectionChanged()
                    refreshWidgets()
                }
            }
        } header: {
            Text("테두리 두께")
        } footer: {
            Text("0은 테두리 없음, 5는 두꺼운 테두리입니다.")
        }
    }

    // MARK: - Reset Section

    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                resetToDefault()
            } label: {
                HStack {
                    Spacer()
                    Label("기본값으로 초기화", systemImage: "arrow.counterclockwise")
                    Spacer()
                }
            }
            .disabled(!gridStyleManager.settings.isCustomized)
        }
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        refreshWidgets()
        HapticManager.shared.lightImpact()
        dismiss()
    }

    private func resetToDefault() {
        cornerRadius = GridStyleSettings.default.cornerRadius
        borderWidth = GridStyleSettings.default.borderWidth
        gridStyleManager.reset()
        HapticManager.shared.warning()
        refreshWidgets()
    }

    private func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Preview

#Preview {
    GridStyleSettingsView()
}
