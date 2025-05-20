//
//  AudioPlaybackManager.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/27/25.
//

import Foundation
import AVFoundation
import MediaPlayer
import ActivityKit
import SwiftUI
import UIKit // Needed for UIImage

// Define notification name for audio playback finished
extension NSNotification.Name {
    static let audioPlaybackFinished = NSNotification.Name("AudioPlaybackFinished")
}

// Since LiveActivityManager is in a different module, we'll define a direct access to the system player
private func updateSystemMediaPlayer(
    for song: Song, 
    isPlaying: Bool, 
    currentTime: TimeInterval, 
    duration: TimeInterval
) {
    // Get the shared MPNowPlayingInfoCenter
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    // Create a dictionary with the current track information
    var nowPlayingInfo = [String: Any]()
    
    // Set the track title and artist
    nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
    nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
    
    // Set playback information
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
    
    // Set the album artwork with high resolution
    if let image = UIImage(named: song.albumArt) {
        // Use high quality art for better display in Dynamic Island and CarPlay
        let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 1024, height: 1024)) { _ in 
            return image
        }
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
    }
    
    // Apply the updated information
    nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    
    // Post notification for CarPlay and other listeners
    NotificationCenter.default.post(
        name: NSNotification.Name("SongChanged"),
        object: nil,
        userInfo: [
            "song": song,
            "isPlaying": isPlaying,
            "currentTime": currentTime,
            "duration": duration
        ]
    )
}

class AudioPlaybackManager: NSObject {
    static let shared = AudioPlaybackManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var currentPlayingSong: Song? // Track the current song being played locally
    private var isAudioSessionInitialized = false
    
    // Add a flag to track genuine playback to prevent false "finished" notifications
    private var hasGenuinelyStartedPlaying = false
    private var playbackStartTime: Date?
    
