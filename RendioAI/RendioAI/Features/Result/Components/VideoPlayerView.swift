//
//  VideoPlayerView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL?
    let isProcessing: Bool
    let hasFailed: Bool
    
    @State private var player: AVPlayer?
    @State private var showFullscreen = false
    
    var body: some View {
        ZStack {
            if let videoURL = videoURL, !isProcessing, !hasFailed {
                // Video Player
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)
                    .onTapGesture {
                        showFullscreen = true
                    }
                    .fullScreenCover(isPresented: $showFullscreen) {
                        FullscreenVideoPlayer(player: player)
                    }
                    .onAppear {
                        setupPlayer(url: videoURL)
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
                    .accessibilityLabel(NSLocalizedString("result.accessibility.video_player", comment: "Video player"))
                    .accessibilityHint(NSLocalizedString("result.accessibility.video_player_hint", comment: "Double tap to play video in fullscreen"))
                    .accessibilityAddTraits(.playsSound)
            } else {
                // Placeholder/Loading State
                placeholderView
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    // MARK: - Subviews
    
    private var placeholderView: some View {
        ZStack {
            Color("SurfaceCard")
            
            if isProcessing {
                // Processing State
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(Color("BrandPrimary"))
                        .scaleEffect(1.2)
                    
                    Text(NSLocalizedString("result.processing", comment: "Processing video"))
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }
            } else if hasFailed {
                // Failed State
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color("AccentError"))
                    
                    Text(NSLocalizedString("result.failed", comment: "Video generation failed"))
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }
            } else {
                // Loading/Empty State
                VStack(spacing: 12) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color("TextSecondary"))
                    
                    Text(NSLocalizedString("result.loading", comment: "Loading video"))
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Private Methods
    
    private func setupPlayer(url: URL) {
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        
        // Auto-play when ready
        newPlayer.play()
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        if isProcessing {
            return NSLocalizedString("result.accessibility.processing", comment: "Video is processing")
        } else if hasFailed {
            return NSLocalizedString("result.accessibility.failed", comment: "Video generation failed")
        } else {
            return NSLocalizedString("result.accessibility.loading", comment: "Loading video")
        }
    }
}

// MARK: - Fullscreen Video Player

struct FullscreenVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview("With Video") {
    VideoPlayerView(
        videoURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4"),
        isProcessing: false,
        hasFailed: false
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Processing") {
    VideoPlayerView(
        videoURL: nil,
        isProcessing: true,
        hasFailed: false
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

#Preview("Failed") {
    VideoPlayerView(
        videoURL: nil,
        isProcessing: false,
        hasFailed: true
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Loading") {
    VideoPlayerView(
        videoURL: nil,
        isProcessing: false,
        hasFailed: false
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

