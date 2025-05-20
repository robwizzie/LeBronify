//
//  PlaylistEditorView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/29/25.
//

import SwiftUI
import PhotosUI

struct PlaylistEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    // State for the form
    @State private var playlistName: String = ""
    @State private var playlistDescription: String = ""
    @State private var selectedSystemImage: String = "music.note.list"
    
    // Image picker state
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var useCustomImage: Bool = false
    
    // Alert state
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Edit mode
    private var editMode: Bool
    private var existingPlaylist: Playlist?
    
    // System images available for playlists
    private let systemImages = [
        "music.note.list", "music.mic", "music.quarternote.3", "headphones", 
        "beats.headphones", "airpodspro", "flame", "heart.fill", "star.fill", 
        "crown", "basketball.fill", "trophy.fill", "waveform", "guitars", "pianokeys"
    ]
    
    // Colors for the UI
    private let gradientColors = [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]
    
    init(playlist: Playlist? = nil) {
        self.existingPlaylist = playlist
        self.editMode = playlist != nil
        
        if let playlist = playlist {
            _playlistName = State(initialValue: playlist.name)
            _playlistDescription = State(initialValue: playlist.description)
            
            // Check if the cover image is a system image or custom
            if systemImages.contains(playlist.coverImage) {
                _selectedSystemImage = State(initialValue: playlist.coverImage)
                _useCustomImage = State(initialValue: false)
            } else {
                _selectedSystemImage = State(initialValue: "music.note.list") // Default
                _useCustomImage = State(initialValue: true)
                // We'll load the custom image in .onAppear
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: gradientColors), 
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Preview of selected image
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.1))
                                .frame(width: 200, height: 200)
                            
                            if useCustomImage, let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                // Display custom image if selected
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                // Display selected system image
                                Image(systemName: selectedSystemImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 220)
                        
                        // Image source picker
                        VStack(alignment: .leading) {
                            Text("Playlist Image")
                                .font(.headline)
                                .padding(.leading)
                            
                            // Toggle between custom and system image
                            Picker("Image Source", selection: $useCustomImage) {
                                Text("System Icon").tag(false)
                                Text("Custom Image").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            
                            if useCustomImage {
                                // PhotosPicker for custom image
                                PhotosPicker(selection: $selectedItem,
                                            matching: .images,
                                            photoLibrary: .shared()) {
                                    HStack {
                                        Image(systemName: "photo.fill")
                                        Text("Select Image")
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            } else {
                                // System image picker
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))]) {
                                    ForEach(systemImages, id: \.self) { imageName in
                                        Image(systemName: imageName)
                                            .font(.system(size: 32))
                                            .frame(width: 60, height: 60)
                                            .background(selectedSystemImage == imageName ? Color.blue.opacity(0.3) : Color.clear)
                                            .cornerRadius(8)
                                            .onTapGesture {
                                                selectedSystemImage = imageName
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Text fields for playlist details
                        VStack(alignment: .leading) {
                            Text("Playlist Name")
                                .font(.headline)
                                .padding(.leading)
                            
                            TextField("Enter playlist name", text: $playlistName)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            
                            Text("Description")
                                .font(.headline)
                                .padding(.leading)
                                .padding(.top, 5)
                            
                            TextEditor(text: $playlistDescription)
                                .frame(height: 100)
                                .padding(5)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        // Save button
                        Button(action: savePlaylist) {
                            Text(editMode ? "Update Playlist" : "Create Playlist")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(editMode ? "Edit Playlist" : "Create Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Attention"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onChange(of: selectedItem) { _ in
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
        .onAppear {
            loadExistingPlaylistImage()
        }
    }
    
    private func loadExistingPlaylistImage() {
        // If in edit mode and we have a custom image, load it
        if let playlist = existingPlaylist, useCustomImage {
            // Get documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            // Build path to the image
            let playlistImagesDirectory = documentsDirectory.appendingPathComponent("PlaylistImages")
            let fileURL = playlistImagesDirectory.appendingPathComponent(playlist.coverImage)
            
            // Try to load the image data
            do {
                let imageData = try Data(contentsOf: fileURL)
                selectedImageData = imageData
            } catch {
                print("Error loading existing playlist image: \(error)")
            }
        }
    }
    
    private func savePlaylist() {
        // Validate input
        guard !playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a playlist name."
            showingAlert = true
            return
        }
        
        // Create/update the playlist
        if useCustomImage, let imageData = selectedImageData, let image = UIImage(data: imageData) {
            // Use custom image
            if editMode, let playlist = existingPlaylist {
                // Update existing playlist with new custom image
                viewModel.updatePlaylist(
                    id: playlist.id,
                    name: playlistName,
                    description: playlistDescription,
                    customImage: image
                )
            } else {
                // Create new playlist with custom image
                viewModel.createPlaylist(
                    name: playlistName,
                    description: playlistDescription,
                    coverImage: "",
                    customImage: image
                )
            }
        } else {
            // Use system image
            if editMode, let playlist = existingPlaylist {
                // Update existing playlist with system image
                viewModel.updatePlaylist(
                    id: playlist.id,
                    name: playlistName,
                    description: playlistDescription,
                    coverImage: selectedSystemImage
                )
            } else {
                // Create new playlist with system image
                viewModel.createPlaylist(
                    name: playlistName,
                    description: playlistDescription,
                    coverImage: selectedSystemImage
                )
            }
        }
        
        // Close the view
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    PlaylistEditorView()
        .environmentObject(LeBronifyViewModel())
} 