//
//  LibraryView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI
import UIKit

// Import PlaylistEditorView and CustomPlaylistImageView

// Since PlaylistEditorView is in the same module, we don't actually need to explicitly import it.
// The error might be because CustomPlaylistImageView is defined in UIComponents.swift but not
// properly recognized. Let's define it here if it's still not found after building.

struct LibraryView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var selectedTab = 0
    @State private var showingAddPlaylist = false
    @State private var sortOption: SortOption = .title
    
    // Updated to only include Playlists and Favorites
    var tabs = ["Playlists", "Favorites"]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 1)
                    
                    // Custom tab selector
                    TabSelectorView(tabs: tabs, selectedTab: $selectedTab, screenWidth: geometry.size.width)
                    
                    // Content for selected tab - only two tabs now
                    TabView(selection: $selectedTab) {
                        // PLAYLISTS TAB
                        PlaylistsTabView(showingAddPlaylist: $showingAddPlaylist)
                            .tag(0)
                        
                        // FAVORITES TAB
                        FavoritesTabView(sortOption: $sortOption)
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                .navigationBarTitle("Your Library", displayMode: .large)
            }
        }
        .sheet(isPresented: $showingAddPlaylist) {
            // Use PlaylistEditorViewWrapper just like in HomeView for consistency
            PlaylistEditorViewWrapper()
                .environmentObject(viewModel)
        }
    }
}

// Tab selector view
struct TabSelectorView: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    let screenWidth: CGFloat
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        selectedTab = index
                    }) {
                        VStack(spacing: 8) {
                            Text(tabs[index])
                                .font(.headline)
                                .fontWeight(selectedTab == index ? .bold : .regular)
                                .foregroundColor(selectedTab == index ? .primary : .secondary)
                                .lineLimit(1)
                                .padding(.horizontal, 5)
                            
                            // Indicator for selected tab
                            Rectangle()
                                .frame(height: 3)
                                .foregroundColor(selectedTab == index ? .yellow : .clear)
                        }
                    }
                    .frame(width: screenWidth / CGFloat(min(tabs.count, 4)))
                }
            }
        }
        .padding(.horizontal)
    }
}

// Playlists tab view
struct PlaylistsTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var showingAddPlaylist: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Your Playlists")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddPlaylist = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Playlist")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if viewModel.playlists.isEmpty {
                    EmptyPlaylistsView(showingAddPlaylist: $showingAddPlaylist)
                        .padding(.top, 50)
                } else {
                    // Separate playlists by type
                    let systemPlaylists = viewModel.playlists.filter { $0.isSystem }
                    let userPlaylists = viewModel.playlists.filter { !$0.isSystem }
                    
                    // System playlists section
                    if !systemPlaylists.isEmpty {
                        Text("System Playlists")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ForEach(systemPlaylists) { playlist in
                            PlaylistRowView(playlist: playlist)
                        }
                    }
                    
                    // User playlists section
                    if !userPlaylists.isEmpty {
                        Text("Your Custom Playlists")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ForEach(userPlaylists) { playlist in
                            PlaylistRowView(playlist: playlist)
                        }
                    }
                }
                
                // Add padding at bottom for mini player
                if viewModel.currentSong != nil {
                    Spacer()
                        .frame(height: 70)
                }
            }
        }
    }
}

