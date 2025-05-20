import WidgetKit
import SwiftUI
import ActivityKit

// Define the attributes needed for the Live Activity
struct LeBronifyLiveActivityAttributes: ActivityAttributes {
    public typealias LeBronifyLiveActivityStatus = ContentState
    
    // Define the content state - what can change during activity updates
    public struct ContentState: Codable, Hashable {
        var songTitle: String
        var artistName: String
        var albumArt: String
        var isPlaying: Bool
        var playbackProgress: Double
        var currentTime: TimeInterval
        var duration: TimeInterval
    }
    
    // Define the static attributes - what doesn't change during updates
    var songId: UUID
}

// Widget that defines how the Live Activity looks in Dynamic Island
struct LeBronifyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LeBronifyLiveActivityAttributes.self) { context in
            // Lock screen presentation
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 12) {
                        Image(context.state.albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 55, height: 55)
                            .cornerRadius(8)
                        
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
                    // Spotify-like playback controls in the center region
                    HStack(spacing: 24) {
                        Button(action: {}) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.yellow)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.primary)
                        }
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
                Image(context.state.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                
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
                
                // Add the playback controls at the right
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.yellow)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
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