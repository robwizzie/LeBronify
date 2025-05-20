import ActivityKit
import SwiftUI

// Define the attributes needed for the Live Activity
struct LeBronifyLiveActivityAttributes: ActivityAttributes {
    public typealias LeBronifyLiveActivityStatus = ContentState
    
    // Define the content state - what can change during activity updates
    public struct ContentState: Codable, Hashable {
        var songTitle: String
        var artistName: String
        var albumArt: String       // Asset name for compact view
        var albumArtURL: URL?      // Optional URL for expanded view
        var isPlaying: Bool
        var playbackProgress: Double
        var currentTime: TimeInterval
        var duration: TimeInterval
        var showInNotificationCenter: Bool = false // Don't show in notification center to avoid duplicate players
    }
    
    // Define the static attributes - what doesn't change during updates
    var songId: UUID
} 