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
    
    init() {
        // First, do a one-time full refresh of songs on app launch
        dataManager.forceRefreshAllSongs()
        
        // Then load the data (which will now use the cached results)
        loadData()
        setupTimers()
        setupNotifications()
        
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
                    self?.currentSong = song
                }
                .store(in: &cancellables)
            
        // IMPORTANT: Always ensure there's a random queue available by default
        queueManager.generateRandomPresetQueue()
        print("ViewModel: Initialized with random queue containing \(queueManager.currentQueue.count) songs")
            
        // Prepare the first song in the queue without playing it
        if let firstSong = queueManager.currentSongInQueue {
            audioManager.prepareAudio(for: firstSong)
            print("ViewModel: Prepared first song in queue: \(firstSong.title)")
        }
    }
    
    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    // MARK: - Song Playback
    
    func playSong(_ song: Song) {
        print("ViewModel: playSong called for \(song.title)")
        
        // Check if we're transitioning to or from the taco song
        let wasTacoSong = isTacoSongPlaying
        let isTacoSong = song.title == "TACO TUESDAYYYYY"
        
        if currentSong?.id == song.id && isPlaying {
            // Already playing this song, do nothing
            print("ViewModel: Already playing this song, doing nothing")
            return
        }
        
        // Important queue management section
        let songAlreadyInQueue = queueManager.currentQueue.contains(where: { $0.id == song.id })
        print("ViewModel: Song already in queue: \(songAlreadyInQueue)")
        
        if songAlreadyInQueue {
            // Song is already in queue, jump to it
            if let index = queueManager.currentQueue.firstIndex(where: { $0.id == song.id }) {
                print("ViewModel: Song already in queue, jumping to index \(index)")
                // This should just change the index, not modify the queue
                queueManager.jumpToSong(at: index)
            }
        } else {
            // Only create a new queue if the current one is empty
            if queueManager.currentQueue.isEmpty {
                print("ViewModel: Empty queue, creating new queue with song")
                queueManager.setQueue(songs: [song])
            } else {
                // Otherwise, add to the existing queue and jump to it
                print("ViewModel: Adding song to existing queue")
                queueManager.addToQueue(song: song)
                if let index = queueManager.currentQueue.firstIndex(where: { $0.id == song.id }) {
                    queueManager.jumpToSong(at: index)
                }
            }
        }
        
        // Set current song
        currentSong = song
        
        // Update audio playback
        if audioManager.playSong(song) {
            isPlaying = true
            currentPlaybackTime = 0
            duration = song.duration
            
            // Update taco song state
            isTacoSongPlaying = isTacoSong
            
            // Publish notification for taco song state change
            if wasTacoSong != isTacoSongPlaying {
                NotificationCenter.default.post(
                    name: NSNotification.Name("TacoSongStateChanged"),
                    object: nil,
                    userInfo: ["isPlaying": isPlaying]
                )
            }
            
            // Ensure the queue manager knows which song is playing
            queueManager.ensureCorrectSongIsPlaying(song)
            
            // Update play count in the data store
            print("ViewModel: Updating play count for song: \(song.title), ID: \(song.id)")
            dataManager.updatePlayCount(for: song.id)
            
            // Refresh the dynamic playlists
            refreshDynamicPlaylists()
            
            // Post notification for CarPlay UI to update
            NotificationCenter.default.post(name: NSNotification.Name("SongChanged"), object: nil)
            
            // Random chance to show an ad (but not in CarPlay mode)
            if Double.random(in: 0...1) < 0.2 && !isConnectedToCarPlay() { // 20% chance
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.showRandomAd()
                }
            }
        } else {
            print("ViewModel: Failed to play song: \(song.title)")
        }
    }
    
    func togglePlayPause() {
        print("ViewModel: togglePlayPause called with isPlaying=\(isPlaying)")
        
        // If we have a song selected but it's not playing yet
        if !isPlaying && currentSong != nil {
            print("ViewModel: Starting playback of song: \(currentSong!.title)")
            
            // Check if we need to update the queue index to match this song
            let songInQueue = queueManager.currentQueue.contains(where: { $0.id == currentSong!.id })
            if songInQueue && queueManager.currentSongInQueue?.id != currentSong!.id {
                // Ensure the queue knows which song should be playing
                queueManager.ensureCorrectSongIsPlaying(currentSong!)
                print("ViewModel: Updated queue to match current song")
            }
            
            // Start playback using audioManager directly
            if audioManager.playSong(currentSong!) {
                isPlaying = true
                
                // Update play count (since this is starting a new play session)
                dataManager.updatePlayCount(for: currentSong!.id)
                refreshDynamicPlaylists()
                
                print("ViewModel: Started playback successfully")
            }
            return
        }
        
        // Normal toggle behavior for ongoing playback
        if audioManager.togglePlayPause() {
            isPlaying.toggle()
            print("ViewModel: Toggled playback to isPlaying=\(isPlaying)")
            
            // If the taco song state changes, notify observers
            if isTacoSongPlaying {
                NotificationCenter.default.post(
                    name: NSNotification.Name("TacoSongStateChanged"),
                    object: nil,
                    userInfo: ["isPlaying": isPlaying]
                )
            }
        } else {
            print("ViewModel: Failed to toggle playback state")
        }
    }
    
    func nextSong() {
        print("ViewModel: nextSong called")
        
        // First, check if there's anything to play next
        guard !queueManager.currentQueue.isEmpty else {
            print("ViewModel: Queue is empty, can't play next song")
            return
        }
        
        // Add a brief delay to ensure proper audio handling
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Get the next song from queue manager
            if let nextSong = self.queueManager.nextSong() {
                print("ViewModel: Moving to next song: \(nextSong.title)")
                
                // Stop current playback first
                self.audioManager.stop()
                
                // Then start the new song
                if self.audioManager.playSong(nextSong) {
                    // Update ViewModel state
                    self.currentSong = nextSong
                    self.isPlaying = true
                    self.currentPlaybackTime = 0
                    self.duration = nextSong.duration
                    
                    // Update taco song state
                    self.isTacoSongPlaying = nextSong.title == "TACO TUESDAYYYYY"
                    
                    // Update play count
                    self.dataManager.updatePlayCount(for: nextSong.id)
                    
                    // Refresh dynamic playlists
                    self.refreshDynamicPlaylists()
                    
                    print("ViewModel: Successfully started playing next song")
                } else {
                    print("ViewModel: Failed to play next song: \(nextSong.title)")
                }
            } else {
                print("ViewModel: No next song available - end of queue")
                // We've reached the end of the queue with repeat off
                if self.queueManager.repeatMode == .all && !self.queueManager.currentQueue.isEmpty {
                    // With repeat all, go back to the beginning
                    self.queueManager.queueIndex = 0
                    if let firstSong = self.queueManager.currentSongInQueue {
                        print("ViewModel: Looping to first song in queue: \(firstSong.title)")
                        self.playSong(firstSong)
                    }
                }
            }
            
            // Log current queue state
            print("ViewModel: Queue now at index \(self.queueManager.queueIndex) of \(self.queueManager.currentQueue.count)")
        }
    }

    func previousSong() {
        print("ViewModel: previousSong called")
        let wasTacoSong = isTacoSongPlaying
        
        // If we're more than 3 seconds into the song, restart it instead of going to previous
        if currentPlaybackTime > 3.0 {
            print("ViewModel: More than 3 seconds into song, restarting instead")
            seek(to: 0)
            return
        }
        
        if let previousSong = queueManager.previousSong() {
            // Log the actual previous song title
            print("ViewModel: Moving to previous song: \(previousSong.title)")
            
            // The queue index has already been updated in queueManager.previousSong()
            // We just need to start playback of this song
            if audioManager.playSong(previousSong) {
                currentSong = previousSong
                isPlaying = true
                currentPlaybackTime = 0
                duration = previousSong.duration
                
                // Update taco song state
                isTacoSongPlaying = previousSong.title == "TACO TUESDAYYYYY"
                
                // Don't update play count for previous song since the user is just going back
                
                // Post notification for CarPlay UI to update
                NotificationCenter.default.post(name: NSNotification.Name("SongChanged"), object: nil)
            }
        } else {
            print("ViewModel: No previous song available")
        }
        
        // Check if the taco song state changed
        if wasTacoSong != isTacoSongPlaying {
            NotificationCenter.default.post(
                name: NSNotification.Name("TacoSongStateChanged"),
                object: nil,
                userInfo: ["isPlaying": isPlaying]
            )
        }
        
        // Debug the queue state after moving
        print("ViewModel: Queue now at index \(queueManager.queueIndex) of \(queueManager.currentQueue.count)")
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
    
    func removeFromQueue(at index: Int) {
        queueManager.removeFromQueue(at: index)
    }
    
    func clearQueue() {
        queueManager.clearQueue()
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
    
    // Add this to your ViewModel
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
    
    func playRandomPresetQueue() {
        print("ViewModel: Playing random preset queue")
        
        // First stop any current playback completely
        audioManager.stop()
        isPlaying = false
        currentPlaybackTime = 0
        
        // Load the latest songs to ensure we have the most up-to-date list
        let allSongs = dataManager.loadSongs()
        
        if !allSongs.isEmpty {
            // Generate a random queue with 10 songs
            let randomQueue = Array(allSongs.shuffled().prefix(10))
            
            // Set the new queue
            queueManager.setQueue(songs: randomQueue)
            print("QueueManager: Created new random queue with \(randomQueue.count) songs")
            
            // Get the first song
            if let firstSong = queueManager.currentSongInQueue {
                print("ViewModel: Playing first song from new random queue: \(firstSong.title)")
                
                // Rather than using playSong, we'll play it more directly to avoid queue confusion
                currentSong = firstSong
                
                // Explicitly play the audio
                if audioManager.playSong(firstSong) {
                    isPlaying = true
                    currentPlaybackTime = 0
                    duration = firstSong.duration
                    
                    // Check if it's a taco song
                    isTacoSongPlaying = firstSong.title == "TACO TUESDAYYYYY"
                    
                    // Update play count
                    dataManager.updatePlayCount(for: firstSong.id)
                    
                    // Refresh dynamic playlists
                    refreshDynamicPlaylists()
                    
                    print("ViewModel: Successfully started playing random queue with first song: \(firstSong.title)")
                } else {
                    print("ViewModel: Failed to play first song in random queue: \(firstSong.title)")
                }
            } else {
                print("ViewModel: Error - Random queue is empty")
            }
        } else {
            print("ViewModel: No songs available for random queue")
        }
        
        // Debug the queue state after setup
        printQueueState()
    }
    
    // MARK: - Playlist Management
    
    func getSongs(for playlist: Playlist) -> [Song] {
        return dataManager.getSongsForPlaylist(playlist)
    }
    
    func createPlaylist(name: String, description: String, coverImage: String) {
        let newPlaylist = Playlist(
            name: name,
            description: description,
            coverImage: coverImage
        )
        
        dataManager.updatePlaylist(newPlaylist)
        playlists = dataManager.loadPlaylists()
    }
    
    func addSongToPlaylist(songID: UUID, playlistID: UUID) {
        var playlists = dataManager.loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlistID }) {
            if !playlists[index].songIDs.contains(songID) {
                playlists[index].songIDs.append(songID)
                dataManager.savePlaylists(playlists)
                self.playlists = playlists
            }
        }
    }
    
    func removeSongFromPlaylist(songID: UUID, playlistID: UUID) {
        var playlists = dataManager.loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlistID }) {
            playlists[index].songIDs.removeAll(where: { $0 == songID })
            dataManager.savePlaylists(playlists)
            self.playlists = playlists
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
            
            self.currentPlaybackTime = self.audioManager.currentTime
            
            // Check if song ended
            if self.currentPlaybackTime >= self.duration {
                self.nextSong()
            }
        }
        
        // Random AD timer - show an ad every 30-90 seconds
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
    
    // MARK: - CarPlay Support
    
    // Function to get a random song
    func playRandomSong() {
        if let randomSong = allSongs.randomElement() {
            playSong(randomSong)
        }
    }
    
    // Play content methods with queue integration
    func playPlaylist(_ playlist: Playlist, shuffled: Bool = false) {
        let songs = getSongs(for: playlist)
        if !songs.isEmpty {
            queueManager.shuffleEnabled = shuffled
            queueManager.setQueue(songs: songs)
            if let firstSong = queueManager.currentSongInQueue {
                playSong(firstSong)
            }
        }
    }
    
    func playArtistSongs(artist: String, shuffled: Bool = false) {
        let songs = allSongs.filter { $0.artist == artist }
        if !songs.isEmpty {
            queueManager.shuffleEnabled = shuffled
            queueManager.setQueue(songs: songs)
            if let firstSong = queueManager.currentSongInQueue {
                playSong(firstSong)
            }
        }
    }
    
    func playCategorySongs(category: String, shuffled: Bool = false) {
        let songs = allSongs.filter { $0.categories.contains(category) }
        if !songs.isEmpty {
            queueManager.shuffleEnabled = shuffled
            queueManager.setQueue(songs: songs)
            if let firstSong = queueManager.currentSongInQueue {
                playSong(firstSong)
            }
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
}
