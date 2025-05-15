//
//  UIComponents.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI

// Helper extension to determine if a song is in the top played songs
extension Song {
    // Returns the top song rank if it's in the top 3 most played
    func topRank(in songs: [Song]) -> Int? {
        // Sort all songs by play count
        let sortedSongs = songs.sorted { $0.playCount > $1.playCount }
        
        // Find this song's position
        if let index = sortedSongs.firstIndex(where: { $0.id == self.id }) {
            // Only return a rank for the top 3 songs with at least 1 play
            return index < 3 && self.playCount > 0 ? index + 1 : nil
        }
        
        return nil
    }
}

// A badge to show on top songs
struct TopSongBadge: View {
    let rank: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow)
                .frame(width: 24, height: 24)
                .shadow(radius: 2)
            
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
        }
    }
}

// Song row component for listing songs
struct SongRow: View {
    let song: Song
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var showingOptions = false
    
    var body: some View {
        Button(action: {
            viewModel.playSong(song)
        }) {
            HStack(spacing: 12) {
                // Album art with optional top rank badge
                if let rank = song.topRank(in: viewModel.allSongs) {
                    ZStack(alignment: .topLeading) {
                        Image(song.albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(4)
                        
                        TopSongBadge(rank: rank)
                            .offset(x: -8, y: -8)
                    }
                } else {
                    Image(song.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(4)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Display play count with a small icon
                        if song.playCount > 0 {
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(song.playCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.toggleFavorite(for: song.id)  // Pass song.id instead of song
                }) {
                    Image(systemName: song.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(song.isFavorite ? .red : .gray)
                }
                .padding(.horizontal, 8)
                
                Button(action: {
                    viewModel.playSong(song)
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    showingOptions = true
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
                .padding(.leading, 8)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .actionSheet(isPresented: $showingOptions) {
            ActionSheet(
                title: Text(song.title),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("Add to Playlist")) {
                        // We would implement a sheet to select playlist here
                    },
                    .default(Text(song.isFavorite ? "Remove from Favorites" : "Add to Favorites")) {
                        viewModel.toggleFavorite(for: song.id)  // Change from song to song.id
                    },
                    .cancel()
                ]
            )
        }
    }
}

// Playlist row for horizontal scrolling
struct PlaylistRow: View {
    let title: String
    let songs: [Song]
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(songs) { song in
                        Button(action: {
                            viewModel.playSong(song)
                        }) {
                            VStack(alignment: .leading) {
                                // Album art with optional top rank badge
                                if let rank = song.topRank(in: viewModel.allSongs), title == "Top Hits" {
                                    ZStack(alignment: .topLeading) {
                                        Image(song.albumArt)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .cornerRadius(8)
                                        
                                        TopSongBadge(rank: rank)
                                            .offset(x: -4, y: -4)
                                    }
                                    .padding(.top, 8)    // Add padding at the top to prevent badge cutoff
                                    .padding(.leading, 8) // Add padding at the left to prevent badge cutoff
                                } else {
                                    Image(song.albumArt)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(8)
                                }
                                
                                Text(song.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                HStack {
                                    Text(song.artist)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    if song.playCount > 0 {
                                        Spacer()
                                        Text("\(song.playCount)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(width: 120)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Mini player that appears at bottom of screen
struct MiniPlayerView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedTab: Int
    @State private var showingQueueView = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Divider at the top for visual separation
            Divider()
            
            // Main mini player content
            HStack(spacing: 16) {
                // Clickable area (album art and text) that navigates to Now Playing tab
                Button(action: {
                    // Switch to Now Playing tab (tab index 1 in your app)
                    selectedTab = 1
                }) {
                    HStack {
                        if let currentSong = viewModel.currentSong {
                            Image(currentSong.albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .cornerRadius(4)
                        } else {
                            Image("lebron_default")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .cornerRadius(4)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.currentSong?.title ?? "")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            
                            Text(viewModel.currentSong?.artist ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Queue button
                Button(action: {
                    showingQueueView = true
                }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.primary)
                        .font(.system(size: 20))
                }
                .padding(.horizontal, 4)
                
                // Control buttons
                HStack(spacing: 10) {
                    Button(action: {
                        viewModel.previousSong()
                    }) {
                        Image(systemName: "backward.fill")
                            .foregroundColor(.primary)
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 4)
                    
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        viewModel.nextSong()
                    }) {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.primary)
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding()
            .background(
                (colorScheme == .dark ? Color(.systemBackground) : Color.white)
            )
        }
        .background(
            (colorScheme == .dark ? Color(.systemBackground) : Color.white)
                .edgesIgnoringSafeArea(.bottom)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: -1)
        .sheet(isPresented: $showingQueueView) {
            QueueView()
        }
    }
}

// This view shows details for a playlist
struct PlaylistDetailView: View {
    let playlist: Playlist
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var sortOption: SortOption = .default
    @Binding var selectedTab: Int
    
    // Add a default initializer to provide backward compatibility
    init(playlist: Playlist, selectedTab: Binding<Int>? = nil) {
        self.playlist = playlist
        self._selectedTab = selectedTab ?? .constant(0) // Provide a default value if nil
    }
    
    var body: some View {
        let songs = sortedSongs(viewModel.getSongs(for: playlist))
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Playlist header
                HStack(alignment: .top, spacing: 16) {
                    Image(playlist.coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(playlist.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(playlist.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("\(songs.count) songs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Play all button and sort options
                HStack {
                    if !songs.isEmpty {
                        Button(action: {
                            if let firstSong = songs.first {
                                viewModel.playSong(firstSong)
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                Text("Play All")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    // Simplified sort menu
                    Menu {
                        // Default option
                        Button(action: { sortOption = .default }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("Default")
                                Spacer()
                                if sortOption == .default {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        // Title option
                        Button(action: { sortOption = .title }) {
                            HStack {
                                Image(systemName: "textformat")
                                Text("By Title")
                                Spacer()
                                if sortOption == .title {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        // Artist option
                        Button(action: { sortOption = .artist }) {
                            HStack {
                                Image(systemName: "person")
                                Text("By Artist")
                                Spacer()
                                if sortOption == .artist {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        // Plays option
                        Button(action: { sortOption = .plays }) {
                            HStack {
                                Image(systemName: "play.circle")
                                Text("Most Played")
                                Spacer()
                                if sortOption == .plays {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        // Recent option
                        Button(action: { sortOption = .recent }) {
                            HStack {
                                Image(systemName: "clock")
                                Text("Recently Played")
                                Spacer()
                                if sortOption == .recent {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                
                if viewModel.currentSong != nil {
                    Spacer()
                        .frame(height: 80) // Match the 80pt padding
                }
                
                // Songs list
                VStack(alignment: .leading) {
                    ForEach(songs) { song in
                        SongRow(song: song)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(playlist.name)
    }
    
    // Sort songs based on selected option
    private func sortedSongs(_ songs: [Song]) -> [Song] {
        switch sortOption {
        case .default:
            return songs
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
        }
    }
}

// Sort options enum for playlists and libraries
enum SortOption {
    case `default`, title, artist, plays, recent
}
