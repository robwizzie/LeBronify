//
//  QueueManager.swift
//  LeBronify
//
//  Created by Robert Wiscount on 4/3/25.
//

import Foundation
import Combine

class QueueManager: ObservableObject {
    // Published properties for UI updates
    @Published var currentQueue: [Song] = []
    @Published var queueIndex: Int = 0
    @Published var shuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    
    // History tracking
    private var playHistory: [Song] = []
    
    // Reference to song manager for access to all songs
    private let songManager = SongManager.shared
    private let dataManager = DataManager.shared
    
    // Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    enum RepeatMode {
        case off
        case all
        case one
    }
    
    init() {
        // Generate the random preset queue on initialization
        generateRandomPresetQueue()
        print("QueueManager: Initialized with \(currentQueue.count) songs in queue")
    }
    
    // MARK: - Queue Management
    
    func prepareRandomQueue() -> Song? {
        // Generate a new random queue
        let allSongs = dataManager.loadSongs()
        if allSongs.isEmpty {
            print("QueueManager: No songs available for random queue")
            return nil
        }
        
        let randomQueue = Array(allSongs.shuffled().prefix(10))
        print("QueueManager: Generated random queue with \(randomQueue.count) songs")
        
        // Set the queue
        currentQueue = randomQueue
        queueIndex = 0
        
        // Return the first song that should be prepared (but not played yet)
        return currentSongInQueue
    }
    
    /// Replace the current queue with new songs
    func setQueue(songs: [Song], startingAt index: Int = 0) {
        if shuffleEnabled {
            // If shuffle is on, shuffle the songs but keep the first song at index
            var shuffledSongs = songs
            if !shuffledSongs.isEmpty && index < shuffledSongs.count {
                let firstSong = shuffledSongs.remove(at: index)
                shuffledSongs.shuffle()
                shuffledSongs.insert(firstSong, at: 0)
                currentQueue = shuffledSongs
                queueIndex = 0
            } else {
                shuffledSongs.shuffle()
                currentQueue = shuffledSongs
                queueIndex = 0
            }
        } else {
            currentQueue = songs
            queueIndex = index
        }
        
        print("QueueManager: Set queue with \(songs.count) songs, starting at index \(queueIndex)")
    }
    
    /// Add songs to the end of the queue
    func addToQueue(songs: [Song]) {
        currentQueue.append(contentsOf: songs)
        print("QueueManager: Added \(songs.count) songs to queue")
    }
    
    /// Add a single song to the end of the queue
    func addToQueue(song: Song) {
        currentQueue.append(song)
        print("QueueManager: Added song to queue: \(song.title)")
    }
    
    /// Add a song to play next (right after the current song)
    func playNext(song: Song) {
        if currentQueue.isEmpty {
            currentQueue = [song]
            queueIndex = 0
            print("QueueManager: Queue was empty, added song as first: \(song.title)")
        } else if queueIndex < currentQueue.count - 1 {
            currentQueue.insert(song, at: queueIndex + 1)
            print("QueueManager: Added song to play next: \(song.title)")
        } else {
            currentQueue.append(song)
            print("QueueManager: Added song to end of queue: \(song.title)")
        }
    }
    
    /// Remove a song from the queue without affecting the currently playing song
    func removeFromQueue(at index: Int) {
        guard index < currentQueue.count else { return }
        
        // Don't allow removing the currently playing song
        if index == queueIndex {
            print("QueueManager: Cannot remove currently playing song at index \(index)")
            return
        }
        
        // Get current song ID before modifying the queue to maintain playback
        let currentSongID = currentSongInQueue?.id
        
        // Adjust queue index if removing a song before the current one
        if index < queueIndex {
            queueIndex -= 1
        }
        
        let removedSong = currentQueue.remove(at: index)
        print("QueueManager: Removed song from queue: \(removedSong.title)")
        
        // If we removed the last song and the index is now out of bounds, adjust it
        if queueIndex >= currentQueue.count && !currentQueue.isEmpty {
            queueIndex = currentQueue.count - 1
        }
        
        // Verify the current song didn't change
        if let currentSongID = currentSongID,
           let newIndex = currentQueue.firstIndex(where: { $0.id == currentSongID }) {
            queueIndex = newIndex
        }
    }
    
    /// Reorder the queue by moving a song without affecting currently playing
    func moveItem(from source: Int, to destination: Int) {
        guard source != queueIndex else {
            print("QueueManager: Cannot move currently playing song")
            return
        }
        
        // Store the current playing song ID
        let currentSongID = currentSongInQueue?.id
        
        // Move the item in the array
        let item = currentQueue.remove(at: source)
        currentQueue.insert(item, at: destination)
        print("QueueManager: Moved song from index \(source) to \(destination)")
        
        // Update the queue index to keep pointing to the same song
        if let currentSongID = currentSongID,
           let newIndex = currentQueue.firstIndex(where: { $0.id == currentSongID }) {
            queueIndex = newIndex
        }
    }
    
    /// Clear the queue except for the currently playing song
    func clearQueue() {
        if let currentSong = currentSongInQueue {
            currentQueue = [currentSong]
            queueIndex = 0
            print("QueueManager: Cleared queue, kept only current song: \(currentSong.title)")
        } else {
            currentQueue = []
            queueIndex = 0
            print("QueueManager: Cleared entire queue")
        }
    }
    
    // MARK: - Playback Control
    
    /// Get the current song in the queue
    var currentSongInQueue: Song? {
        guard !currentQueue.isEmpty, queueIndex >= 0, queueIndex < currentQueue.count else {
            return nil
        }
        return currentQueue[queueIndex]
    }
    
    /// Move to the next song in the queue
    func nextSong() -> Song? {
        guard !currentQueue.isEmpty else { return nil }
        
        // Add current song to history
        if let currentSong = currentSongInQueue {
            playHistory.append(currentSong)
            // Limit history size
            if playHistory.count > 50 {
                playHistory.removeFirst()
            }
        }
        
        switch repeatMode {
        case .off:
            if queueIndex < currentQueue.count - 1 {
                queueIndex += 1
                print("QueueManager: Moving to next song at index \(queueIndex)")
                return currentSongInQueue
            } else {
                print("QueueManager: End of queue reached with repeat off")
                return nil // End of queue
            }
            
        case .all:
            if queueIndex < currentQueue.count - 1 {
                queueIndex += 1
                print("QueueManager: Moving to next song at index \(queueIndex)")
            } else {
                queueIndex = 0 // Loop back to start
                print("QueueManager: Looping back to start of queue with repeat all")
            }
            return currentSongInQueue
            
        case .one:
            // Don't change the index, replay the same song
            print("QueueManager: Repeating current song with repeat one")
            return currentSongInQueue
        }
    }
    
    /// Move to the previous song in the queue
    func previousSong() -> Song? {
        guard !currentQueue.isEmpty else { return nil }
        
        switch repeatMode {
        case .off, .all:
            if queueIndex > 0 {
                queueIndex -= 1
                print("QueueManager: Moving to previous song at index \(queueIndex)")
                return currentSongInQueue
            } else if !playHistory.isEmpty && repeatMode == .off {
                // Go back to the last song in history
                let lastSong = playHistory.removeLast()
                print("QueueManager: Going back to song from history: \(lastSong.title)")
                playNext(song: lastSong)
                queueIndex -= 1 // Move to the song we just inserted
                return currentSongInQueue
            } else if repeatMode == .all {
                // Wrap around to the end
                queueIndex = currentQueue.count - 1
                print("QueueManager: Wrapping to end of queue with repeat all")
                return currentSongInQueue
            } else {
                print("QueueManager: Already at first song, staying there")
                return currentSongInQueue // Stay on first song
            }
            
        case .one:
            // Don't change the index, replay the same song
            print("QueueManager: Repeating current song with repeat one")
            return currentSongInQueue
        }
    }
    
    /// Jump to a specific position in the queue
    func jumpToSong(at index: Int) -> Song? {
        guard index >= 0, index < currentQueue.count else { return nil }
        
        // Add current song to history
        if let currentSong = currentSongInQueue {
            playHistory.append(currentSong)
        }
        
        queueIndex = index
        print("QueueManager: Jumped to song at index \(index): \(currentQueue[index].title)")
        return currentSongInQueue
    }
    
    /// Ensure the current song index matches the provided song
    func ensureCorrectSongIsPlaying(_ song: Song) {
        print("QueueManager: Ensuring correct song is playing: \(song.title)")
        
        // If the queue is empty, add this song
        if currentQueue.isEmpty {
            print("QueueManager: Queue is empty, adding song")
            currentQueue = [song]
            queueIndex = 0
            return
        }
        
        // Check if song is in queue
        if !currentQueue.contains(where: { $0.id == song.id }) {
            print("QueueManager: Song not in queue, adding and making current")
            // Add it to the queue and make it current
            if queueIndex < currentQueue.count {
                // Insert after current song
                currentQueue.insert(song, at: queueIndex + 1)
                queueIndex += 1
            } else {
                // Add to end
                currentQueue.append(song)
                queueIndex = currentQueue.count - 1
            }
            return
        }
        
        // If the current index doesn't match the song, find and set the correct index
        if queueIndex < 0 || queueIndex >= currentQueue.count || currentQueue[queueIndex].id != song.id {
            if let correctIndex = currentQueue.firstIndex(where: { $0.id == song.id }) {
                print("QueueManager: Correcting queue index from \(queueIndex) to \(correctIndex) for song: \(song.title)")
                queueIndex = correctIndex
            }
        } else {
            print("QueueManager: Song already at correct index: \(queueIndex)")
        }
    }
    
    /// Toggle shuffle mode
    func toggleShuffle() {
        print("QueueManager: toggleShuffle called, current state: \(shuffleEnabled)")
        let currentSong = currentSongInQueue
        
        shuffleEnabled.toggle()
        print("QueueManager: Shuffle \(shuffleEnabled ? "enabled" : "disabled")")
        
        if shuffleEnabled {
            // Shuffle the queue but keep the current song at the start
            if let song = currentSong, let index = currentQueue.firstIndex(where: { $0.id == song.id }) {
                var newQueue = currentQueue
                newQueue.remove(at: index)
                newQueue.shuffle()
                newQueue.insert(song, at: 0)
                currentQueue = newQueue
                queueIndex = 0
                print("QueueManager: Shuffled queue with current song \(song.title) at start")
            } else {
                currentQueue.shuffle()
                queueIndex = 0
                print("QueueManager: Shuffled queue completely")
            }
        } else {
            // Just keep the current shuffled order
            print("QueueManager: Keeping current queue order after disabling shuffle")
        }
    }
    
    /// Cycle through repeat modes
    func cycleRepeatMode() {
        print("QueueManager: cycleRepeatMode called, current mode: \(repeatMode)")
        
        switch repeatMode {
        case .off:
            repeatMode = .all
            print("QueueManager: Repeat mode changed to: all")
        case .all:
            repeatMode = .one
            print("QueueManager: Repeat mode changed to: one")
        case .one:
            repeatMode = .off
            print("QueueManager: Repeat mode changed to: off")
        }
    }
    
    // MARK: - Random Preset Queue
    
    /// Generate a random preset queue of 10 songs
    func generateRandomPresetQueue() {
        let allSongs = dataManager.loadSongs()
        if allSongs.isEmpty {
            print("QueueManager: No songs available for random queue")
            return
        }
        
        let randomQueue = Array(allSongs.shuffled().prefix(10))
        print("QueueManager: Generated random queue with \(randomQueue.count) songs")
        
        // Always set an initial random queue on app start
        if currentQueue.isEmpty {
            currentQueue = randomQueue
            queueIndex = 0
            print("QueueManager: Set initial random queue")
        }
    }
    
    /// Play the random preset queue - create a completely new random queue
    func playRandomPresetQueue() {
        // Generate a new random queue regardless of current state
        let allSongs = dataManager.loadSongs()
        if !allSongs.isEmpty {
            let randomQueue = Array(allSongs.shuffled().prefix(10))
            
            // Always set a new queue when this method is called
            setQueue(songs: randomQueue)
            print("QueueManager: Created new random queue with \(randomQueue.count) songs")
            
            // Log the first song (will be played)
            if let firstSong = currentSongInQueue {
                print("QueueManager: First song in new random queue: \(firstSong.title)")
            }
        } else {
            print("QueueManager: No songs available for random queue")
        }
    }
    
    /// Refresh the random preset queue with new songs
    func refreshRandomPresetQueue() {
        playRandomPresetQueue()
    }
}
