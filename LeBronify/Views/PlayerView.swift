//
//  PlayerView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI
import AVFoundation

struct SongRowWithActions: View {
    let song: Song
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var showingOptions = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Album art with rank
            ZStack(alignment: .topLeading) {
                Image(song.albumArt)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
                
                if let rank = song.topRank(in: viewModel.allSongs) {
                    TopSongBadge(rank: rank)
                        .offset(x: -4, y: -4)
                        .scaleEffect(0.7)
                        .zIndex(1)
                }
            }
            
            VStack(alignment: .leading) {
                Text(song.title)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack {
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    if song.playCount > 0 {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                                
                            Text("\(song.playCount)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Menu with queue actions
            Menu {
                Button(action: {
                    viewModel.playSong(song)
                }) {
                    Label("Play Now", systemImage: "play.fill")
                }
                
                Button(action: {
                    viewModel.queueManager.playNext(song: song)
                }) {
                    Label("Play Next", systemImage: "text.insert")
                }
                
                Button(action: {
                    viewModel.addToQueue(song)
                }) {
                    Label("Add to Queue", systemImage: "list.bullet")
                }
                
                Divider()
                
                Button(action: {
                    viewModel.toggleFavorite(for: song.id)
                }) {
                    Label(
                        song.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: song.isFavorite ? "heart.fill" : "heart"
                    )
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
            }
            
            // Play button
            Button(action: {
                viewModel.playSong(song)
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PlayerView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var sortOption: SortOption = .plays
    @State private var showingQueueView = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("LEBRONIFY")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(.top, 10)
                    
                    // Current song info (if any)
                    if let song = viewModel.currentSong {
                        // Album art with rank badge if applicable
                        ZStack(alignment: .topLeading) {
                            Image(song.albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: min(250, geometry.size.width - 40))
                                .cornerRadius(12)
                                .shadow(radius: 8)
                            
                            if let rank = song.topRank(in: viewModel.allSongs) {
                                TopSongBadge(rank: rank)
                                    .offset(x: 10, y: 10)
                                    .scaleEffect(1.5)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            Text(song.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .padding(.horizontal)
                            
                            Text(song.artist)
                                .font(.title3)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            
                            // Play statistics
                            HStack(spacing: 16) {
                                VStack {
                                    Text("\(song.playCount)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.yellow)
                                    
                                    Text("Plays")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                if let lastPlayed = song.lastPlayed {
                                    VStack {
                                        Text(lastPlayedTime(lastPlayed))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.yellow)
                                        
                                        Text("Last Played")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        // Playback progress - constrain to screen width
                        VStack(spacing: 4) {
                            Slider(value: Binding(
                                get: { viewModel.currentPlaybackTime },
                                set: { viewModel.seek(to: $0) }
                            ), in: 0...max(viewModel.duration, 1))
                            .accentColor(.yellow)
                            
                            HStack {
                                Text(formatTime(viewModel.currentPlaybackTime))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(formatTime(viewModel.duration))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(width: min(geometry.size.width, 350))
                        
                        // Shuffle and repeat controls
                        HStack(spacing: 40) {
                            Button(action: {
                                viewModel.toggleShuffle()
                            }) {
                                Image(systemName: viewModel.queueManager.shuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                                    .font(.title3)
                                    .foregroundColor(viewModel.queueManager.shuffleEnabled ? .yellow : .gray)
                            }
                            
                            // Player controls
                            HStack(spacing: 30) {
                                Button(action: {
                                    viewModel.previousSong()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    viewModel.togglePlayPause()
                                }) {
                                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 65))
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    viewModel.nextSong()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Button(action: {
                                viewModel.cycleRepeatMode()
                            }) {
                                Image(systemName: {
                                    switch viewModel.queueManager.repeatMode {
                                    case .off: return "repeat"
                                    case .all: return "repeat.circle.fill"
                                    case .one: return "repeat.1.circle.fill"
                                    }
                                }())
                                .font(.title3)
                                .foregroundColor(viewModel.queueManager.repeatMode == .off ? .gray : .yellow)
                            }
                        }
                        .padding()
                        
                        // Queue and favorite buttons
                        HStack(spacing: 50) {
                            Button(action: {
                                if let currentSong = viewModel.currentSong {
                                    viewModel.toggleFavorite(for: currentSong.id)
                                    
                                    // Need to refresh currentSong to update UI
                                    let songID = currentSong.id
                                    let allSongs = viewModel.allSongs
                                    if let updatedSong = allSongs.first(where: { $0.id == songID }) {
                                        viewModel.currentSong = updatedSong
                                    }
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: song.isFavorite ? "heart.fill" : "heart")
                                        .font(.title3)
                                        .foregroundColor(song.isFavorite ? .red : .gray)
                                    
                                    Text("Favorite")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {
                                showingQueueView = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "list.bullet")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                    
                                    Text("Queue")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {
                                viewModel.playRandomPresetQueue()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "shuffle.circle")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                    
                                    Text("Random")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                    } else {
                        // No song selected state
                        Text("No song selected")
                            .font(.title)
                            .foregroundColor(.gray)
                            .padding(.vertical, 40)
                        
                        Button(action: {
                            // Select a random song to start
                            if let song = viewModel.allSongs.randomElement() {
                                viewModel.playSong(song)
                            }
                        }) {
                            Text("Play Random LeBron Hit")
                                .font(.headline)
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                    }
                    
                    // Song list
                    VStack(alignment: .leading) {
                        HStack {
                            Text(sortOption == .plays ? "Most Played" : "All Songs")
                                .font(.headline)
                                .padding(.leading)
                            
                            Spacer()
                            
                            Picker("Sort", selection: $sortOption) {
                                Text("Most Played").tag(SortOption.plays)
                                Text("Recent").tag(SortOption.recent)
                                Text("Title").tag(SortOption.title)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: min(geometry.size.width - 150, 220))
                            .padding(.trailing)
                        }
                        .padding(.horizontal, 5)
                        
                        // Use List with fixed height to prevent scroll issues
                        List {
                            ForEach(sortedSongs(viewModel.allSongs)) { song in
                                SongRowWithActions(song: song)
                            }
                        }
                        .frame(height: 200)
                        .listStyle(PlainListStyle())
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .padding(.top)
        .sheet(isPresented: $showingQueueView) {
            QueueView()
        }
    }
    
    // Sort songs based on selected option
    private func sortedSongs(_ songs: [Song]) -> [Song] {
        switch sortOption {
        case .title:
            return songs.sorted { $0.title < $1.title }
        case .artist:
            return songs.sorted { $0.artist < $1.artist }
        case .plays:
            return songs.sorted { $0.playCount > $1.playCount }
        case .recent:
            return songs.sorted {
                ($0.lastPlayed ?? Date.distantPast) > ($1.lastPlayed ?? Date.distantPast)
            }
        default:
            return songs
        }
    }
    
    // Helper function to format time
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Helper function to format last played time
    private func lastPlayedTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
            .environmentObject(LeBronifyViewModel())
    }
}
