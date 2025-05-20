import Foundation
import MediaPlayer
import UIKit

// This class handles system media player integration using MPNowPlayingInfoCenter
class LiveActivityManager {
    // Singleton instance
    static let shared = LiveActivityManager()
    
    private init() {
        configureRemoteCommandCenter()
    }
    
    // Update the system media player info for a song
    func updateMediaInfo(for song: Any, isPlaying: Bool, currentTime: TimeInterval, duration: TimeInterval) {
        // Extract properties from the song object using key paths to avoid direct type dependency
        guard let songTitle = (song as AnyObject).value(forKey: "title") as? String,
              let artistName = (song as AnyObject).value(forKey: "artist") as? String,
              let albumArt = (song as AnyObject).value(forKey: "albumArt") as? String else {
            print("Error: Invalid song object provided")
            return
        }
        
        updateNowPlayingInfo(songTitle: songTitle, artistName: artistName, albumArt: albumArt, 
                            currentTime: currentTime, duration: duration, isPlaying: isPlaying)
    }
    
    // Update the system Now Playing info directly
    func updateNowPlayingInfo(songTitle: String, artistName: String, albumArt: String, 
                             currentTime: TimeInterval, duration: TimeInterval, isPlaying: Bool) {
        // Get the shared MPNowPlayingInfoCenter
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        // Create a dictionary with the current track information
        var nowPlayingInfo = [String: Any]()
        
        // Set the track title and artist
        nowPlayingInfo[MPMediaItemPropertyTitle] = songTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = artistName
        
        // Set playback information
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Set the album artwork with high resolution
        if let image = UIImage(named: albumArt) {
            // Use high quality art for better display in Dynamic Island
            let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 1024, height: 1024)) { _ in 
                return image
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // Apply the updated information
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    // Configure system Remote Command Center
    private func configureRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Clear any existing handlers
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        
        // Configure playback commands
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            // Post notification for play command
            NotificationCenter.default.post(name: NSNotification.Name("systemPlayCommandReceived"), object: nil)
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            // Post notification for pause command
            NotificationCenter.default.post(name: NSNotification.Name("systemPauseCommandReceived"), object: nil)
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            // Post notification for toggle command
            NotificationCenter.default.post(name: NSNotification.Name("systemTogglePlayPauseCommandReceived"), object: nil)
            return .success
        }
        
        // Configure skip commands
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { _ in
            NotificationCenter.default.post(name: NSNotification.Name("systemNextTrackCommandReceived"), object: nil)
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { _ in
            NotificationCenter.default.post(name: NSNotification.Name("systemPreviousTrackCommandReceived"), object: nil)
            return .success
        }
        
        // Configure seeking commands
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                NotificationCenter.default.post(
                    name: NSNotification.Name("systemSeekCommandReceived"), 
                    object: nil, 
                    userInfo: ["position": event.positionTime]
                )
                return .success
            }
            return .commandFailed
        }
    }
} 