//
//  UIComponents.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI
import UIKit
import Combine

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

// Song row component for listing songs - Spotify-inspired
struct SongRow: View {
    let song: Song
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var playCount: Int
    @State private var playCountObserver: NSObjectProtocol?
    @State private var showingAddToPlaylist = false

    init(song: Song) {
        self.song = song
        self._playCount = State(initialValue: song.playCount)
    }

    var body: some View {
        Button { viewModel.playSong(song) } label: {
            HStack(spacing: 12) {
                // Album art
                ZStack(alignment: .topLeading) {
                    Image(song.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .cornerRadius(4)

                    if let rank = song.topRank(in: viewModel.allSongs) {
                        TopSongBadge(rank: rank)
                            .scaleEffect(0.7)
                            .offset(x: -6, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(song.artist)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)

                        if playCount > 0 {
                            Text("·")
                                .foregroundColor(.white.opacity(0.3))
                            Text("\(playCount) plays")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }
                }

                Spacer()

                // Ellipsis menu
                Menu {
                    Button { viewModel.playSong(song) } label: {
                        Label("Play Now", systemImage: "play.fill")
                    }
                    Button {
                        viewModel.playNext(song)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Label("Play Next", systemImage: "text.insert")
                    }
                    Button {
                        viewModel.addToQueue(song)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Add to Queue", systemImage: "list.bullet")
                    }
                    Divider()
                    Button { showingAddToPlaylist = true } label: {
                        Label("Add to Playlist", systemImage: "plus.rectangle.on.folder")
                    }
                    Button { viewModel.toggleFavorite(for: song.id) } label: {
                        Label(
                            song.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: song.isFavorite ? "heart.fill" : "heart"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingAddToPlaylist) {
            AddToPlaylistViewWrapper(song: song)
                .environmentObject(viewModel)
        }
        .onAppear { setupPlayCountObserver() }
        .onDisappear {
            if let observer = playCountObserver {
                NotificationCenter.default.removeObserver(observer)
                playCountObserver = nil
            }
        }
    }

    private func setupPlayCountObserver() {
        if let observer = playCountObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        playCountObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PlayCountUpdated"),
            object: nil, queue: .main
        ) { notification in
            if let songID = notification.userInfo?["songID"] as? UUID, songID == song.id {
                if let updated = self.viewModel.allSongs.first(where: { $0.id == songID }) {
                    self.playCount = updated.playCount
                }
            } else {
                if let updated = self.viewModel.allSongs.first(where: { $0.id == song.id }) {
                    self.playCount = updated.playCount
                }
            }
        }
    }
}

// Playlist row for horizontal scrolling
struct PlaylistRow: View {
    let title: String
    let songs: [Song]
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(songs) { song in
                        // Use a dedicated SongCardView with play count tracking
                        SongCardView(song: song, isTopHit: title == "Top Hits")
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Card view for songs in horizontal scrolling playlists
struct SongCardView: View {
    let song: Song
    let isTopHit: Bool
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var playCount: Int
    @State private var playCountObserver: NSObjectProtocol?
    @State private var showingAddToPlaylist = false
    
    init(song: Song, isTopHit: Bool = false) {
        self.song = song
        self.isTopHit = isTopHit
        self._playCount = State(initialValue: song.playCount)
    }
    
    var body: some View {
        Button { viewModel.playSong(song) } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topLeading) {
                    Image(song.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 130, height: 130)
                        .cornerRadius(8)

                    if let rank = song.topRank(in: viewModel.allSongs), isTopHit {
                        TopSongBadge(rank: rank)
                            .scaleEffect(0.8)
                            .offset(x: -4, y: -4)
                    }
                }

                Text(song.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .frame(width: 130)
        }
        .contextMenu {
            Button(action: {
                viewModel.playSong(song)
            }) {
                Label("Play Now", systemImage: "play.fill")
            }
            
            Button(action: {
                viewModel.playNext(song)
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }) {
                Label("Play Next", systemImage: "text.insert")
            }
            
            Button(action: {
                viewModel.addToQueue(song)
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                Label("Add to Queue", systemImage: "list.bullet")
            }
            
            Button {
                showingAddToPlaylist = true
            } label: {
                Label("Add to Playlist", systemImage: "plus.rectangle.on.folder")
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
        }
        .sheet(isPresented: $showingAddToPlaylist) {
            AddToPlaylistViewWrapper(song: song)
                .environmentObject(viewModel)
        }
        .onAppear {
            // Setup observer to update when play counts change
            setupPlayCountObserver()
        }
        .onDisappear {
            // Clean up observers
            if let observer = playCountObserver {
                NotificationCenter.default.removeObserver(observer)
                playCountObserver = nil
            }
        }
    }
    
    private func setupPlayCountObserver() {
        // Clean up any existing observer first
        if let observer = playCountObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Create a new observer
        playCountObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PlayCountUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            if let songID = notification.userInfo?["songID"] as? UUID, songID == song.id {
                // Direct update for this specific song
                if let updatedSong = self.viewModel.allSongs.first(where: { $0.id == songID }) {
                    self.playCount = updatedSong.playCount
                }
            } else {
                // General refresh - find updated song in viewModel
                if let updatedSong = self.viewModel.allSongs.first(where: { $0.id == song.id }) {
                    self.playCount = updatedSong.playCount
                }
            }
        }
    }
}

// Mini player that appears at bottom of screen - Spotify-inspired design
struct MiniPlayerView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedTab: Int
    @State private var showingQueueView = false

    private let miniPlayerBg = Color(red: 0.14, green: 0.14, blue: 0.14)

    var body: some View {
        VStack(spacing: 0) {
            // Thin progress bar at top
            GeometryReader { geo in
                let progress = viewModel.duration > 0
                    ? viewModel.currentPlaybackTime / viewModel.duration
                    : 0.0
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                    Rectangle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 2)

            // Main content
            HStack(spacing: 12) {
                // Tappable song info
                Button {
                    selectedTab = 1
                } label: {
                    HStack(spacing: 10) {
                        if let currentSong = viewModel.currentSong {
                            Image(currentSong.albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 42, height: 42)
                                .cornerRadius(4)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .foregroundColor(.white.opacity(0.3))
                                )
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(viewModel.currentSong?.title ?? "Not Playing")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(viewModel.currentSong?.artist ?? "")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // Compact controls
                HStack(spacing: 20) {
                    Button { viewModel.togglePlayPause() } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    Button { viewModel.nextSong() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(miniPlayerBg)
        .shadow(color: .black.opacity(0.3), radius: 8, y: -2)
        .onTapGesture {
            selectedTab = 1
        }
    }
}

// This view shows details for a playlist
struct PlaylistDetailView: View {
    let playlist: Playlist
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var sortOption: SortOption = .default
    @Binding var selectedTab: Int
    @State private var showingEditPlaylist = false
    
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
                    // Use the helper to get the appropriate image view
                    playlist.getImageView(size: 120)
                    
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
                    
                    // Edit button - only for non-system playlists
                    if !playlist.isSystem {
                        Button(action: {
                            showingEditPlaylist = true
                        }) {
                            Image(systemName: "pencil.circle")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                
                // Play all button and sort options
                HStack {
                    Button(action: {
                        // Play all songs
                        viewModel.playPlaylist(playlist)
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play All")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    // Add Shuffle button
                    Button(action: {
                        // Play shuffled
                        viewModel.playPlaylist(playlist, shuffled: true)
                    }) {
                        HStack {
                            Image(systemName: "shuffle")
                            Text("Shuffle")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button("Default") {
                            sortOption = .default
                        }
                        Button("By Title") {
                            sortOption = .title
                        }
                        Button("By Artist") {
                            sortOption = .artist
                        }
                        Button("By Play Count") {
                            sortOption = .plays
                        }
                        Button("Most Recent") {
                            sortOption = .recent
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // Song list
                if songs.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("This playlist is empty")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        if selectedTab == 0 { // Only show button if in library (tab 0)
                            Button(action: {
                                // Switch to all songs tab to add songs
                                selectedTab = 2 // Assuming "All Songs" is tab 2
                            }) {
                                Text("Add Songs")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                } else {
                    // Song list with dividers
                    ForEach(songs) { song in
                        VStack(spacing: 0) {
                            SongRow(song: song)
                                .padding(.horizontal)
                            
                            Divider()
                                .padding(.leading, 90)
                        }
                    }
                }
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditPlaylist) {
            PlaylistEditorViewWrapper(playlist: playlist)
                .environmentObject(viewModel)
        }
    }
    
    // Helper function to sort songs based on the selected sort option
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
            return songs.sorted { ($0.lastPlayed ?? Date.distantPast) > ($1.lastPlayed ?? Date.distantPast) }
        }
    }
}

// Sort options enum for playlists and libraries
enum SortOption {
    case `default`, title, artist, plays, recent
}

// Create simple wrappers for views that aren't in scope
struct AddToPlaylistViewWrapper: View {
    let song: Song
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingCreatePlaylist = false
    
    var body: some View {
        // Simplified version of AddToPlaylistView
        NavigationView {
            List {
                Section(header: Text("Select a playlist")) {
                    // Filter out system playlists to prevent adding to them
                    let userPlaylists = viewModel.playlists.filter { !$0.isSystem }
                    
                    if userPlaylists.isEmpty {
                        Text("You don't have any custom playlists yet.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(userPlaylists) { playlist in
                            Button(action: {
                                viewModel.addSongToPlaylist(songID: song.id, playlistID: playlist.id)
                            }) {
                                HStack {
                                    // Use the helper to get the appropriate image view
                                    playlist.getImageView(size: 40)
                                    
                                    VStack(alignment: .leading) {
                                        Text(playlist.name)
                                            .font(.headline)
                                        Text("\(viewModel.getSongs(for: playlist).count) songs")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Add button to create a new playlist
                Section {
                    Button(action: {
                        // Open playlist creator
                        showingCreatePlaylist = true
                    }) {
                        Label("Create New Playlist", systemImage: "plus.circle")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Add to Playlist")
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Cannot Add Song"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingCreatePlaylist) {
                PlaylistEditorViewWrapper()
                    .environmentObject(viewModel)
            }
        }
    }
}

struct PlaylistEditorViewWrapper: View {
    var playlist: Playlist?
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var playlistName: String = ""
    @State private var playlistDescription: String = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]), 
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Image selector
                        ZStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(10)
                            } else if let existingPlaylist = playlist, existingPlaylist.coverImage.hasPrefix("playlist_") {
                                // Custom image for existing playlist
                                CustomPlaylistImageView(imageName: existingPlaylist.coverImage)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(10)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        Image(systemName: playlist?.coverImage ?? "music.note.list")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .offset(x: 50, y: 50)
                        }
                        .padding(.top, 30)
                        
                        // Input fields
                        VStack(spacing: 15) {
                            TextField("Playlist Name", text: $playlistName)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .accentColor(.white)
                            
                            TextField("Description", text: $playlistDescription)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .accentColor(.white)
                        }
                        .padding(.horizontal)
                        
                        // Create/Update button
                        Button(action: {
                            if playlistName.isEmpty {
                                alertMessage = "Please enter a playlist name"
                                showingAlert = true
                                return
                            }
                            
                            if let existingPlaylist = playlist {
                                viewModel.updatePlaylist(
                                    id: existingPlaylist.id,
                                    name: playlistName,
                                    description: playlistDescription,
                                    coverImage: existingPlaylist.coverImage,
                                    customImage: selectedImage
                                )
                            } else {
                                viewModel.createPlaylist(
                                    name: playlistName, 
                                    description: playlistDescription,
                                    coverImage: "music.note.list",
                                    customImage: selectedImage
                                )
                            }
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(playlist == nil ? "Create Playlist" : "Update Playlist")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .disabled(playlistName.isEmpty)
                        .opacity(playlistName.isEmpty ? 0.5 : 1.0)
                        .padding(.top, 20)
                    }
                }
                .onAppear {
                    if let playlist = playlist {
                        // Don't allow editing system playlists
                        if playlist.isSystem {
                            alertMessage = "System playlists cannot be modified"
                            showingAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        
                        playlistName = playlist.name
                        playlistDescription = playlist.description
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(selectedImage: $selectedImage)
                }
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Playlist Error"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationTitle(playlist == nil ? "Create Playlist" : "Edit Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Image picker using UIKit
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// Add CustomPlaylistImageView to ensure it's available in this file
struct CustomPlaylistImageView: View {
    let imageName: String
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        // Get documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // Build path to the image
        let playlistImagesDirectory = documentsDirectory.appendingPathComponent("PlaylistImages")
        let fileURL = playlistImagesDirectory.appendingPathComponent(imageName)
        
        // Load the image
        do {
            let imageData = try Data(contentsOf: fileURL)
            if let loadedImage = UIImage(data: imageData) {
                self.image = loadedImage
            }
        } catch {
            print("Error loading playlist image: \(error)")
        }
    }
}

// Helper extension to handle playlist images consistently throughout the app
extension Playlist {
    // Returns the appropriate View for displaying this playlist's image
    @ViewBuilder
    func getImageView(size: CGFloat) -> some View {
        if isSystem {
            // System playlists use asset images
            if ["lebron_recent", "lebron_top", "lebron_favorites"].contains(coverImage) {
                Image(coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .cornerRadius(size * 0.1)
                    .shadow(radius: 2)
            } else {
                // Fallback for other system playlists
                Image(systemName: "music.note.list")
                    .resizable()
                    .padding(size * 0.2)
                    .frame(width: size, height: size)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(size * 0.1)
            }
        } else if coverImage.hasPrefix("playlist_") {
            // Custom uploaded image
            CustomPlaylistImageView(imageName: coverImage)
                .frame(width: size, height: size)
                .cornerRadius(size * 0.1)
        } else {
            // System SF Symbol
            Image(systemName: coverImage)
                .resizable()
                .scaledToFit()
                .padding(size * 0.25)
                .frame(width: size, height: size)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(size * 0.1)
        }
    }
}
