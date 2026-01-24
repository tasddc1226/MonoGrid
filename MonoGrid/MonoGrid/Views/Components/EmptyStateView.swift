//
//  EmptyStateView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// View displayed when no habits have been created
struct EmptyStateView: View {
    // MARK: - Properties

    /// Action when add button is tapped
    let onAddHabit: () -> Void

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "target")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            // Text
            VStack(spacing: 8) {
                Text("첫 번째 습관을 추가하세요")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("최대 3개의 핵심 습관을 관리할 수 있습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Add Button
            Button(action: onAddHabit) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("습관 추가")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.UI.primaryButtonHeight)
                .background(Color.accentColor)
                .cornerRadius(Constants.UI.buttonCornerRadius)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView {
        print("Add habit tapped")
    }
}