    private override init() {
        super.init()
        // Don't call setupAudioSession during initialization
        // We'll do it lazily when needed
        
        // Only set up observers - this doesn't affect performance
        setupNotificationObservers()
        
        // Skip logging audio files during initialization to improve startup time
        print("AudioPlaybackManager: Initialized with lazy audio session setup")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        // Clean up audio session on deinit
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() -> Bool {
        // Skip if already initialized
        if isAudioSessionInitialized {
            return true
        }
        
        // Use minimal configuration from the start to avoid error -50
        do {
            print("AudioPlaybackManager: Initializing audio session on demand")
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            isAudioSessionInitialized = true
            print("AudioPlaybackManager: Audio session initialized successfully")
            
            // Setup interruption notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
            
            // Also observe when audio route changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
            
            return true
        } catch let error as NSError {
            print("AudioPlaybackManager: Audio session setup failed: \(error)")
            print("AudioPlaybackManager: Error code: \(error.code), domain: \(error.domain)")
            return false
        }
    }
    
    private func resetAndReconfigureAudioSession() -> Bool {
        // Try to reset the audio session completely
        print("AudioPlaybackManager: Attempting to reset and reconfigure audio session")
        
        do {
            // First deactivate the current session if it exists
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isAudioSessionInitialized = false
            
            // Small delay to ensure clean state
            Thread.sleep(forTimeInterval: 0.1)
            
            // Now try to set up again
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            isAudioSessionInitialized = true
            
            print("AudioPlaybackManager: Audio session reset successful")
            return true
        } catch {
            print("AudioPlaybackManager: Audio session reset failed: \(error)")
            return false
        }
    }
    
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interrupted (e.g., phone call) - pause playback
            print("AudioPlaybackManager: Audio session interrupted - pausing playback")
            pause()
        
        case .ended:
            // Interruption ended - check if we should resume
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                
                print("AudioPlaybackManager: Audio interruption ended - resuming playback")
                // First try to reactivate the session
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    // Resume playback if it was playing before
                    _ = resume()
                } catch {
                    print("AudioPlaybackManager: Failed to reactivate audio session after interruption: \(error)")
                }
            }
            
        @unknown default:
            break
        }
    }
    
    @objc private func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones were unplugged or Bluetooth disconnected
            print("AudioPlaybackManager: Audio route changed: device unavailable")
            pause()
            
        case .newDeviceAvailable:
            print("AudioPlaybackManager: Audio route changed: new device available")
            // Don't auto-resume here, let the user decide
            
        default:
            print("AudioPlaybackManager: Audio route changed: \(reason.rawValue)")
        }
    }
    
    // Setup notification observers for remote media control commands
    private func setupNotificationObservers() {
        // Listen for system media control notifications from LiveActivityManager
        NotificationCenter.default.addObserver(self, selector: #selector(handleSystemPlayCommand), 
                                               name: NSNotification.Name("systemPlayCommandReceived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSystemPauseCommand), 
                                               name: NSNotification.Name("systemPauseCommandReceived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSystemTogglePlayPauseCommand), 
                                               name: NSNotification.Name("systemTogglePlayPauseCommandReceived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSystemNextTrackCommand), 
                                               name: NSNotification.Name("systemNextTrackCommandReceived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSystemPreviousTrackCommand), 
                                               name: NSNotification.Name("systemPreviousTrackCommandReceived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSystemSeekCommand), 
                                               name: NSNotification.Name("systemSeekCommandReceived"), object: nil)
    }
    
    // Handlers for system media control notifications
    @objc private func handleSystemPlayCommand() {
        _ = resume()
    }
    
    @objc private func handleSystemPauseCommand() {
        pause()
    }
    
    @objc private func handleSystemTogglePlayPauseCommand() {
        _ = togglePlayPause()
    }
    
    @objc private func handleSystemNextTrackCommand() {
        NotificationCenter.default.post(name: .audioPlaybackFinished, object: nil)
    }
    
    @objc private func handleSystemPreviousTrackCommand() {
        NotificationCenter.default.post(name: NSNotification.Name("previousTrackRequested"), object: nil)
    }
    
    @objc private func handleSystemSeekCommand(_ notification: Notification) {
        if let position = notification.userInfo?["position"] as? TimeInterval {
            seekTo(time: position)
        }
    }
    
    // MARK: - Playback Controls
    
    func playSong(_ song: Song) -> Bool {
        // Initialize audio session on-demand when a song is played
        if !setupAudioSession() {
            // If initial setup fails, try reset and reconfigure
            if !resetAndReconfigureAudioSession() {
                print("AudioPlaybackManager: Unable to set up audio session after reset")
                return false
            }
        }
        
        // Log the attempt to find the song
        print("AudioPlaybackManager: Attempting to play song: \(song.title)")
        
        // Try multiple approaches to find the audio file
        
        // Approach 1: Try with the exact filename as stored in the model
        if let url = Bundle.main.url(forResource: song.audioFileName, withExtension: nil) {
            print("AudioPlaybackManager: Found song using exact filename")
            return playAudioFrom(url: url, for: song)
        }
        
        // Approach 2: Try with filename without extension and explicit mp3 extension
        let nameWithoutExtension = song.audioFileName.components(separatedBy: ".").first ?? song.audioFileName
        if let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: "mp3") {
            print("Found song using filename without extension + .mp3")
            return playAudioFrom(url: url, for: song)
        }
        
        // Approach 3: Try looking in a "Songs" subdirectory
        if let url = Bundle.main.url(forResource: song.audioFileName, withExtension: nil, subdirectory: "Songs") {
            print("Found song in Songs subdirectory")
            return playAudioFrom(url: url, for: song)
        }
        
        // Approach 4: Try looking for the song in the Documents directory (if songs are downloaded)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let documentsDirectory = documentsDirectory {
            let fileURL = documentsDirectory.appendingPathComponent(song.audioFileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("Found song in Documents directory")
                return playAudioFrom(url: fileURL, for: song)
            }
        }
        
        // Special debugging: Log all audio files in the bundle to help diagnose issues
        logAvailableAudioFiles()
        
        print("Could not find audio file: \(song.audioFileName) (tried multiple approaches)")
        return false
    }
    
    func prepareAudio(for song: Song) {
        // Initialize audio session on-demand
        if !setupAudioSession() {
            print("AudioPlaybackManager: Audio session setup failed during prepare")
            return
        }
        
        // Log the attempt to find the song
        print("Preparing audio for song: \(song.title) with filename: \(song.audioFileName)")
        
        // Try multiple approaches to find the audio file, just like in playSong
        
        // Approach 1: Try with the exact filename as stored in the model
        if let url = Bundle.main.url(forResource: song.audioFileName, withExtension: nil) {
            print("Found song using exact filename")
            prepareAudioFrom(url: url, for: song)
            return
        }
        
        // Approach 2: Try with filename without extension and explicit mp3 extension
        let nameWithoutExtension = song.audioFileName.components(separatedBy: ".").first ?? song.audioFileName
        if let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: "mp3") {
            print("Found song using filename without extension + .mp3")
            prepareAudioFrom(url: url, for: song)
            return
        }
        
        // Approach 3: Try looking in a "Songs" subdirectory
        if let url = Bundle.main.url(forResource: song.audioFileName, withExtension: nil, subdirectory: "Songs") {
            print("Found song in Songs subdirectory")
            prepareAudioFrom(url: url, for: song)
            return
        }
        
        // Approach 4: Try looking for the song in the Documents directory (if songs are downloaded)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let documentsDirectory = documentsDirectory {
            let fileURL = documentsDirectory.appendingPathComponent(song.audioFileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("Found song in Documents directory")
                prepareAudioFrom(url: fileURL, for: song)
                return
            }
        }
        
        print("Could not find audio file for preparation: \(song.audioFileName) (tried multiple approaches)")
    }

    private func prepareAudioFrom(url: URL, for song: Song) {
        do {
            // Create audio player and prepare to play, but don't start playing
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            
            // Store the current song
            currentPlayingSong = song
            
            // Update the media info
            if let player = audioPlayer {
                updateSystemMediaPlayer(
                    for: song, 
                    isPlaying: false, 
                    currentTime: 0, 
                    duration: player.duration
                )
            }
            
            print("Successfully prepared audio for: \(song.title)")
        } catch {
            print("Error preparing audio: \(error.localizedDescription)")
        }
    }
    
    private func playAudioFrom(url: URL, for song: Song) -> Bool {
        // Reset playback tracking to avoid stale state
        hasGenuinelyStartedPlaying = false
        playbackStartTime = nil
        
        do {
            // Only activate audio session if not already active
            if !isAudioSessionInitialized {
               _ = setupAudioSession()
            }
            
            let audioSession = AVAudioSession.sharedInstance()
            if !audioSession.isOtherAudioPlaying && !audioSession.isInputAvailable {
                do {
                    try audioSession.setActive(true)
                } catch {
                    print("AudioPlaybackManager: Note - Audio session already active or couldn't be activated: \(error)")
                    // Continue anyway - the session might still work for playback
                }
            }
            
            // Clean up any existing player first
            if audioPlayer != nil {
                audioPlayer?.stop()
                audioPlayer = nil
            }
            
            // Create audio player and prepare to play
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            
            // Configure player
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.numberOfLoops = 0 // Don't loop by default
            
            // Make sure it's ready before playing
            if !(audioPlayer?.prepareToPlay() ?? false) {
                print("AudioPlaybackManager: Failed to prepare audio player")
                return false
            }
            
            // Play with a simpler approach - no need for double-checking
            if !(audioPlayer?.play() ?? false) {
                print("AudioPlaybackManager: Failed to start playback")
                return false
            }
            
            // Store the current song
            currentPlayingSong = song
            
            // Update the media info
            if let player = audioPlayer {
                updateSystemMediaPlayer(
                    for: song, 
                    isPlaying: true, 
                    currentTime: 0, 
                    duration: player.duration
                )
                
                print("AudioPlaybackManager: Successfully started playing: \(song.title), duration: \(player.duration)s")
            }
            
            // Post notification that playback has started
            NotificationCenter.default.post(name: NSNotification.Name("PlaybackStarted"), object: nil)
            
            // Set the playback start time
            playbackStartTime = Date()
            hasGenuinelyStartedPlaying = true
            
            return true
        } catch {
            print("AudioPlaybackManager: Error playing audio: \(error.localizedDescription)")
            
            // More detailed error logging
            if let err = error as NSError? {
                print("AudioPlaybackManager: Audio play error - Domain: \(err.domain), Code: \(err.code)")
                
                // Add specific handling for common error codes
                if err.domain == NSOSStatusErrorDomain {
                    switch err.code {
                    case -50:
                        print("AudioPlaybackManager: Error -50: Permission or privacy issue with audio session")
                    case -54:
                        print("AudioPlaybackManager: Error -54: File format not recognized")
                    case -43:
                        print("AudioPlaybackManager: Error -43: File not found at specified path")
                    default:
                        break
                    }
                }
            }
            
            return false
        }
    }
    
    func resume() -> Bool {
        // Check if audio session needs initialization
        if !isAudioSessionInitialized {
            _ = setupAudioSession()
        }
        
        guard let player = audioPlayer, !player.isPlaying else { return false }
        
        let success = player.play()
        if !success {
            print("AudioPlaybackManager: Resume failed")
            return false
        }
        
        // Update media info with new playing state
        if let song = currentPlayingSong {
            updateSystemMediaPlayer(
                for: song, 
                isPlaying: true, 
                currentTime: player.currentTime, 
                duration: player.duration
            )
        }
        
        // Notify observers that playback has started
        NotificationCenter.default.post(name: NSNotification.Name("PlaybackStarted"), object: nil)
        
        // Update playback tracking flags
        playbackStartTime = Date()
        hasGenuinelyStartedPlaying = true
        
        return true
    }
    
    func pause() {
        if let player = audioPlayer, player.isPlaying {
            player.pause()
            
            // Update media info with new paused state
            if let song = currentPlayingSong {
                updateSystemMediaPlayer(
                    for: song, 
                    isPlaying: false, 
                    currentTime: player.currentTime, 
                    duration: player.duration
                )
            }
            
            // Notify observers that playback has paused
            NotificationCenter.default.post(name: NSNotification.Name("PlaybackPaused"), object: nil)
        }
    }
    
    func togglePlayPause() -> Bool {
        // Check if audio session needs initialization
        if !isAudioSessionInitialized {
            _ = setupAudioSession()
        }
        
        guard let player = audioPlayer else { return false }
        
        var success = false
        
        if player.isPlaying {
            player.pause()
            success = true
            
            // Notify observers that playback has paused
            NotificationCenter.default.post(name: NSNotification.Name("PlaybackPaused"), object: nil)
            
            // Don't reset the tracking flags on pause, only if playback stops completely
        } else {
            success = player.play()
            
            if success {
                // Notify observers that playback has started
                NotificationCenter.default.post(name: NSNotification.Name("PlaybackStarted"), object: nil)
                
                // Set or update the playback tracking
                playbackStartTime = Date()
                hasGenuinelyStartedPlaying = true
            }
        }
        
        // Update media info with new playing/paused state
        if let song = currentPlayingSong {
            updateSystemMediaPlayer(for: song, isPlaying: player.isPlaying, currentTime: player.currentTime, duration: player.duration)
        }
        
        return success
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentPlayingSong = nil
        
        // Reset playback tracking flags
        hasGenuinelyStartedPlaying = false
        playbackStartTime = nil
        
        // Notify observers that playback has stopped
        NotificationCenter.default.post(name: NSNotification.Name("PlaybackStopped"), object: nil)
        
        // Deactivate audio session to free up resources
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isAudioSessionInitialized = false
    }
    
    func seekTo(time: TimeInterval) {
        if let player = audioPlayer {
            player.currentTime = time
            
            // Update media info with new position
            if let song = currentPlayingSong {
                updateSystemMediaPlayer(
                    for: song, 
                    isPlaying: player.isPlaying, 
                    currentTime: time, 
                    duration: player.duration
                )
            }
        }
    }
    
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    var currentTime: TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    // MARK: - Debug Helpers
    
    func logAvailableAudioFiles() {
        print("=== SCANNING FOR AUDIO FILES ===")
        
        // Check in the main bundle
        guard let resourceURL = Bundle.main.resourceURL else {
            print("Could not access app bundle resources")
            return
        }
        
        // List files in main bundle
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: resourceURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            let audioFileURLs = fileURLs.filter { url in
                let fileExtension = url.pathExtension.lowercased()
                return ["mp3", "m4a", "wav", "aac"].contains(fileExtension)
            }
            
            print("Found \(audioFileURLs.count) audio files in main bundle:")
            for url in audioFileURLs {
                print("- \(url.lastPathComponent)")
            }
        } catch {
            print("Error listing bundle contents: \(error)")
        }
        
        // Check if there's a Songs directory
        if let songsURL = Bundle.main.url(forResource: "Songs", withExtension: nil) {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: songsURL,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                )
                
                let audioFileURLs = fileURLs.filter { url in
                    let fileExtension = url.pathExtension.lowercased()
                    return ["mp3", "m4a", "wav", "aac"].contains(fileExtension)
                }
                
                print("Found \(audioFileURLs.count) audio files in Songs directory:")
                for url in audioFileURLs {
                    print("- \(url.lastPathComponent)")
                }
            } catch {
                print("Error listing Songs directory: \(error)")
            }
        } else {
            print("No Songs directory found in bundle")
        }
        
        // Print some diagnostics about the song data
        let songManager = SongManager.shared
        print("\nTesting song discovery...")
        let testSongs = songManager.discoverSongsInBundle()
        print("SongManager discovered \(testSongs.count) songs")
        
        print("=== END OF AUDIO FILE SCAN ===")
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("AudioPlaybackManager: Audio playback finished, checking if genuine playback occurred")
        
        // Only consider it a genuine finish if:
        // 1. We've marked playback as having genuinely started
        // 2. At least 1 second has passed since playback started (to avoid initialization false positives)
        let hasPlayedLongEnough = playbackStartTime != nil && 
                                 Date().timeIntervalSince(playbackStartTime!) >= 1.0
        
        if hasGenuinelyStartedPlaying && hasPlayedLongEnough && flag {
            print("AudioPlaybackManager: Confirmed genuine playback finish, posting notification")
            // Post notification when playback finishes successfully
            NotificationCenter.default.post(name: .audioPlaybackFinished, object: nil)
        } else {
            if !hasGenuinelyStartedPlaying {
                print("AudioPlaybackManager: Ignoring finish notification - playback never genuinely started")
            } else if !hasPlayedLongEnough {
                print("AudioPlaybackManager: Ignoring finish notification - played for less than 1 second")
            } else if !flag {
                print("AudioPlaybackManager: Playback finished unsuccessfully")
            }
        }
        
        // Reset playback tracking flags
        hasGenuinelyStartedPlaying = false
        playbackStartTime = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("AudioPlaybackManager: Decode error: \(error?.localizedDescription ?? "unknown error")")
        // Reset playback tracking flags on error
        hasGenuinelyStartedPlaying = false
        playbackStartTime = nil
    }
}