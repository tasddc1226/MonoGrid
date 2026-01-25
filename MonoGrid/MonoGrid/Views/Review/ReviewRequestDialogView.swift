//
//  ReviewRequestDialogView.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import SwiftUI

/// Pre-confirmation dialog view for app review request
/// Shown before SKStoreReviewController to filter positive users
struct ReviewRequestDialogView: View {
    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @Bindable var viewModel: ReviewRequestViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.onDismiss()
                }

            // Dialog content
            if viewModel.showingTransition {
                transitionView
                    .transition(.opacity)
            } else {
                dialogContent
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(
            reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.7),
            value: viewModel.showingDialog
        )
        .animation(
            reduceMotion ? .none : .easeOut(duration: 0.2),
            value: viewModel.showingTransition
        )
    }

    // MARK: - Dialog Content

    private var dialogContent: some View {
        VStack(spacing: 20) {
            // Emoji
            Text(viewModel.milestoneEmoji)
                .font(.system(size: 48))

            // Title
            Text(viewModel.milestoneTitle)
                .font(.title2)
                .fontWeight(.bold)

            // Subtitle
            Text(viewModel.milestoneSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Question
            Text("모노그리드가\n마음에 드시나요?")
                .font(.headline)
                .multilineTextAlignment(.center)

            // Buttons
            HStack(spacing: 12) {
                Button("아니요") {
                    viewModel.onNegativeResponse()
                }
                .buttonStyle(ReviewSecondaryButtonStyle())

                Button("네, 좋아요!") {
                    viewModel.onPositiveResponse()
                }
                .buttonStyle(ReviewPrimaryButtonStyle())
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20)
        .padding(.horizontal, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("모노그리드 평가 요청")
        .accessibilityHint("\(viewModel.currentMilestone)일 연속 달성을 축하합니다")
    }

    // MARK: - Transition View

    private var transitionView: some View {
        VStack(spacing: 20) {
            Text("⭐️ ⭐️ ⭐️")
                .font(.title)

            Text("감사합니다! 💙")
                .font(.title2)
                .fontWeight(.bold)

            Text("잠시 후 평가 화면이\n나타납니다...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ProgressView()
                .scaleEffect(1.2)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20)
        .padding(.horizontal, 40)
    }
}

// MARK: - Button Styles

/// Primary button style for positive response
struct ReviewPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.blue)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .accessibilityLabel("네, 좋아요! 버튼")
            .accessibilityHint("앱스토어 평가 화면으로 이동합니다")
    }
}

/// Secondary button style for negative response
struct ReviewSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(Color(.systemGray))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(configuration.isPressed ? Color(.systemGray5) : Color.clear)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .accessibilityLabel("아니요 버튼")
            .accessibilityHint("평가 요청을 닫습니다")
    }
}

// MARK: - Preview

#Preview {
    ReviewRequestDialogView(viewModel: ReviewRequestViewModel())
}