// Empty playlists view
struct EmptyPlaylistsView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var showingAddPlaylist: Bool
    
    init(showingAddPlaylist: Binding<Bool>? = nil) {
        self._showingAddPlaylist = showingAddPlaylist ?? .constant(false)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("You don't have any playlists yet")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddPlaylist = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create a Playlist")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Playlist row view
struct PlaylistRowView: View {
    let playlist: Playlist
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
            HStack(spacing: 12) {
                // Use the helper to get the appropriate image view
                playlist.getImageView(size: 70)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(playlist.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text("\(viewModel.getSongs(for: playlist).count) songs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

// Artists tab view
struct ArtistsTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var sortOption: SortOption
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Artists")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    SortMenuView(sortOption: $sortOption, showRecent: false)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Get unique artists
                let artists = Array(Set(viewModel.allSongs.map { $0.artist })).sorted()
                
                ForEach(artists, id: \.self) { artist in
                    ArtistSectionView(artist: artist, sortOption: sortOption)
                }
                
                // Space for mini player if needed
                if viewModel.currentSong != nil {
                    Spacer()
                        .frame(height: 70)
                }
            }
        }
    }
}

// Artist section view
struct ArtistSectionView: View {
    let artist: String
    let sortOption: SortOption
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(artist)
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            let artistSongs = sortSongs(viewModel.allSongs.filter { $0.artist == artist })
            
            ForEach(artistSongs) { song in
                SongRow(song: song)
                    .padding(.horizontal)
            }
        }
    }
    
    private func sortSongs(_ songs: [Song]) -> [Song] {
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

// Categories tab view
struct CategoriesTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var sortOption: SortOption
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Categories")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        SortMenuView(sortOption: $sortOption, showRecent: false)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Get unique categories
                    let allCategories = viewModel.allSongs.flatMap { $0.categories }
                    let categories = Array(Set(allCategories)).sorted()
                    
                    ForEach(categories, id: \.self) { category in
                        CategorySectionView(category: category, sortOption: sortOption)
                            .frame(width: geometry.size.width)
                    }
                    
                    // Space for mini player if needed
                    if viewModel.currentSong != nil {
                        Spacer()
                            .frame(height: 80)
                    }
                }
            }
        }
    }
}

// Category section view
struct CategorySectionView: View {
    let category: String
    let sortOption: SortOption
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(category)
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            let categorySongs = sortSongs(viewModel.allSongs.filter { $0.categories.contains(category) })
            
            ForEach(categorySongs) { song in
                SongRow(song: song)
                    .padding(.horizontal)
            }
        }
    }
    
    private func sortSongs(_ songs: [Song]) -> [Song] {
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

// Favorites tab view
struct FavoritesTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var sortOption: SortOption
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Favorites")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    SortMenuView(sortOption: $sortOption, showRecent: true)
                }
                .padding(.horizontal)
                .padding(.top)
                
                let favorites = sortSongs(viewModel.allSongs.filter { $0.isFavorite })
                
                if favorites.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ForEach(favorites) { song in
                        SongRow(song: song)
                            .padding(.horizontal)
                    }
                }
                
                // Space for mini player if needed
                if viewModel.currentSong != nil {
                    Spacer()
                        .frame(height: 80)
                }
            }
        }
    }
    
    private func sortSongs(_ songs: [Song]) -> [Song] {
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

// Empty favorites view
struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .padding(.top, 50)
            
            Text("No favorites yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Tap the heart icon on any song to add it to your favorites")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

// Sort menu view
struct SortMenuView: View {
    @Binding var sortOption: SortOption
    let showRecent: Bool
    
    var body: some View {
        Menu {
            Button("Default") { sortOption = .default }
            Button("Alphabetical") { sortOption = .title }
            Button("Most Played") { sortOption = .plays }
            if showRecent {
                Button("Recently Played") { sortOption = .recent }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(.primary)
                .padding(8)
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .environmentObject(LeBronifyViewModel())
    }
}

// Wrapper for PlaylistEditorView
struct PlaylistCreatorView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        // Use this view to create a new playlist
        // It will internally use the PlaylistEditorView from the other file
        VStack {
            // This view structure should match what's in PlaylistEditorView.swift
            NavigationView {
                ZStack {
                    // Background gradient
                    LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]), 
                                   startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    
                    // Main content (simplified version)
                    ScrollView {
                        VStack(spacing: 20) {
                            // Form fields and controls would go here
                            // For now just showing a message
                            Text("Create a New Playlist")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                            
                            // Show message to call the developer to fix the issue
                            Text("This is a temporary workaround. Please rebuild the app to use the full playlist editor.")
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                }
                .navigationTitle("Create Playlist")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
