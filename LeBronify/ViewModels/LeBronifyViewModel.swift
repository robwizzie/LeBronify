//
//  LeBronifyViewModel.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import Foundation
import Combine
import MediaPlayer
import AVFoundation

// Define an alias to keep backward compatibility
typealias LeBronifyLiveActivityAttributes = Int

class LeBronifyViewModel: ObservableObject {
    // Song and playlist data
    @Published var allSongs: [Song] = []
    @Published var playlists: [Playlist] = []
    @Published var recentlyPlayedSongs: [Song] = []
    @Published var topHitsSongs: [Song] = []
    @Published var favoriteSongs: [Song] = []
    
    // Playback state
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var currentPlaybackTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    // Queue management
    let queueManager = QueueManager()
    
    // AD state
    @Published var showingAd: Bool = false
    @Published var currentAd: AnthonyDavisAd?
    
    // Taco Tuesday state
    @Published var isTacoSongPlaying: Bool = false
    
    // Audio player
    private let audioManager = AudioPlaybackManager.shared
    
    // Timers
    private var playbackTimer: Timer?
    private var adTimer: Timer?
    
    // Data manager
    private let dataManager = DataManager.shared
    
    // Taco Tuesday manager
    private let tacoManager = TacoTuesdayManager.shared
    
    // Tracking for play count
    private var playTimeThresholdReached = false
    private var currentSongPlayTimer: Timer?
    
    // Flag to track genuine playback vs. initialization
    private var hasPlaybackStarted: Bool = false
    
    // Add the missing threshold constant
    private let currentPlaybackTimeThreshold: TimeInterval = 10.0 // 10 seconds threshold for play count
    
    // MARK: - Initialization and Setup
    
