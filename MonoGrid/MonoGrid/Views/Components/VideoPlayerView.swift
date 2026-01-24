//
//  VideoPlayerView.swift
//  MonoGrid
//
//  Created on 2026-01-24.
//

import SwiftUI
import AVKit

/// Video player component for onboarding tutorial
struct VideoPlayerView: View {
    // MARK: - Properties

    /// Video file name (without extension)
    let videoName: String

    /// Video file extension
    let videoExtension: String

    /// Whether to loop the video
    var isLooping: Bool = true

    /// Whether to show playback controls
    var showControls: Bool = false

    // MARK: - State

    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var hasError: Bool = false

    // MARK: - Initialization

    init(
        videoName: String,
        videoExtension: String = "mp4",
        isLooping: Bool = true,
        showControls: Bool = false
    ) {
        self.videoName = videoName
        self.videoExtension = videoExtension
        self.isLooping = isLooping
        self.showControls = showControls
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let player = player, !hasError {
                VideoPlayer(player: player)
                    .disabled(!showControls)
                    .onAppear {
                        player.play()
                        isPlaying = true
                    }
                    .onDisappear {
                        player.pause()
                        isPlaying = false
                    }
            } else {
                // Placeholder when video is not available
                placeholderView
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                player?.play()
            } else {
                player?.pause()
            }
        }
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))

            VStack(spacing: 16) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))

                Text("튜토리얼 영상")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Setup

    private func setupPlayer() {
        guard let url = Bundle.main.url(
            forResource: videoName,
            withExtension: videoExtension
        ) else {
            hasError = true
            return
        }

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = true

        if isLooping {
            setupLooping()
        }
    }

    private func setupLooping() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - Preview

#Preview {
    VideoPlayerView(videoName: "onboarding_tutorial")
        .frame(height: 300)
        .padding()
}
