import Foundation
import MediaPlayer
import UIKit

// This class handles system media player integration using MPNowPlayingInfoCenter
// Remote command center is configured by AppDelegate.setupRemoteCommandCenter()
// to avoid duplicate handlers. This class only manages Now Playing info.
class LiveActivityManager {
    // Singleton instance
    static let shared = LiveActivityManager()

    private init() {}

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
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()

        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = songTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = artistName
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        // Set the album artwork with high resolution for Dynamic Island display
        if let image = UIImage(named: albumArt) {
            let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 1024, height: 1024)) { _ in
                return image
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}
