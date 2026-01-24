//
//  OnboardingView.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import SwiftUI

/// Onboarding flow for first-time users
struct OnboardingView: View {
    // MARK: - Environment

    @Environment(OnboardingViewModel.self) private var viewModel

    // MARK: - Body

    var body: some View {
        @Bindable var vm = viewModel

        VStack {
            // Page content
            TabView(selection: $vm.currentPage) {
                OnboardingPage1()
                    .tag(0)

                OnboardingPage2()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Bottom buttons
            HStack {
                // Skip button
                Button("건너뛰기") {
                    viewModel.skip()
                }
                .foregroundColor(.secondary)

                Spacer()

                // Next/Start button
                Button {
                    viewModel.nextPage()
                } label: {
                    Text(viewModel.isLastPage ? "시작하기" : "다음")
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Page 1: Core Concept

struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "target")
                .font(.system(size: 72))
                .foregroundColor(.accentColor)

            // Title
            Text("핵심에 집중하세요")
                .font(.title)
                .fontWeight(.bold)

            // Description
            VStack(spacing: 24) {
                // 3 habit slots visual
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { index in
                        let icons = ["book.fill", "figure.walk", "pills.fill"]
                        let colors: [Color] = [.habitCoral, .habitBlue, .habitGreen]

                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colors[index].opacity(0.15))
                                .frame(width: 70, height: 70)

                            Image(systemName: icons[index])
                                .font(.system(size: 28))
                                .foregroundColor(colors[index])
                        }
                    }
                }

                Text("3개의 핵심 습관만 관리하는\n미니멀 습관 트래커")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 2: Invisible Tracking

struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 72))
                .foregroundColor(.accentColor)

            // Title
            Text("Invisible Tracking")
                .font(.title)
                .fontWeight(.bold)

            // Description
            VStack(spacing: 24) {
                // Feature icons
                HStack(spacing: 24) {
                    featureItem(icon: "rectangle.stack", title: "위젯")
                    featureItem(icon: "square.grid.2x2", title: "제어센터")
                    featureItem(icon: "mic", title: "Siri")
                }

                Text("앱 실행 없이 위젯, 단축어,\n제어센터로 바로 기록하세요")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    @ViewBuilder
    private func featureItem(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.accentColor)
                .frame(width: 60, height: 60)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(OnboardingViewModel())
}

#Preview("Page 1") {
    OnboardingPage1()
}

#Preview("Page 2") {
    OnboardingPage2()
}
