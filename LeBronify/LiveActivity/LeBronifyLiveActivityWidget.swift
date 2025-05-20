import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents
import MediaPlayer

// Widget that defines how the Live Activity looks in Dynamic Island
struct LeBronifyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LeBronifyLiveActivityAttributes.self) { context in
            // Only show in lock screen if explicitly requested (we typically want to use the system player instead)
            if context.state.showInNotificationCenter {
                LockScreenLiveActivityView(context: context)
            } else {
                // Return an empty view to prevent duplicate players
                EmptyView()
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 12) {
                        // Use AsyncImage to load from URL when available, fallback to asset name
                        if let artURL = context.state.albumArtURL {
                            AsyncImage(url: artURL) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 55, height: 55)
                                        .cornerRadius(8)
                                } else {
                                    // Fallback to asset or placeholder
                                    Image(context.state.albumArt)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 55, height: 55)
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            // Use bundled asset
                            Image(context.state.albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 55, height: 55)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.state.songTitle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(context.state.artistName)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    // No content in trailing region to match Spotify
                }
                
                DynamicIslandExpandedRegion(.center) {
                    // Media controls are handled by the system, just show minimal UI here
                    HStack(spacing: 24) {
                        // Using system handlers now, so the buttons are just visual
                        Image(systemName: "backward.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                        
                        Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.yellow)
                        
                        Image(systemName: "forward.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        // Progress bar with thumb indicator like Spotify
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                
                                // Progress track
                                Rectangle()
                                    .fill(Color.yellow)
                                    .frame(width: max(0, geometry.size.width * context.state.playbackProgress), height: 4)
                                    .cornerRadius(2)
                                
                                // Thumb indicator
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 12, height: 12)
                                    .offset(x: max(0, geometry.size.width * context.state.playbackProgress - 6))
                            }
                        }
                        .frame(height: 12)
                        .padding(.horizontal, 2)
                        
                        // Time labels
                        HStack {
                            Text(formatTime(context.state.currentTime))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatTime(context.state.duration))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                // Spotify-style: just show album art in compact mode
                Image(context.state.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 24)
                    .cornerRadius(4)
            } compactTrailing: {
                // More minimalist display like Spotify in compact mode
                HStack(spacing: 4) {
                    Text(context.state.songTitle)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .frame(maxWidth: 90, alignment: .leading)
                    
                    // Just a small dot as a separator
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 3, height: 3)
                    
                    // Play/pause icon
                    Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
            } minimal: {
                // Minimal view (when other activities are present)
                Image(context.state.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .cornerRadius(4)
            }
            .keylineTint(.yellow)
        }
    }
    
    // Helper function to format time
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// View for the lock screen version of the live activity
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LeBronifyLiveActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Use AsyncImage with fallback to asset
                if let artURL = context.state.albumArtURL {
                    AsyncImage(url: artURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        } else {
                            // Fallback to asset
                            Image(context.state.albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    Image(context.state.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.songTitle)
                        .font(.headline)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text(context.state.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add the playback controls at the right - just visual elements now
                HStack(spacing: 16) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                    
                    Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.yellow)
                    
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
            
            // Progress bar with thumb indicator for lock screen
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress track
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: max(0, geometry.size.width * context.state.playbackProgress), height: 4)
                        .cornerRadius(2)
                    
                    // Thumb indicator
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .offset(x: max(0, geometry.size.width * context.state.playbackProgress - 6))
                }
            }
            .frame(height: 12)
            
            // Time labels
            HStack {
                Text(formatTime(context.state.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(context.state.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    // Helper function to format time
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 