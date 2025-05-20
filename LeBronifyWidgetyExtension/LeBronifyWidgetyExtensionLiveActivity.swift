//
//  LeBronifyWidgetyExtensionLiveActivity.swift
//  LeBronifyWidgetyExtension
//
//  Created by Robert Wiscount on 5/15/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// Use same structure as the main app
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

struct LeBronifyWidgetyExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LeBronifyLiveActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.7))
                .activitySystemActionForegroundColor(Color.yellow)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        // Use a system image if the album art can't be found
                        if UIImage(named: context.state.albumArt) != nil {
                            Image(context.state.albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 45, height: 45)
                                .cornerRadius(6)
                        } else {
                            Image(systemName: "music.note")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .padding(10)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(6)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.songTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(context.state.artistName)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 2)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    // Duration/progress indicator on the trailing side
                    Text(formatTime(context.state.currentTime))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    // Compact player controls
                    HStack(spacing: 20) {
                        Button(intent: PreviousTrackIntent()) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: PlayPauseIntent()) {
                            Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.yellow)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: NextTrackIntent()) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Slimmer progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 3)
                                .cornerRadius(1.5)
                            
                            // Progress track
                            Rectangle()
                                .fill(Color.yellow)
                                .frame(width: max(0, geometry.size.width * context.state.playbackProgress), height: 3)
                                .cornerRadius(1.5)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            } compactLeading: {
                // Compact album art with fallback
                if UIImage(named: context.state.albumArt) != nil {
                    Image(context.state.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }
            } compactTrailing: {
                // More minimalist display like Spotify in compact mode
                HStack(spacing: 4) {
                    Text(context.state.songTitle)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .frame(maxWidth: 80, alignment: .leading)
                    
                    // Play/pause button
                    Button(intent: PlayPauseIntent()) {
                        Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                }
            } minimal: {
                // Minimal view (when other activities are present)
                if UIImage(named: context.state.albumArt) != nil {
                    Image(context.state.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 16, height: 16)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
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
                // Use a system image if the album art can't be found
                if UIImage(named: context.state.albumArt) != nil {
                    Image(context.state.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "music.note")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .padding(15)
                        .background(Color.gray.opacity(0.3))
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
                
                // Add the playback controls at the right
                HStack(spacing: 16) {
                    Button(intent: PreviousTrackIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: PlayPauseIntent()) {
                        Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: NextTrackIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
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

extension LeBronifyLiveActivityAttributes {
    fileprivate static var preview: LeBronifyLiveActivityAttributes {
        LeBronifyLiveActivityAttributes(songId: UUID())
    }
}

extension LeBronifyLiveActivityAttributes.ContentState {
    fileprivate static var preview: LeBronifyLiveActivityAttributes.ContentState {
        LeBronifyLiveActivityAttributes.ContentState(
            songTitle: "King James",
            artistName: "LeBron",
            albumArt: "lebron_crown",
            isPlaying: true,
            playbackProgress: 0.45,
            currentTime: 135,
            duration: 300
        )
     }
}

#Preview("Notification", as: .content, using: LeBronifyLiveActivityAttributes.preview) {
   LeBronifyWidgetyExtensionLiveActivity()
} contentStates: {
    LeBronifyLiveActivityAttributes.ContentState.preview
}