    init() {
        print("ViewModel: Starting fast initialization")
        
        // Load data using cached approach for speed
        loadData()
        
        // Set up essential timers and notifications
        setupTimers()
        setupNotifications()
        
        // Prepare queue but don't force audio initialization
        if queueManager.currentQueue.isEmpty {
            _ = queueManager.generateRandomPresetQueue()
        }
        
        // Bind to queue updates
        setupQueueBinding()
        
        // Set up playback timer
        setupPlaybackTimer()
        
        // Don't do audio setup or queue manipulation on init
        // This will prevent audio session errors during startup
        print("ViewModel: Fast initialization complete")
    }
    
    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        // Clean up timers
        playbackTimer?.invalidate()
        adTimer?.invalidate()
        currentSongPlayTimer?.invalidate()
    }
    
    // MARK: - Data Loading
    
    // Update loadData to not cause excessive refreshes
    func loadData() {
        print("ViewModel: Loading data")
        
        // Load songs directly from DataManager (which now uses cached results)
        allSongs = dataManager.loadSongs()
        print("ViewModel: Loaded \(allSongs.count) songs")
        
        // Add Taco Tuesday song if it's Tuesday
        if tacoManager.isTacoTuesday {
            let tacoSong = tacoManager.createTacoTuesdaySong()
            // Only add if not already present (checking by title)
            if !allSongs.contains(where: { $0.title == tacoSong.title }) {
                // Create a mutable copy and insert taco song
                var updatedSongs = allSongs
                updatedSongs.insert(tacoSong, at: 0)
                allSongs = updatedSongs
                print("ViewModel: Added Taco Tuesday song")
            }
        }
        
        // Load playlists
        playlists = dataManager.loadPlaylists()
        print("ViewModel: Loaded \(playlists.count) playlists")
        
        // Refresh dynamic playlists
        refreshDynamicPlaylists()
    }
    
    func refreshAllSongs() {
        print("=== STARTING SONG LIBRARY REFRESH ===")
        
        // Force rediscovery of songs - bypass DataManager's cached data
        let songManager = SongManager.shared
        print("Forcing rediscovery of songs from bundle...")
        allSongs = songManager.discoverSongsInBundle()
        
        print("Discovered \(allSongs.count) songs")
        
        // Save the refreshed songs to DataManager
        print("Saving refreshed songs to DataManager...")
        dataManager.saveSongs(allSongs)
        
        // Refresh playlists
        playlists = dataManager.loadPlaylists()
        
        // Refresh dynamic playlists
        print("Refreshing dynamic playlists...")
        refreshDynamicPlaylists()
        
        // Reset the queue with the updated song list
        print("Updating queue with refreshed songs...")
        queueManager.playRandomPresetQueue()
        
        print("=== SONG LIBRARY REFRESH COMPLETE ===")
    }
    
    func refreshDynamicPlaylists() {
        recentlyPlayedSongs = dataManager.getRecentlyPlayedSongs()
        topHitsSongs = dataManager.getTopHitsSongs()
        favoriteSongs = dataManager.getFavoriteSongs()
    }
    
    // MARK: - Audio Session Notifications

    private func setupAudioSessionNotifications() {
        // Only set up when actually needed, not during initialization
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackFinished),
            name: .audioPlaybackFinished,
            object: nil
        )
        print("ViewModel: Audio playback observers set up")
    }
    
    @objc private func handlePlaybackFinished() {
        print("ViewModel: Audio playback finished notification received")
        
        // Only proceed if genuine playback has started
        // This prevents auto-skipping when initializing playback
        if hasPlaybackStarted {
            // Double check that we're not at the very beginning of the track
            if currentPlaybackTime > 1.0 || currentPlaybackTime >= duration - 1.0 {
                print("ViewModel: Confirmed genuine end of playback, moving to next song")
                DispatchQueue.main.async { [weak self] in
                    self?.nextSong()
                }
            } else {
                print("ViewModel: Ignoring playback finished near start of track - likely unintended")
            }
        } else {
            print("ViewModel: Ignoring playback finished notification - playback hasn't genuinely started yet")
        }
    }
    
    // MARK: - Song Playback
    
    func playSong(_ song: Song) {
        print("ViewModel: playSong called for \(song.title)")
        
        // Ensure audio session notifications are set up on first playback
        setupAudioSessionNotifications()
        
        // Reset playback state flags
        resetPlayCountTracking()
        hasPlaybackStarted = false
        
        // Track taco song state
        _ = isTacoSongPlaying
        
        // Stop current playback before starting a new one
        audioManager.stop()
        
        // Have QueueManager handle the song placement properly
        queueManager.playSongImmediately(song)
        
        // Update the current song immediately - this is important for the UI
        currentSong = song
        
        // Ensure the audio session is active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("ViewModel: Failed to activate audio session: \(error)")
        }
        
        // Start audio playback with a small delay to ensure proper initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            if self.audioManager.playSong(song) {
                self.isPlaying = true
                self.currentPlaybackTime = 0
                self.duration = song.duration
                
                // Mark that genuine playback has started
                self.hasPlaybackStarted = true
                
                // Update taco song state
                self.isTacoSongPlaying = song.title == "TACO TUESDAYYYYY"
                
                // Start play time tracking
                self.startPlayTimeTracking()
                
                // Refresh dynamic playlists
                self.refreshDynamicPlaylists()
                
                print("ViewModel: Successfully started playing: \(song.title)")
                
                // Post notification that playback has started
                NotificationCenter.default.post(name: NSNotification.Name("PlaybackStarted"), object: nil)
                
                // Print queue state for debugging
                self.printQueueState()
        } else {
                print("ViewModel: Failed to play song: \(song.title)")
                self.isPlaying = false
                // Ensure hasPlaybackStarted remains false on failure
                self.hasPlaybackStarted = false
            }
        }
    }
    
    // Track play time to count as a play after 10 seconds
    private func startPlayTimeTracking() {
        // Reset state
        playTimeThresholdReached = false
        
        // Cancel any existing timer
        currentSongPlayTimer?.invalidate()
        
        // Start new timer for 10 seconds
        currentSongPlayTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self, self.isPlaying, let currentSong = self.currentSong else { return }
            
            print("ViewModel: 10-second play threshold reached for song: \(currentSong.title)")
            self.playTimeThresholdReached = true
            
            // Now update the play count after 10 seconds
            self.dataManager.updatePlayCount(for: currentSong.id)
            
            // Refresh all song data across the app
            self.refreshAllSongData()
            
            // Notify observers about play count update
            self.notifyPlayCountUpdated()
        }
    }
    
    private func resetPlayCountTracking() {
        playTimeThresholdReached = false
        currentSongPlayTimer?.invalidate()
        currentSongPlayTimer = nil
    }
    
    // Update all song references in the app
    private func refreshAllSongData() {
        // Reload all songs to get fresh play counts
        allSongs = dataManager.loadSongs()
        
        // Refresh dynamic playlists
            refreshDynamicPlaylists()
            
        // Update current song reference to get fresh play count
        if let currentSong = currentSong {
            self.currentSong = allSongs.first(where: { $0.id == currentSong.id }) ?? currentSong
        }
    }
    
    @objc func togglePlayPause() {
        print("ViewModel: togglePlayPause called with isPlaying=\(isPlaying)")
        
        if isPlaying {
            audioManager.pause()
            isPlaying = false
            
            // Pause play time tracking by invalidating timer
            currentSongPlayTimer?.invalidate()
        } else {
            // If we have songs in queue but nothing is playing yet, play the first song or the current song
            if !queueManager.currentQueue.isEmpty {
                if currentSong == nil {
                    // This handles the case where the first song isn't playing correctly
                    print("ViewModel: Have songs in queue but nothing playing, starting first song")
                    playFirstSongInQueue()
                    return
                } else {
                    // We have a currentSong but it's not playing - use it directly
                    print("ViewModel: Resuming the current song: \(currentSong?.title ?? "unknown")")
                    if let song = currentSong {
                        // Ensure proper song position in queue
                        queueManager.ensureCorrectSongIsPlaying(song)
                        
                        // Try resuming existing playback first
                        if !audioManager.resume() {
                            // If resume fails, try playing the song again
                            print("ViewModel: Resume failed, restarting playback")
                            playSong(song)
                            return
                        }
                    }
                }
            } else {
                print("ViewModel: Queue is empty, nothing to play")
                return
            }
            
            // If we get here, audio was successfully resumed
                isPlaying = true
                
            // If we haven't reached the threshold yet, restart the timer
            if !playTimeThresholdReached {
                startPlayTimeTracking()
            }
        }
        
        // Notify if taco song
            if isTacoSongPlaying {
                NotificationCenter.default.post(
                    name: NSNotification.Name("TacoSongStateChanged"),
                    object: nil,
                    userInfo: ["isPlaying": isPlaying]
                )
        }
    }
    
    @objc func nextSong() {
        print("ViewModel: nextSong called")
        
        // Reset play count tracking
        resetPlayCountTracking()
        
        // First check if the queue is empty
        guard !queueManager.currentQueue.isEmpty else {
            print("ViewModel: Queue is empty, can't play next song")
            return
        }
        
        // Always stop current playback first
        audioManager.stop()
            
        // Get the next song from queue manager - with true queue behavior, current song will be removed
        if let nextSong = queueManager.nextSong() {
            print("ViewModel: Playing next song: \(nextSong.title)")
                
            // Ensure the audio session is active
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("ViewModel: Failed to activate audio session: \(error)")
            }
            
            // Start audio playback with a small delay to ensure proper initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                
                // Start audio playback
                if self.audioManager.playSong(nextSong) {
                    // Update ViewModel state
                    self.currentSong = nextSong
                    self.isPlaying = true
                    self.currentPlaybackTime = 0
                    self.duration = nextSong.duration
                    
                    // Start play time tracking
                    self.startPlayTimeTracking()
                    
                    // Update taco song state
                    self.isTacoSongPlaying = nextSong.title == "TACO TUESDAYYYYY"
                    
                    // Post notification that playback has started
                    NotificationCenter.default.post(name: NSNotification.Name("PlaybackStarted"), object: nil)
                    
                    // Print queue state for debugging
                    self.printQueueState()
                } else {
                    print("ViewModel: Failed to play next song: \(nextSong.title)")
                    self.isPlaying = false
                }
                }
            } else {
            print("ViewModel: No next song available in queue")
        }
    }

    @objc func previousSong() {
        print("ViewModel: previousSong called")
        
        // Reset play count tracking
        resetPlayCountTracking()
        
        // If we're more than 3 seconds into the song, restart it instead of going to previous
        if currentPlaybackTime > 3.0 {
            print("ViewModel: More than 3 seconds into song, restarting instead")
            seek(to: 0)
            return
        }
        
        // Always stop current playback first
        audioManager.stop()
        
        // Get the previous song from queue manager
        if let previousSong = queueManager.previousSong() {
            print("ViewModel: Playing previous song: \(previousSong.title)")
            
            // Ensure the audio session is active
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("ViewModel: Failed to activate audio session: \(error)")
            }
            
            // Start audio playback with a small delay to ensure proper initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                
                // Start audio playback
                if self.audioManager.playSong(previousSong) {
                    self.currentSong = previousSong
                    self.isPlaying = true
                    self.currentPlaybackTime = 0
                    self.duration = previousSong.duration
                    
                    // Start play time tracking
                    self.startPlayTimeTracking()
                
                // Update taco song state
                    self.isTacoSongPlaying = previousSong.title == "TACO TUESDAYYYYY"
                    
                    // Post notification that playback has started
                    NotificationCenter.default.post(name: NSNotification.Name("PlaybackStarted"), object: nil)
                    
                    // Print queue state for debugging
                    self.printQueueState()
                } else {
                    print("ViewModel: Failed to play previous song: \(previousSong.title)")
                    self.isPlaying = false
                }
            }
        } else {
            print("ViewModel: No previous song available in queue")
        }
    }
    
    func seek(to position: TimeInterval) {
        audioManager.seekTo(time: position)
        currentPlaybackTime = position
    }
    
    // MARK: - Queue Management
    
    func addToQueue(_ song: Song) {
        queueManager.addToQueue(song: song)
        
        // If this is the first song and nothing is playing, start playback
        if queueManager.currentQueue.count == 1 && currentSong == nil {
            playSong(song)
        }
    }
    
    func playNext(_ song: Song) {
        // Add song to play immediately after current
        queueManager.playAfterCurrent(song)
        
        // If nothing is playing, start this song
        if currentSong == nil {
            playSong(song)
        }
    }
    
    func removeFromQueue(at index: Int) {
        queueManager.removeFromQueue(at: index)
    }
    
    func clearQueue() {
        queueManager.clearQueue()
        
        // If audio is playing, stop it
        if isPlaying {
            audioManager.stop()
            isPlaying = false
            currentPlaybackTime = 0
            currentSong = nil
        }
    }
    
    func moveQueueItem(from sourceIndex: Int, to destinationIndex: Int) {
        queueManager.moveItem(from: sourceIndex, to: destinationIndex)
    }
    
    func toggleShuffle() {
        queueManager.toggleShuffle()
    }
    
    func cycleRepeatMode() {
        queueManager.cycleRepeatMode()
    }
    
    // MARK: - Random Queue
    
    func playRandomPresetQueue() {
        print("ViewModel: playRandomPresetQueue called")
        
        // First stop any current playback
        audioManager.stop()
        isPlaying = false
        
        // Generate a diverse random queue
        let allAvailableSongs = dataManager.loadSongs()
        
        if !allAvailableSongs.isEmpty {
            // Generate a good random mix
            let randomSongs = generateRandomMix(from: allAvailableSongs, count: 10)
            print("ViewModel: Generated random queue with \(randomSongs.count) songs")
            
            // Set the new queue
            queueManager.setQueue(songs: randomSongs)
            
            // Play the first song
            if let firstSong = queueManager.currentSongInQueue {
                playSong(firstSong)
            }
        } else {
            print("ViewModel: No songs available for random queue")
        }
    }
    
    // Create a diverse random mix of songs
    private func generateRandomMix(from songs: [Song], count: Int) -> [Song] {
        guard !songs.isEmpty else { return [] }
        
        // Get a diverse selection of artists first
        let artists = Set(songs.map { $0.artist })
        var randomMix: [Song] = []
        var remainingSongs = songs
        
        // First pass: Try to get one song from each artist to ensure variety
        for artist in artists {
            if randomMix.count >= count { break }
            
            if let artistSong = remainingSongs.first(where: { $0.artist == artist }) {
                randomMix.append(artistSong)
                remainingSongs.removeAll(where: { $0.id == artistSong.id })
            }
        }
        
        // Second pass: Fill remaining slots with random songs
        if randomMix.count < count {
            let remaining = count - randomMix.count
            let additionalSongs = Array(remainingSongs.shuffled().prefix(remaining))
            randomMix.append(contentsOf: additionalSongs)
        }
        
        // Final shuffle to mix up the order
        return randomMix.shuffled()
    }
    
    // MARK: - Playlist/Collection Playback
    
    // Play a playlist 
    func playPlaylist(_ playlist: Playlist, shuffled: Bool = false) {
        print("ViewModel: Playing playlist: \(playlist.name), shuffled: \(shuffled)")
        
        let songs = getSongs(for: playlist)
        if songs.isEmpty {
            print("ViewModel: Playlist is empty, nothing to play")
            return
        }
        
        // Set up the queue first
        queueManager.shuffleEnabled = shuffled
        queueManager.setQueue(songs: songs)
        
        // Then play the first song
        if let firstSong = queueManager.currentSongInQueue {
            playSong(firstSong)
        }
    }
    
    // Play artist songs
    func playArtistSongs(artist: String, shuffled: Bool = false) {
        print("ViewModel: Playing artist songs: \(artist), shuffled: \(shuffled)")
        
        let songs = allSongs.filter { $0.artist == artist }
        if songs.isEmpty {
            print("ViewModel: No songs found for artist")
            return
        }
        
        // Set up the queue first
        queueManager.shuffleEnabled = shuffled
        queueManager.setQueue(songs: songs)
        
        // Then play the first song
        if let firstSong = queueManager.currentSongInQueue {
            playSong(firstSong)
                }
    }
    
    // Play category songs
    func playCategorySongs(category: String, shuffled: Bool = false) {
        print("ViewModel: Playing category songs: \(category), shuffled: \(shuffled)")
        
        let songs = allSongs.filter { $0.categories.contains(category) }
        if songs.isEmpty {
            print("ViewModel: No songs found for category")
            return
        }
        
        // Set up the queue first
        queueManager.shuffleEnabled = shuffled
        queueManager.setQueue(songs: songs)
        
        // Then play the first song
        if let firstSong = queueManager.currentSongInQueue {
            playSong(firstSong)
        }
    }
    
    // MARK: - Playlist Management
    
    func getSongs(for playlist: Playlist) -> [Song] {
        return dataManager.getSongsForPlaylist(playlist)
    }
    
    // Updated to support custom image uploads and handle playlist creation correctly
    func createPlaylist(name: String, description: String, coverImage: String, customImage: UIImage? = nil) {
        print("ViewModel: Creating playlist: \(name)")
        
        // Validation
        guard !name.isEmpty else {
            print("ViewModel: Error - playlist name cannot be empty")
            return
        }
        
        let newPlaylist: Playlist
        
        if let image = customImage {
            // If we have a custom image, save it to disk and use its filename
            let imageFilename = saveCustomPlaylistImage(image, name: name)
            newPlaylist = Playlist(
            name: name,
            description: description,
                coverImage: imageFilename,
                songIDs: [],
                isSystem: false  // User-created playlists are not system playlists
            )
        } else {
            // Use the provided coverImage string (system image name)
            newPlaylist = Playlist(
                name: name,
                description: description,
                coverImage: coverImage,
                songIDs: [],
                isSystem: false  // User-created playlists are not system playlists
            )
        }
        
        // Save the playlist
        dataManager.updatePlaylist(newPlaylist)
        
        // Refresh playlists after creating a new one
        playlists = dataManager.loadPlaylists()
        
        // Notify about playlist creation
        NotificationCenter.default.post(
            name: NSNotification.Name("PlaylistCreated"),
            object: nil,
            userInfo: ["playlistID": newPlaylist.id]
        )
        
        print("ViewModel: Created playlist with ID: \(newPlaylist.id)")
    }
    
    // Helper method to save custom images
    private func saveCustomPlaylistImage(_ image: UIImage, name: String) -> String {
        // Create a unique filename based on the playlist name and current timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let safeName = name.replacingOccurrences(of: " ", with: "_")
                           .replacingOccurrences(of: "/", with: "_")
                           .replacingOccurrences(of: "\\", with: "_")
        let filename = "playlist_\(safeName)_\(timestamp).jpg"
        
        // Get documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access documents directory")
            return "playlist_default"
        }
        
        // Create playlists images directory if it doesn't exist
        let playlistImagesDirectory = documentsDirectory.appendingPathComponent("PlaylistImages")
        
        do {
            try FileManager.default.createDirectory(at: playlistImagesDirectory, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
        } catch {
            print("Error creating playlist images directory: \(error)")
        }
        
        // Create full path to save image
        let fileURL = playlistImagesDirectory.appendingPathComponent(filename)
        
        // Convert image to JPEG data with 80% quality
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
                print("ViewModel: Saved custom playlist image to \(fileURL.path)")
                return filename
            } catch {
                print("ViewModel: Error saving playlist image: \(error)")
            }
        }
        
        // Return default image name if save failed
        return "playlist_default"
    }
    
    // Method to update an existing playlist
    func updatePlaylist(id: UUID, name: String, description: String, coverImage: String? = nil, customImage: UIImage? = nil) {
        print("ViewModel: Updating playlist \(id)")
        
        // Get current playlists
        var playlists = dataManager.loadPlaylists()
        
        // Find the playlist to update
        guard let index = playlists.firstIndex(where: { $0.id == id }) else {
            print("ViewModel: Error - playlist with ID \(id) not found")
            return
        }
        
        // Protect system playlists from modification
        if playlists[index].isSystem {
            print("ViewModel: Error - cannot modify system playlist")
            return
        }
        
        // Validate playlist name
        guard !name.isEmpty else {
            print("ViewModel: Error - playlist name cannot be empty")
            return
        }
        
        // Keep the same song IDs
        let songIDs = playlists[index].songIDs
        
        // Determine the cover image to use
        let finalCoverImage: String
        
        if let image = customImage {
            // Save the custom image and use its filename
            finalCoverImage = saveCustomPlaylistImage(image, name: name)
            
            // If there was a previous custom image, try to delete it
            let previousCoverImage = playlists[index].coverImage
            deleteOldPlaylistImage(previousCoverImage)
        } else if let newCoverImage = coverImage {
            // Use the provided system image name
            finalCoverImage = newCoverImage
        } else {
            // Keep the existing cover image
            finalCoverImage = playlists[index].coverImage
        }
        
        // Create updated playlist
        let updatedPlaylist = Playlist(
            id: id,
            name: name,
            description: description,
            coverImage: finalCoverImage,
            songIDs: songIDs,
            isSystem: playlists[index].isSystem
        )
        
        // Update in the array
        playlists[index] = updatedPlaylist
        
        // Save updated playlists
        dataManager.savePlaylists(playlists)
        
        // Update view model data
        self.playlists = playlists
        
        // Notify observers that a playlist was updated
        NotificationCenter.default.post(
            name: NSNotification.Name("PlaylistUpdated"),
            object: nil,
            userInfo: ["playlistID": id]
        )
        
        print("ViewModel: Playlist updated successfully")
    }
    
    // Helper to delete old custom playlist images
    private func deleteOldPlaylistImage(_ filename: String) {
        // Only attempt to delete if it doesn't look like a system image name
        guard !filename.isEmpty && !filename.contains(".") && filename.count > 10 else {
            return
        }
        
        // Get documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // Build path to the image
        let playlistImagesDirectory = documentsDirectory.appendingPathComponent("PlaylistImages")
        let fileURL = playlistImagesDirectory.appendingPathComponent(filename)
        
        // Try to delete the file
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("ViewModel: Deleted old playlist image: \(filename)")
        } catch {
            print("ViewModel: Could not delete old playlist image: \(error)")
        }
    }
    
    // Improved method to add song to playlist with better error handling and success notification
    func addSongToPlaylist(songID: UUID, playlistID: UUID) {
        print("ViewModel: Adding song \(songID) to playlist \(playlistID)")
        
        // Get current playlists from data manager
        var playlists = dataManager.loadPlaylists()
        
        // Find the playlist to modify
        if let index = playlists.firstIndex(where: { $0.id == playlistID }) {
            // Check if this is a system playlist (Recent, Top Hits, Favorites)
            if playlists[index].isSystem {
                print("ViewModel: Cannot add song to system playlist")
                // Send notification about the failure
                NotificationCenter.default.post(
                    name: NSNotification.Name("PlaylistActionFailed"),
                    object: nil,
                    userInfo: [
                        "message": "Cannot modify system playlists",
                        "playlistID": playlistID
                    ]
                )
                return
            }
            
            // Check if song is already in playlist
            if !playlists[index].songIDs.contains(songID) {
                // Add the song
                playlists[index].songIDs.append(songID)
                
                // Save updated playlists
                dataManager.savePlaylists(playlists)
                
                // Update view model data
                self.playlists = playlists
                
                print("ViewModel: Song added to playlist successfully")
                
                // Notify observers that a playlist was updated
                NotificationCenter.default.post(
                    name: NSNotification.Name("PlaylistUpdated"),
                    object: nil,
                    userInfo: [
                        "playlistID": playlistID,
                        "action": "addSong",
                        "success": true
                    ]
                )
            } else {
                print("ViewModel: Song already in playlist")
                // Notify that the song is already in the playlist
                NotificationCenter.default.post(
                    name: NSNotification.Name("PlaylistActionInfo"),
                    object: nil,
                    userInfo: [
                        "message": "Song is already in this playlist",
                        "playlistID": playlistID
                    ]
                )
            }
        } else {
            print("ViewModel: Error - playlist with ID \(playlistID) not found")
            // Notify about the failure
            NotificationCenter.default.post(
                name: NSNotification.Name("PlaylistActionFailed"),
                object: nil,
                userInfo: [
                    "message": "Playlist not found",
                    "playlistID": playlistID
                ]
            )
        }
    }
    
    func removeSongFromPlaylist(songID: UUID, playlistID: UUID) {
        print("ViewModel: Removing song \(songID) from playlist \(playlistID)")
        
        // Get current playlists
        var playlists = dataManager.loadPlaylists()
        
        // Find the playlist to modify
        if let index = playlists.firstIndex(where: { $0.id == playlistID }) {
            // Check if this is a system playlist
            if playlists[index].isSystem {
                print("ViewModel: Cannot remove song from system playlist")
                // Send notification about the failure
                NotificationCenter.default.post(
                    name: NSNotification.Name("PlaylistActionFailed"),
                    object: nil,
                    userInfo: [
                        "message": "Cannot modify system playlists",
                        "playlistID": playlistID
                    ]
                )
                return
            }
            
            // Check if the song is actually in the playlist
            if playlists[index].songIDs.contains(songID) {
                // Remove the song
            playlists[index].songIDs.removeAll(where: { $0 == songID })
                
                // Save updated playlists
            dataManager.savePlaylists(playlists)
                
                // Update view model data
            self.playlists = playlists
                
                print("ViewModel: Song removed from playlist successfully")
                
                // Notify observers that a playlist was updated
                NotificationCenter.default.post(
                    name: NSNotification.Name("PlaylistUpdated"),
                    object: nil,
                    userInfo: [
                        "playlistID": playlistID,
                        "action": "removeSong",
                        "success": true
                    ]
                )
            } else {
                print("ViewModel: Song not found in playlist")
                // Notify that the song wasn't in the playlist
                NotificationCenter.default.post(
                    name: NSNotification.Name("PlaylistActionInfo"),
                    object: nil,
                    userInfo: [
                        "message": "Song is not in this playlist",
                        "playlistID": playlistID
                    ]
                )
            }
        } else {
            print("ViewModel: Error - playlist with ID \(playlistID) not found")
            // Notify about the failure
            NotificationCenter.default.post(
                name: NSNotification.Name("PlaylistActionFailed"),
                object: nil,
                userInfo: [
                    "message": "Playlist not found",
                    "playlistID": playlistID
                ]
            )
        }
    }
    
    func toggleFavorite(for songID: UUID) {
        dataManager.toggleFavorite(for: songID)
        
        // Update any references to the song
        allSongs = dataManager.loadSongs()
        refreshDynamicPlaylists()
        
        // Update currentSong if it's the one being toggled
        if let currentSong = currentSong, currentSong.id == songID {
            self.currentSong = allSongs.first(where: { $0.id == songID })
        }
    }
    
    // MARK: - AD Management
    
    func showRandomAd() {
        // Use the TacoTuesday ads on Tuesday with higher probability
        if tacoManager.isTacoTuesday && Double.random(in: 0...1) < 0.4 {
            // 40% chance to show a taco ad on Tuesday
            currentAd = tacoManager.getTacoAds().randomElement()
        } else {
            // Use the existing AnthonyDavisAd.randomAd() method
            currentAd = AnthonyDavisAd.randomAd()
        }
        
        showingAd = true
    }
    
    func dismissAd() {
        showingAd = false
    }
    
    // MARK: - Timers and Notifications
    
    private func setupTimers() {
        // Update playback time
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            let newTime = self.audioManager.currentTime
            self.currentPlaybackTime = newTime
            
            // Check if current playback is near the end of the song
            if let duration = self.currentSong?.duration, 
               newTime >= duration - 0.5 && 
               self.currentPlaybackTime < duration - 0.5 {
                print("ViewModel: Song is about to end based on timer (\(newTime)/\(duration))")
            }
        }
        
        // Random AD timer - keep as is
        adTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying, !self.showingAd else { return }
            
            // 20% chance to show an ad
            if Double.random(in: 0...1) < 0.2 && !self.isConnectedToCarPlay() {
                self.showRandomAd()
            }
        }
    }
    
    private func setupNotifications() {
        // Listen for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Listen for app entering background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Listen for notifications about the first song in queue
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQueueFirstSongReady),
            name: NSNotification.Name("QueueFirstSongReady"),
            object: nil
        )
    }
    
    @objc private func handleAppDidBecomeActive() {
        // Refresh data when app becomes active
        loadData()
        
        // Update playback state
        isPlaying = audioManager.isPlaying
        currentPlaybackTime = audioManager.currentTime
        
        // Check if taco song state needs to be updated
        if let song = currentSong, song.title == "TACO TUESDAYYYYY" {
            if isTacoSongPlaying != isPlaying {
                isTacoSongPlaying = isPlaying
                NotificationCenter.default.post(
                    name: NSNotification.Name("TacoSongStateChanged"),
                    object: nil,
                    userInfo: ["isPlaying": isPlaying]
                )
            }
        }
    }
    
    @objc private func handleAppDidEnterBackground() {
        // Make sure data is saved
        if let currentSong = currentSong {
            dataManager.updatePlayCount(for: currentSong.id)
        }
    }
    
    @objc private func handleQueueFirstSongReady(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let song = userInfo["song"] as? Song else {
            return
        }
        
        print("ViewModel: Received notification about first song in queue: \(song.title)")
        
        // Don't automatically start playing - this should be user-initiated
        // But we can at least update the current song reference if needed
        if currentSong == nil || currentSong?.id != song.id {
            currentSong = song
            print("ViewModel: Updated current song reference to: \(song.title)")
        }
        
        // Could prepare the audio here if needed for faster playback when requested
        audioManager.prepareAudio(for: song)
    }
    
    // MARK: - CarPlay Support
    
    // Function to get a random song
    func playRandomSong() {
        if let randomSong = allSongs.randomElement() {
            playSong(randomSong)
        }
    }
    
    // Helper to determine if connected to CarPlay
    func isConnectedToCarPlay() -> Bool {
        // Check if we're in CarPlay mode
        #if targetEnvironment(simulator)
        return false
        #else
        return MPMusicPlayerController.systemMusicPlayer.playbackState == .playing &&
               UIApplication.shared.connectedScenes.contains(where: { $0.activationState == .foregroundActive &&
                                                                   $0 is UIWindowScene &&
                                                                   $0.session.role == .carTemplateApplication })
        #endif
    }
    
    // Get the songs for playlist by ID
    func getSongs(for playlistID: UUID) -> [Song] {
        if let playlist = playlists.first(where: { $0.id == playlistID }) {
            return getSongs(for: playlist)
        }
        return []
    }
    
    // Get playlist by ID
    func getPlaylist(by id: UUID) -> Playlist? {
        return playlists.first(where: { $0.id == id })
    }
    
    // MARK: - Song of the Day
    
    // Get or generate song of the day
    func getSongOfTheDay() -> Song? {
        // On Tuesdays, possibility to feature the Taco Tuesday song
        if tacoManager.isTacoTuesday && Double.random(in: 0...1) < 0.6 {
            // 60% chance on Tuesdays to feature Taco Tuesday song
            return tacoManager.createTacoTuesdaySong()
        }
        
        // Normal song of the day logic
        let todayKey = getTodayDateKey()
        
        if let storedSongID = UserDefaults.standard.string(forKey: "songOfTheDay_\(todayKey)"),
           let uuid = UUID(uuidString: storedSongID),
           let song = allSongs.first(where: { $0.id == uuid }) {
            return song
        } else {
            // New day, pick a random song
            guard let randomSong = allSongs.randomElement() else { return nil }
            
            UserDefaults.standard.set(randomSong.id.uuidString, forKey: "songOfTheDay_\(todayKey)")
            return randomSong
        }
    }
    
    private func getTodayDateKey() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }
    
    // MARK: - Information Events
    
    // Get song title for notification display
    func getSongDisplayText() -> String {
        guard let song = currentSong else { return "No song playing" }
        return "\(song.title) - \(song.artist)"
    }
    
    // Debug helper to print queue state
    func printQueueState() {
        print("\n=== QUEUE STATE ===")
        print("Queue size: \(queueManager.currentQueue.count)")
        print("Current index: \(queueManager.queueIndex)")
        print("Current song in queue: \(queueManager.currentSongInQueue?.title ?? "None")")
        print("Current song in ViewModel: \(currentSong?.title ?? "None")")
        print("Is playing: \(isPlaying)")
        print("Shuffle enabled: \(queueManager.shuffleEnabled)")
        print("Repeat mode: \(queueManager.repeatMode)")
        
        print("\nQueue contents:")
        for (index, song) in queueManager.currentQueue.enumerated() {
            let marker = index == queueManager.queueIndex ? " ← CURRENT" : ""
            print("\(index): \(song.title) by \(song.artist)\(marker)")
        }
        print("=== END QUEUE STATE ===\n")
    }
    
    // Add a notification for play count updates
    private func notifyPlayCountUpdated() {
        print("ViewModel: Notifying about play count update")
        // Send song ID with notification so views can update specific songs
        if let songID = currentSong?.id {
            NotificationCenter.default.post(
                name: NSNotification.Name("PlayCountUpdated"),
                object: nil,
                userInfo: ["songID": songID]
            )
        } else {
            NotificationCenter.default.post(
                name: NSNotification.Name("PlayCountUpdated"),
                object: nil
            )
        }
    }
    
    // MARK: - Media Playback Controls
    
    // These functions are made public to support CarPlay integration
    func resumePlayback() {
        if !isPlaying, audioManager.resume() {
            isPlaying = true
            
            // Restart play time tracking if needed
            if currentSong != nil && currentPlaybackTime < currentPlaybackTimeThreshold {
                startPlayTimeTracking()
            }
        }
    }
    
    func pausePlayback() {
        if isPlaying {
            audioManager.pause()
            isPlaying = false
            
            // Pause play time tracking by invalidating timer
            currentSongPlayTimer?.invalidate()
        }
    }
    
    // Skip to the next song in queue
    func playNextSong() {
        // Use the correct nextSong method from QueueManager
        if let nextSong = queueManager.nextSong() {
            playSong(nextSong)
        }
    }
    
    // Go back to previous song
    func playPreviousSong() {
        // Use the correct previousSong method from QueueManager
        if let previousSong = queueManager.previousSong() {
            playSong(previousSong)
        }
    }
    
    // Seek to a specific position
    func seekTo(position: TimeInterval) {
        audioManager.seekTo(time: position)
    }
    
    // Toggle shuffle mode
    var shuffleEnabled: Bool {
        get { queueManager.shuffleEnabled }
        set { queueManager.shuffleEnabled = newValue }
    }
    
    // Repeat modes
    enum RepeatMode {
        case off, all, one
    }
    
    private var _repeatMode: RepeatMode = .off
    
    var repeatMode: RepeatMode {
        get { _repeatMode }
        set { _repeatMode = newValue }
    }
    
    func toggleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }
    
    // Update playback time periodically
    private func setupPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.currentPlaybackTime = self.audioManager.currentTime
            
            // Check if song has ended and we need to play the next one
            if self.currentPlaybackTime >= self.duration - 0.5 {
                // Only proceed to next song if we're near the end and not paused
                self.nextSong()
            }
        }
    }
    
    // MARK: - First Song Fix
    
    /// Play the first song in the queue with special handling to fix initialization issues
    func playFirstSongInQueue() {
        print("ViewModel: Explicitly playing first song in queue")
        
        // Reset playback flags
        hasPlaybackStarted = false
        
        // Check if queue is empty and try to generate one if needed
        if queueManager.currentQueue.isEmpty {
            print("ViewModel: Queue is empty, generating a random queue first")
            
            // First do a one-time refresh to ensure we have the latest data
            // Only do this if forced to generate a new queue
            dataManager.forceRefreshAllSongs()
            
            queueManager.playRandomPresetQueue()
            
            // Still empty? Nothing we can do
            if queueManager.currentQueue.isEmpty {
                print("ViewModel: Failed to generate queue, no songs available")
                return
            }
        }
        
        // Ensure queue index is at the beginning
        if queueManager.queueIndex != 0 {
            print("ViewModel: Resetting queue index to 0")
            _ = queueManager.jumpToSong(at: 0)
        }
        
        // Get the first song with a proper delay to ensure audio system is ready
        if let firstSong = queueManager.currentSongInQueue {
            print("ViewModel: Starting playback of first song: \(firstSong.title)")
            
            // Set the current song immediately to prevent UI inconsistencies
            currentSong = firstSong
            
            // Small delay to ensure audio system is fully initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                
                // We use playSong directly to ensure proper playback
                if self.audioManager.playSong(firstSong) {
                    self.isPlaying = true
                    self.currentPlaybackTime = 0
                    self.duration = firstSong.duration
                    
                    // Mark that playback has genuinely started
                    self.hasPlaybackStarted = true
                    
                    // Update taco song state
                    self.isTacoSongPlaying = firstSong.title == "TACO TUESDAYYYYY"
                    
                    // Start play time tracking
                    self.startPlayTimeTracking()
                    
                    print("ViewModel: Successfully started playing first song: \(firstSong.title)")
                    NotificationCenter.default.post(name: NSNotification.Name("PlaybackStarted"), object: nil)
                    
                    // Print queue state for debugging
                    self.printQueueState()
                } else {
                    print("ViewModel: Failed to play first song: \(firstSong.title)")
                    self.isPlaying = false
                    self.hasPlaybackStarted = false
                }
            }
        } else {
            print("ViewModel: Failed to get first song from queue")
        }
    }
    
    private func setupQueueBinding() {
        // Set up binding between currentSong and queue manager's currentSongInQueue
        queueManager.$currentQueue
            .combineLatest(queueManager.$queueIndex)
            .map { queue, index -> Song? in
                guard !queue.isEmpty, index >= 0, index < queue.count else {
                    return nil
                }
                return queue[index]
            }
            .sink { [weak self] song in
                if self?.currentSong?.id != song?.id {
                    print("ViewModel: Current song changed to: \(song?.title ?? "nil")")
                    self?.currentSong = song
                }
            }
            .store(in: &cancellables)
    }
}
