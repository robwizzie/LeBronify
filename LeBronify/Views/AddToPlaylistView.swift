//
//  AddToPlaylistView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/29/25.
//

import SwiftUI

struct AddToPlaylistView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    // Song to add
    let song: Song
    
    // State for the sheet
    @State private var showingCreatePlaylist = false
    @State private var showingSuccessAlert = false
    @State private var selectedPlaylistID: UUID?
    @State private var successMessage = ""
    
    // Colors for the UI
    private let gradientColors = [Color.indigo.opacity(0.7), Color.blue.opacity(0.3)]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: gradientColors), 
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack {
                    // Song info header
                    SongInfoHeader(song: song)
                        .padding()
                    
                    Text("Add to Playlist")
                        .font(.headline)
                        .padding(.top)
                    
                    // Playlist list with add buttons
                    ScrollView {
                        VStack(spacing: 10) {
                            // Create new playlist button
                            Button(action: {
                                showingCreatePlaylist = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Create New Playlist")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Divider
                            Divider()
                                .background(Color.white.opacity(0.5))
                                .padding(.vertical, 5)
                            
                            // List of existing playlists
                            if viewModel.playlists.isEmpty {
                                Text("No playlists yet")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(viewModel.playlists) { playlist in
                                    PlaylistRowWithAddButton(
                                        playlist: playlist,
                                        song: song,
                                        onAddSong: { addSongToPlaylist(playlist) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlaylist) {
                PlaylistEditorView()
                    .environmentObject(viewModel)
            }
            .alert(isPresented: $showingSuccessAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text(successMessage),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func addSongToPlaylist(_ playlist: Playlist) {
        viewModel.addSongToPlaylist(songID: song.id, playlistID: playlist.id)
        successMessage = "\"\(song.title)\" added to \"\(playlist.name)\" playlist"
        showingSuccessAlert = true
    }
}

// Helper view for displaying song info
struct SongInfoHeader: View {
    let song: Song
    
    var body: some View {
        HStack(spacing: 15) {
            // Album art
            Image(song.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 70, height: 70)
                .cornerRadius(8)
                .shadow(radius: 3)
            
            // Song details
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Duration and other metadata
                HStack {
                    Text(formatDuration(song.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if song.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if song.playCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(song.playCount) plays")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// Playlist row with add button
struct PlaylistRowWithAddButton: View {
    let playlist: Playlist
    let song: Song
    let onAddSong: () -> Void
    
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    // Compute if song is already in this playlist
    private var songIsInPlaylist: Bool {
        return playlist.songIDs.contains(song.id)
    }
    
    var body: some View {
        HStack {
            // Playlist image
            Group {
                if playlist.coverImage.hasPrefix("playlist_") {
                    // Custom image from documents directory
                    CustomPlaylistImageView(imageName: playlist.coverImage)
                        .frame(width: 50, height: 50)
                        .cornerRadius(5)
                } else {
                    // System image
                    Image(systemName: playlist.coverImage)
                        .font(.system(size: 24))
                        .frame(width: 50, height: 50)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(5)
                }
            }
            .shadow(radius: 2)
            
            // Playlist details
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(viewModel.getSongs(for: playlist).count) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Add button or Already Added indicator
            if songIsInPlaylist {
                Text("Already Added")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(15)
            } else {
                Button(action: onAddSong) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

// Custom view for loading custom playlist images
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

#Preview {
    let previewSong = Song(
        title: "King James",
        artist: "LeBron James",
        duration: 180,
        audioFileName: "king_james.mp3",
        albumArt: "album_cover_king_james"
    )
    
    return AddToPlaylistView(song: previewSong)
        .environmentObject(LeBronifyViewModel())
} 