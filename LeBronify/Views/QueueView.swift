//
//  QueueView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 5/14/25.
//

import SwiftUI

struct QueueView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Current song section
                if let currentSong = viewModel.currentSong {
                    VStack(spacing: 16) {
                        Text("NOW PLAYING")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        HStack(spacing: 12) {
                        Image.albumArt(for: currentSong)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                        
                            VStack(alignment: .leading, spacing: 4) {
                            Text(currentSong.title)
                                .font(.headline)
                                    .lineLimit(1)
                            
                            Text(currentSong.artist)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                    .lineLimit(1)
                        }
                        
                        Spacer()
                            
                            // Playback control buttons
                            HStack(spacing: 16) {
                                // Previous button
                                Button(action: {
                                    viewModel.previousSong()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                
                                // Play/Pause button
                                Button(action: {
                                    viewModel.togglePlayPause()
                                }) {
                                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.blue)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                
                                // Next button
                                Button(action: {
                                    viewModel.nextSong()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                    .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                }
                
                // Queue list with better section header
                List {
                    Section(header: 
                        HStack {
                            Text("UP NEXT")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Calculate only upcoming songs, excluding the current one
                            let upcomingSongs = getUpcomingSongs()
                            Text("\(upcomingSongs.count) \(upcomingSongs.count == 1 ? "song" : "songs")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    ) {
                        // Only display upcoming songs (exclude the currently playing song)
                        ForEach(Array(getUpcomingSongs().enumerated()), id: \.element.id) { index, song in
                                HStack(spacing: 12) {
                                // Song number in queue - starts from 1 for user readability
                                Text("\(index + 1)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .frame(width: 25, alignment: .center)
                                
                                    Image.albumArt(for: song)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(6)
                                    
                                VStack(alignment: .leading, spacing: 4) {
                                        Text(song.title)
                                            .font(.body)
                                        .lineLimit(1)
                                        
                                        Text(song.artist)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                // Play button with better touch target
                                    Button(action: {
                                        viewModel.playSong(song)
                                    }) {
                                    Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                            }
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button(action: {
                                    removeFromQueue(song)
                                }) {
                                    Label("Remove", systemImage: "trash")
                                }
                                
                                    Button(action: {
                                    viewModel.playNext(song)
                                    }) {
                                    Label("Play Next", systemImage: "text.insert")
                                    }
                            }
                        }
                        .onMove { source, destination in
                            // Remove isReordering flag usage which was causing problems
                            moveQueueItem(from: source.first!, to: destination)
                }
                        .onDelete { indexSet in
                            // Convert IndexSet to array of indices and remove
                            removeSelectedItems(indexSet) 
                        }
                    }
                }
                .listStyle(PlainListStyle())
                // Allow editing even when song is playing
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                
                // Queue controls with improved appearance
                VStack(spacing: 0) {
                    Divider()
                    
                    // Control buttons
                    HStack(spacing: 24) {
                    Button(action: {
                            viewModel.clearQueue()
                    }) {
                            VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                            Text("Clear")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.isPlaying)
                    
                    Button(action: {
                        viewModel.queueManager.toggleShuffle()
                    }) {
                            VStack(spacing: 4) {
                            Image(systemName: viewModel.queueManager.shuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                                .font(.title2)
                                .foregroundColor(viewModel.queueManager.shuffleEnabled ? .blue : .primary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                            Text("Shuffle")
                                .font(.caption)
                                    .foregroundColor(viewModel.queueManager.shuffleEnabled ? .blue : .primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        viewModel.queueManager.cycleRepeatMode()
                    }) {
                            VStack(spacing: 4) {
                            Image(systemName: {
                                switch viewModel.queueManager.repeatMode {
                                case .off: return "repeat"
                                case .all: return "repeat.circle.fill"
                                case .one: return "repeat.1.circle.fill"
                                }
                            }())
                            .font(.title2)
                            .foregroundColor(viewModel.queueManager.repeatMode == .off ? .primary : .blue)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            
                            Text("Repeat")
                                .font(.caption)
                                    .foregroundColor(viewModel.queueManager.repeatMode == .off ? .primary : .blue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        viewModel.playRandomPresetQueue()
                    }) {
                            VStack(spacing: 4) {
                            Image(systemName: "shuffle.circle")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                            Text("Random")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Queue")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Group {
                    // Allow editing even when playing
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                }
            )
        }
    }
    
    // Helper method to get only upcoming songs (exclude currently playing)
    private func getUpcomingSongs() -> [Song] {
        let allQueueSongs = viewModel.queueManager.currentQueue
        
        // Create a new array without the currently playing song
        return allQueueSongs.filter { song in
            song.id != viewModel.currentSong?.id
        }
    }
    
    // Helper to remove a song from the queue based on song ID
    private func removeFromQueue(_ song: Song) {
        // Find the real index in the full queue
        if let realIndex = viewModel.queueManager.currentQueue.firstIndex(where: { $0.id == song.id }) {
            viewModel.queueManager.removeFromQueue(at: realIndex)
        }
    }
    
    // Helper to move queue items with proper index adjustment
    private func moveQueueItem(from source: Int, to destination: Int) {
        // Remove the isReordering check that was blocking moves
        print("QueueView: === MOVE OPERATION START ===")
        print("QueueView: Moving visible item from \(source) to \(destination)")
        
        // Get the upcoming songs (which excludes the currently playing song)
        let upcomingSongs = getUpcomingSongs()
        print("QueueView: Found \(upcomingSongs.count) upcoming songs (visible in queue)")
        
        // Check if there's anything to move
        guard source < upcomingSongs.count else {
            print("QueueView: Source index \(source) out of bounds for visible queue size \(upcomingSongs.count)")
            return
        }
        
        // Get the song at the source position in our filtered list
        let songToMove = upcomingSongs[source]
        print("QueueView: Selected song to move: '\(songToMove.title)'")
        
        // Log full queue state for reference
        print("QueueView: Current full queue state before move:")
        let fullQueue = viewModel.queueManager.currentQueue
        print("QueueView: - Full queue size: \(fullQueue.count)")
        print("QueueView: - Current index: \(viewModel.queueManager.queueIndex)")
        for (i, song) in fullQueue.enumerated() {
            let currentIndicator = i == viewModel.queueManager.queueIndex ? "▶️" : "  "
            print("QueueView: \(currentIndicator) [\(i)]: \(song.title)")
        }
        
        // Find the real source index in the full queue
        if let realSourceIndex = viewModel.queueManager.currentQueue.firstIndex(where: { $0.id == songToMove.id }) {
            print("QueueView: Found real source index in full queue: \(realSourceIndex)")
            
            // Calculate real destination in the full queue
            // This is the key part that's causing the issues
            var realDestination: Int
            
            // Get the currently playing song's position in the real queue
            let currentSongIndex = viewModel.queueManager.queueIndex
            
            // If there's a current song playing (which is filtered out of the UI list)
            if let currentSong = viewModel.currentSong {
                print("QueueView: Current song is: '\(currentSong.title)' at index \(currentSongIndex)")
                
                // Map from UI destination to real queue destination
                if currentSongIndex == 0 {
                    // If current song is at the start of the queue
                    realDestination = destination + 1 // Everything in UI is offset by 1
                    print("QueueView: Current song is at start - offsetting destination by 1")
                } else {
                    // Create a mapping from UI indices to real queue indices
                    var visibleIndicesMap = [Int: Int]() // UI index -> real queue index
                    var counter = 0
                    
                    // Build a mapping table from visible indices to real queue indices
                    for (i, _) in fullQueue.enumerated() {
                        // Skip the current song in our mapping
                        if i == currentSongIndex {
                            continue
                        }
                        visibleIndicesMap[counter] = i
                        counter += 1
                    }
                    
                    print("QueueView: Visible queue to real queue mapping:")
                    for (uiIndex, realIndex) in visibleIndicesMap.sorted(by: { $0.key < $1.key }) {
                        print("QueueView:   UI[\(uiIndex)] -> Queue[\(realIndex)]")
                    }
                    
                    // If the destination is at the end of the visible queue
                    if destination >= upcomingSongs.count {
                        realDestination = fullQueue.count
                        print("QueueView: Destination is at end of visible queue, setting to end of real queue")
                    } else {
                        // Get the real index that corresponds to the UI destination
                        realDestination = visibleIndicesMap[destination] ?? destination
                        print("QueueView: Mapped UI destination \(destination) to real queue index \(realDestination)")
                    }
                }
            } else {
                // No current song, UI indices should match real queue indices
                realDestination = destination
                print("QueueView: No current song - UI indices match real queue indices")
            }
            
            // Make sure destination is in bounds
            let initialDestination = realDestination
            realDestination = min(realDestination, viewModel.queueManager.currentQueue.count)
            realDestination = max(realDestination, 0)
            
            if initialDestination != realDestination {
                print("QueueView: Adjusted destination to stay within bounds: \(initialDestination) -> \(realDestination)")
            }
            
            // Prevent moving to the current song position
            if viewModel.currentSong != nil && realDestination == currentSongIndex {
                let oldDestination = realDestination
                realDestination = realDestination + 1
                print("QueueView: Prevented move to current song position: \(oldDestination) -> \(realDestination)")
            }
            
            // Now perform the move with the real indices
            print("QueueView: FINAL: Moving song from index \(realSourceIndex) to \(realDestination)")
            
            // Log visible queue before move
            print("QueueView: Visible queue before move:")
            for (i, song) in upcomingSongs.enumerated() {
                let indicator = i == source ? "→" : " "
                print("QueueView:  \(indicator) [\(i)]: \(song.title)")
            }
            
            viewModel.queueManager.moveItem(from: realSourceIndex, to: realDestination)
            
            // Log visible queue after move
            let newUpcomingSongs = getUpcomingSongs()
            print("QueueView: Visible queue after move:")
            for (i, song) in newUpcomingSongs.enumerated() {
                let indicator = song.id == songToMove.id ? "→" : " "
                print("QueueView:  \(indicator) [\(i)]: \(song.title)")
            }
            
            print("QueueView: === MOVE OPERATION COMPLETE ===")
        } else {
            print("QueueView: ERROR - Could not find song '\(songToMove.title)' in full queue")
        }
    }
    
    // Helper to remove selected items by index
    private func removeSelectedItems(_ indexSet: IndexSet) {
        // Get the songs to remove
        let upcomingSongs = getUpcomingSongs()
        let songsToRemove = indexSet.map { upcomingSongs[$0] }
        
        // Remove each song by finding its real index in the queue
        for song in songsToRemove {
            if let realIndex = viewModel.queueManager.currentQueue.firstIndex(where: { $0.id == song.id }) {
                viewModel.queueManager.removeFromQueue(at: realIndex)
            }
        }
    }
}

struct QueueView_Previews: PreviewProvider {
    static var previews: some View {
        QueueView()
            .environmentObject(LeBronifyViewModel())
    }
}
