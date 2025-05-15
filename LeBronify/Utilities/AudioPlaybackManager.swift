//
//  AudioPlaybackManager.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/27/25.
//

import Foundation
import AVFoundation
import MediaPlayer

class AudioPlaybackManager {
    static let shared = AudioPlaybackManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var nowPlayingInfo = [String: Any]()
    
    private init() {
        setupAudioSession()
        logAvailableAudioFiles() // Add debug logging on initialization
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Playback Controls
    
    func playSong(_ song: Song) -> Bool {
        // Log the attempt to find the song
        print("Attempting to play song: \(song.title) with filename: \(song.audioFileName)")
        
        // Try multiple approaches to find the audio file
        
        // Approach 1: Try with the exact filename as stored in the model
        if let url = Bundle.main.url(forResource: song.audioFileName, withExtension: nil) {
            print("Found song using exact filename")
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
        
        print("Could not find audio file: \(song.audioFileName) (tried multiple approaches)")
        return false
    }
    
    func prepareAudio(for song: Song) {
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
            
            // Update now playing info
            updateNowPlayingInfo(for: song)
            
            print("Successfully prepared audio for: \(song.title)")
        } catch {
            print("Error preparing audio: \(error.localizedDescription)")
        }
    }
    private func playAudioFrom(url: URL, for song: Song) -> Bool {
        do {
            // Create audio player and prepare to play
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            // Update now playing info
            updateNowPlayingInfo(for: song)
            
            return true
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
            return false
        }
    }
    
    func togglePlayPause() -> Bool {
        guard let player = audioPlayer else { return false }
        
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        // Update playing state in now playing info
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        return true
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func seekTo(time: TimeInterval) {
        audioPlayer?.currentTime = time
        
        // Update playback position in now playing info
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
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
    
    // MARK: - Now Playing
    
    private func updateNowPlayingInfo(for song: Song) {
        nowPlayingInfo = [String: Any]()
        
        // Set metadata
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = song.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer?.currentTime ?? 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer?.isPlaying ?? false ? 1.0 : 0.0
        
        // Set album artwork
        if let image = UIImage(named: song.albumArt) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // Update now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
