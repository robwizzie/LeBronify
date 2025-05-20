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
    @Published var originalQueueOrder: [Song] = [] // Store original order when shuffle is enabled
    
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
        // Load initial queue data in a lightweight way without notifications
        initializeDefaultQueue()
    }
    
    // Lightweight initialization without notifications or expensive operations
    private func initializeDefaultQueue() {
        let allSongs = dataManager.loadSongs()
        if !allSongs.isEmpty {
            let randomQueue = Array(allSongs.shuffled().prefix(10))
            currentQueue = randomQueue
            originalQueueOrder = randomQueue
            queueIndex = 0
            print("QueueManager: Initialized with default queue (\(randomQueue.count) songs)")
        } else {
            print("QueueManager: Initialized with empty queue, no songs available")
        }
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
        
        // Store original order
        originalQueueOrder = randomQueue
        
        // Set the queue
        currentQueue = randomQueue
        queueIndex = 0
        
        // Return the first song that should be prepared (but not played yet)
        return currentSongInQueue
    }
    
    /// Replace the current queue with new songs
    func setQueue(songs: [Song], startingAt index: Int = 0) {
        guard !songs.isEmpty else {
            print("QueueManager: Attempted to set empty queue")
            return
        }
        
        // Store the original order before any shuffling
        originalQueueOrder = songs
        
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
            queueIndex = min(index, songs.count - 1)
        }
        
        print("QueueManager: Set queue with \(songs.count) songs, starting at index \(queueIndex)")
        
        // If we have at least one song, ensure the first song is ready
        if !currentQueue.isEmpty && queueIndex < currentQueue.count {
            let firstSong = currentQueue[queueIndex]
            print("QueueManager: First song in new queue: \(firstSong.title)")
            
            // Notify that we have a new current song ready
            NotificationCenter.default.post(
                name: NSNotification.Name("QueueFirstSongReady"),
                object: nil,
                userInfo: ["song": firstSong]
            )
        }
    }
    
    /// Add songs to the end of the queue
    func addToQueue(songs: [Song]) {
        guard !songs.isEmpty else { return }
        
        // Add to both current and original queue
        currentQueue.append(contentsOf: songs)
        originalQueueOrder.append(contentsOf: songs)
        
        print("QueueManager: Added \(songs.count) songs to queue")
    }
    
    /// Add a single song to the end of the queue
    func addToQueue(song: Song) {
        // Check if song is already in queue to prevent duplicates
        if currentQueue.contains(where: { $0.id == song.id }) {
            print("QueueManager: Song already in queue, not adding duplicate")
            return
        }
        
        currentQueue.append(song)
        originalQueueOrder.append(song)
        print("QueueManager: Added song to queue: \(song.title)")
    }
    
    /// Add a song to play next (right after the current song)
    func playNext(song: Song) {
        // Remove the song if it's already in the queue to avoid duplicates
        if let existingIndex = currentQueue.firstIndex(where: { $0.id == song.id }) {
            // Don't remove if it's the current song
            if existingIndex != queueIndex {
                currentQueue.remove(at: existingIndex)
                // Adjust queue index if removing a song before the current one
                if existingIndex < queueIndex {
                    queueIndex -= 1
                }
            }
        }
        
        if currentQueue.isEmpty {
            currentQueue = [song]
            originalQueueOrder = [song]
            queueIndex = 0
            print("QueueManager: Queue was empty, added song as first: \(song.title)")
        } else if queueIndex < currentQueue.count - 1 {
            currentQueue.insert(song, at: queueIndex + 1)
            // Add to original order at the same relative position
            if let currentSong = currentSongInQueue,
               let originalIndex = originalQueueOrder.firstIndex(where: { $0.id == currentSong.id }) {
                originalQueueOrder.insert(song, at: originalIndex + 1)
            } else {
                originalQueueOrder.append(song)
            }
            print("QueueManager: Added song to play next: \(song.title)")
        } else {
            currentQueue.append(song)
            originalQueueOrder.append(song)
            print("QueueManager: Added song to end of queue: \(song.title)")
        }
    }
    
    /// Remove a song from the queue without affecting the currently playing song
    func removeFromQueue(at index: Int) {
        guard index >= 0, index < currentQueue.count else {
            print("QueueManager: Invalid index \(index) for removal")
            return
        }
        
        // Don't allow removing the currently playing song
        if index == queueIndex {
            print("QueueManager: Cannot remove currently playing song at index \(index)")
            return
        }
        
        // Get current song ID before modifying the queue to maintain playback
        let currentSongID = currentSongInQueue?.id
        
        // Remove from both queues
        let removedSong = currentQueue.remove(at: index)
        if let originalIndex = originalQueueOrder.firstIndex(where: { $0.id == removedSong.id }) {
            originalQueueOrder.remove(at: originalIndex)
        }
        
        // Adjust queue index if removing a song before the current one
        if index < queueIndex {
            queueIndex -= 1
        }
        
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
        guard source >= 0, source < currentQueue.count, 
              destination >= 0, destination <= currentQueue.count else {
            print("QueueManager: Invalid source or destination index - source: \(source), destination: \(destination), queueSize: \(currentQueue.count)")
            return
        }
        
        guard source != queueIndex else {
            print("QueueManager: Cannot move currently playing song")
            return
        }
        
        // Store the current song details
        let currentSongID = currentSongInQueue?.id
        let currentSongTitle = currentSongInQueue?.title ?? "Unknown"
        
        // Get song being moved for better logging
        let movingSong = currentQueue[source]
        
        print("QueueManager: Moving song '\(movingSong.title)' from \(source) to \(destination)")
        print("QueueManager: Current playing song: '\(currentSongTitle)' at index \(queueIndex)")
        
        // Perform the move operation
        let item = currentQueue.remove(at: source)
        
        // Calculate actual destination accounting for removal
        let actualDestination = min(destination, currentQueue.count)
        
        // Insert at the actual destination
        currentQueue.insert(item, at: actualDestination)
        
        // Update original order to maintain consistency
        if let originalSource = originalQueueOrder.firstIndex(where: { $0.id == item.id }) {
            originalQueueOrder.remove(at: originalSource)
            let originalDestination = min(destination, originalQueueOrder.count)
            originalQueueOrder.insert(item, at: originalDestination)
        }
        
        // Update queue index to maintain current song position
        if currentSongID != nil {
            // Moving a song affects the current index
            if source < queueIndex && destination >= queueIndex {
                // Moving from before current to after current - shift current down by 1
                let oldIndex = queueIndex
                queueIndex -= 1
                print("QueueManager: Moving from before to after - adjusting index from \(oldIndex) to \(queueIndex)")
            } else if source > queueIndex && destination <= queueIndex {
                // Moving from after current to before current - shift current up by 1
                let oldIndex = queueIndex
                queueIndex += 1
                print("QueueManager: Moving from after to before - adjusting index from \(oldIndex) to \(queueIndex)")
            }
            
            // Re-verify current song position by finding its ID in the queue
            if let newIndex = currentQueue.firstIndex(where: { $0.id == currentSongID }) {
                if newIndex != queueIndex {
                    print("QueueManager: Correcting index from \(queueIndex) to \(newIndex) to match current song")
                    queueIndex = newIndex
                }
            }
        }
        
        // Print the new queue state for debugging
        printQueueState()
    }
    
    // Helper method to print the current queue state for debugging
    private func printQueueState() {
        print("QueueManager: QUEUE STATE -----")
        print("Queue size: \(currentQueue.count), Current index: \(queueIndex)")
        print("Current song: \(currentSongInQueue?.title ?? "none")")
        
        for (index, song) in currentQueue.enumerated() {
            let indicator = index == queueIndex ? "▶️" : "  "
            print("\(indicator) [\(index)]: \(song.title)")
        }
        print("-------------------------")
    }
    
    /// Clear the queue except for the currently playing song
    func clearQueue() {
        if let currentSong = currentSongInQueue {
            currentQueue = [currentSong]
            originalQueueOrder = [currentSong]
            queueIndex = 0
            print("QueueManager: Cleared queue, kept only current song: \(currentSong.title)")
        } else {
            currentQueue = []
            originalQueueOrder = []
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
    
    /// Play a specific song immediately 
    func playSongImmediately(_ song: Song) {
        // Check if song is already in queue
        if let index = currentQueue.firstIndex(where: { $0.id == song.id }) {
            // It's in the queue, jump to it
            _ = jumpToSong(at: index)
        } else {
            // Not in queue, create a new queue with just this song
            setQueue(songs: [song])
        }
    }
    
    /// Add song to play immediately after the current song
    func playAfterCurrent(_ song: Song) {
        // If queue is empty or no current song, just add and set as current
        if currentQueue.isEmpty {
            currentQueue = [song]
            originalQueueOrder.append(song)
            queueIndex = 0
            return
        }
        
        // Remove the song if it's already in the queue (to avoid duplicates)
        if let existingIndex = currentQueue.firstIndex(where: { $0.id == song.id }) {
            // Don't remove if it's the current song
            if existingIndex != queueIndex {
                currentQueue.remove(at: existingIndex)
                // Adjust queue index if removing a song before the current one
                if existingIndex < queueIndex {
                    queueIndex -= 1
                }
            }
        }
        
        // Now add it right after the current song
        if queueIndex < currentQueue.count {
            // Insert after current
            currentQueue.insert(song, at: queueIndex + 1)
            
            // Update originalQueueOrder too
            if let currentSong = currentSongInQueue,
               let originalIndex = originalQueueOrder.firstIndex(where: { $0.id == currentSong.id }) {
                originalQueueOrder.insert(song, at: originalIndex + 1)
            } else {
                originalQueueOrder.append(song)
            }
        } else {
            // Should never happen, but just in case
            currentQueue.append(song)
            originalQueueOrder.append(song)
        }
    }
    
    /// Move to the next song in the queue
    func nextSong() -> Song? {
        guard !currentQueue.isEmpty else { 
            print("QueueManager: Queue is empty, can't get next song")
            return nil 
        }
        
        switch repeatMode {
        case .off:
            // In normal mode, we move to the next song but only remove the current 
            // after we've confirmed the next song exists
            if !currentQueue.isEmpty {
                // Check if we have more songs in the queue
                if queueIndex < currentQueue.count - 1 {
                    // We have more songs - add current to history before moving to next
                    if let currentSong = currentSongInQueue {
                        playHistory.append(currentSong)
                        // Limit history size
                        if playHistory.count > 50 {
                            playHistory.removeFirst()
                        }
                    }
                    
                    // Move to the next song first
                    queueIndex += 1
                    print("QueueManager: Moving to next song at index \(queueIndex)")
                    return currentSongInQueue
                } 
                else if queueIndex == currentQueue.count - 1 {
                    // At the last song - add to history but keep it
                    if let currentSong = currentSongInQueue {
                        playHistory.append(currentSong)
                        // Limit history size
                        if playHistory.count > 50 {
                            playHistory.removeFirst()
                        }
                    }
                    
                    // We're already at the last song
                    print("QueueManager: Already at the last song")
                    return currentSongInQueue
                }
                else {
                    return nil // No more songs (shouldn't reach here)
                }
            } else {
                return nil // Queue is empty
            }
            
        case .all:
            // With repeat all, if we reach the end, go back to the beginning
            if queueIndex < currentQueue.count - 1 {
                // Not at the end yet, move to next song
                queueIndex += 1
                print("QueueManager: Moving to next song at index \(queueIndex)")
            } else {
                // At the end, loop back to the first song
                queueIndex = 0
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
        guard !currentQueue.isEmpty else { 
            print("QueueManager: Queue is empty, can't get previous song")
            return nil 
        }
        
        switch repeatMode {
        case .off, .all:
            // For previous, we need to restore the last song from history
            if queueIndex > 0 {
                // Still have previous songs in queue
                queueIndex -= 1
                print("QueueManager: Moving to previous song at index \(queueIndex)")
                return currentSongInQueue
            } else if !playHistory.isEmpty && repeatMode == .off {
                // Go back to the last song in history
                let lastSong = playHistory.removeLast()
                print("QueueManager: Going back to song from history: \(lastSong.title)")
                
                // Insert the song from history at the beginning
                currentQueue.insert(lastSong, at: 0)
                
                // Adjust for proper queue index
                queueIndex = 0
                
                // Add to original order as well
                originalQueueOrder.insert(lastSong, at: 0)
                
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
        guard index >= 0, index < currentQueue.count else { 
            print("QueueManager: Invalid jump index: \(index)")
            return nil 
        }
        
        // Don't add to history if we're already at this index
        if index != queueIndex {
        // Add current song to history
        if let currentSong = currentSongInQueue {
            playHistory.append(currentSong)
            }
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
            // Store current order before shuffling if not already stored
            if originalQueueOrder.isEmpty {
                originalQueueOrder = currentQueue
            }
            
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
            // Restore original order while keeping current song position
            if let currentSong = currentSong,
               let originalIndex = originalQueueOrder.firstIndex(where: { $0.id == currentSong.id }) {
                currentQueue = originalQueueOrder
                queueIndex = originalIndex
                print("QueueManager: Restored original queue order, current song at index \(queueIndex)")
            } else {
                print("QueueManager: Could not find current song in original order, keeping current queue")
            }
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
    func generateRandomPresetQueue() -> Song? {
        let allSongs = dataManager.loadSongs()
        if allSongs.isEmpty {
            print("QueueManager: No songs available for random queue")
            return nil
        }
        
        let randomQueue = Array(allSongs.shuffled().prefix(10))
        print("QueueManager: Generated random queue with \(randomQueue.count) songs")
        
        // Store original order
        originalQueueOrder = randomQueue
        
        // Set the queue
        currentQueue = randomQueue
        queueIndex = 0
        
        // Return the first song that should be prepared (but not played yet)
        return currentSongInQueue
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
