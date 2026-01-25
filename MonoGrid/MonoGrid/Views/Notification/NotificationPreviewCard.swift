//
//  NotificationPreviewCard.swift
//  MonoGrid
//
//  Created on 2026-01-25.
//

import SwiftUI

/// Preview card showing how the notification will look
struct NotificationPreviewCard: View {
    // MARK: - Properties

    let message: NotificationMessage

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("MonoGrid")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("지금")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(message.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(message.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: Constants.UI.cardCornerRadius)
                .fill(Color(.secondarySystemBackground))
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

// MARK: - Preview

#Preview {
    List {
        Section(header: Text("알림 미리보기")) {
            NotificationPreviewCard(
                message: NotificationMessage(
                    title: "🔥 7일 연속 달성 중!",
                    body: "오늘도 이어가볼까요?",
                    badgeCount: 2
                )
            )
        }
    }
}
