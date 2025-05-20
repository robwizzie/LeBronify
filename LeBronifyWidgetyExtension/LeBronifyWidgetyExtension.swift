//
//  LeBronifyWidgetyExtension.swift
//  LeBronifyWidgetyExtension
//
//  Created by Robert Wiscount on 5/15/25.
//

import WidgetKit
import SwiftUI
import AppIntents
import UIKit

// Mock data for widget preview and when no song is playing
struct MusicPlayerData {
    var songTitle: String
    var artistName: String
    var albumArt: String
    var isPlaying: Bool
    var playbackProgress: Double
    var currentTime: TimeInterval
    var duration: TimeInterval
    
    static let placeholder = MusicPlayerData(
        songTitle: "King James",
        artistName: "LeBron",
        albumArt: "lebron_crown",
        isPlaying: false,
        playbackProgress: 0.45,
        currentTime: 135,
        duration: 300
    )
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            playerData: MusicPlayerData.placeholder
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // For the snapshot view (preview), use placeholder data
        SimpleEntry(
            date: Date(),
            configuration: configuration,
            playerData: MusicPlayerData.placeholder
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Read current playback data from shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.robertwiscount.LeBronify")
        
        // If we have data in UserDefaults, use it; otherwise use placeholder
        let playerData: MusicPlayerData
        
        if let songTitle = sharedDefaults?.string(forKey: "songTitle"),
           let artistName = sharedDefaults?.string(forKey: "artistName"),
           let albumArt = sharedDefaults?.string(forKey: "albumArt") {
            
            // Verify the album art exists
            let artExists = UIImage(named: albumArt) != nil
            let finalArtName = artExists ? albumArt : "lebron_crown" // Use lebron_crown as fallback for widget preview
            
            let isPlaying = sharedDefaults?.bool(forKey: "isPlaying") ?? false
            let progress = sharedDefaults?.double(forKey: "playbackProgress") ?? 0.0
            let currentTime = sharedDefaults?.double(forKey: "currentTime") ?? 0.0
            let duration = sharedDefaults?.double(forKey: "duration") ?? 0.0
            
            playerData = MusicPlayerData(
                songTitle: songTitle,
                artistName: artistName,
                albumArt: finalArtName,
                isPlaying: isPlaying,
                playbackProgress: progress,
                currentTime: currentTime,
                duration: duration
            )
        } else {
            // Use placeholder if no data is available
            playerData = MusicPlayerData.placeholder
        }
        
        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            playerData: playerData
        )
        entries.append(entry)

        // Update widget more frequently if music is playing
        let refreshDate = playerData.isPlaying ? 
            Date().addingTimeInterval(5) : // 5 seconds if playing
            Date().addingTimeInterval(60)  // 1 minute if not playing
            
        return Timeline(entries: entries, policy: .after(refreshDate))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let playerData: MusicPlayerData
}

struct LeBronifyWidgetyExtensionEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
            
            VStack(spacing: 10) {
                // Album art and song details
                HStack(spacing: 12) {
                    // Album art with fallback
                    if UIImage(named: entry.playerData.albumArt) != nil {
                        Image(entry.playerData.albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "music.note")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .padding(15)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Song info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.playerData.songTitle)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.white)
                        
                        Text(entry.playerData.artistName)
                            .font(.subheadline)
                            .lineLimit(1)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                
                // Progress bar
                ProgressView(value: entry.playerData.playbackProgress)
                    .progressViewStyle(.linear)
                    .tint(.yellow)
                
                // Time labels
                HStack {
                    Text(formatTime(entry.playerData.currentTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(formatTime(entry.playerData.duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Player controls
                HStack(spacing: 40) {
                    Button(intent: PreviousTrackIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: PlayPauseIntent()) {
                        Image(systemName: entry.playerData.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: NextTrackIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 5)
            }
            .padding()
        }
    }
    
    // Helper function to format time
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct LeBronifyWidgetyExtension: Widget {
    let kind: String = "LeBronifyWidgetyExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            LeBronifyWidgetyExtensionEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("LeBronify Player")
        .description("Control your music and see what's playing.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// Preview data
extension ConfigurationAppIntent {
    fileprivate static var preview: ConfigurationAppIntent {
        return ConfigurationAppIntent()
    }
}

#Preview(as: .systemMedium) {
    LeBronifyWidgetyExtension()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: .preview,
        playerData: MusicPlayerData.placeholder
    )
}
