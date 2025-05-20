//
//  HomeView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var scrollViewHeight: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var showTacoRain = false
    @State private var shouldShowInitialTacos = true
    @State private var tacoObserver: NSObjectProtocol? = nil
    @State private var playCountObserver: NSObjectProtocol? = nil
    
    var body: some View {
        ZStack {
            // Main content
            NavigationView {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Taco Tuesday Banner (only on Tuesdays)
                            if TacoTuesdayManager.shared.isTacoTuesday {
                                tacoTuesdayBanner
                            }
                            
                            // Header
                            HeaderView()
                            
                            // Random song button
                            RandomSongButton()
                            
                            // LeBron song of the day
                            SongOfDaySection()
                            
                            // Recently played section
                            if !viewModel.recentlyPlayedSongs.isEmpty {
                                PlaylistRow(
                                    title: "Recently Played",
                                    songs: viewModel.recentlyPlayedSongs
                                )
                            }
                            
                            // Top hits section
                            if !viewModel.topHitsSongs.isEmpty {
                                PlaylistRow(
                                    title: "Top Hits",
                                    songs: viewModel.topHitsSongs
                                )
                            }
                            
                            // Featured playlists
                            PlaylistsSection(selectedTab: $selectedTab)
                            
                            // All songs section
                            AllSongsSection()
                        }
                        .padding(.vertical)
                        .padding(.bottom, viewModel.currentSong != nil ? 80 : 0)
                        .background(
                            // This invisible view helps measure the content height
                            GeometryReader { contentGeometry in
                                Color.clear.preference(
                                    key: ViewHeightKey.self,
                                    value: contentGeometry.size.height
                                )
                            }
                        )
                    }
                    .onPreferenceChange(ViewHeightKey.self) { height in
                        scrollViewHeight = height
                    }
                }
                .navigationBarHidden(true)
            }
            
            // Taco rain overlay - only shown when the taco song is playing or initially for 10 seconds
            if (showTacoRain || (shouldShowInitialTacos && TacoTuesdayManager.shared.isTacoTuesday)) {
                TacoRain()
                    .allowsHitTesting(false)
                    .zIndex(1000)
            }
        }
        .onAppear {
            viewModel.loadData()
            
            // Initial taco rain when view appears on Tuesdays
            if TacoTuesdayManager.shared.isTacoTuesday && shouldShowInitialTacos {
                // Start initial tacos for 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showTacoRain = true
                    }
                }
                
                // Auto-hide after 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    withAnimation {
                        showTacoRain = false
                        shouldShowInitialTacos = false
                    }
                }
            }
            
            // Set up notification observer for taco song state changes
            setupTacoNotifications()
        }
        .onDisappear {
            // Clean up notification observers
            cleanupObservers()
        }
    }
    
    // Set up notification observers for taco song state
    private func setupTacoNotifications() {
        // Store the observer so we can remove it later
        tacoObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TacoSongStateChanged"),
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let isPlaying = userInfo["isPlaying"] as? Bool else {
                return
            }
            
            // Only show tacos when taco song is actively playing
            if self.viewModel.isTacoSongPlaying && isPlaying {
                withAnimation {
                    self.showTacoRain = true
                }
            } else {
                withAnimation {
                    self.showTacoRain = false
                }
            }
        }
        
        // Setup observer for play count updates
        playCountObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PlayCountUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            print("HomeView: Received play count update notification")
            
            // When a play count is updated, we need to refresh the dynamic playlists
            // which show songs based on play count
            DispatchQueue.main.async {
                // Make sure we get the latest data
                self.viewModel.refreshDynamicPlaylists()
                
                // Force UI refresh for any song rows showing play counts
                if let userInfo = notification.userInfo,
                   let songID = userInfo["songID"] as? UUID {
                    print("HomeView: Refreshing UI for song with ID: \(songID)")
                }
            }
        }
    }
    
    // Cleanup both observers when view disappears
    private func cleanupObservers() {
        if let observer = tacoObserver {
            NotificationCenter.default.removeObserver(observer)
            tacoObserver = nil
        }
        
        if let observer = playCountObserver {
            NotificationCenter.default.removeObserver(observer)
            playCountObserver = nil
        }
    }
    
    // Taco Tuesday Banner - styled to match the app's design
    var tacoTuesdayBanner: some View {
        ZStack {
            // Background with gradient similar to HeaderView
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.yellow, .orange]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 4)
            
            // Content
            VStack(spacing: 12) {
                Text("TACO TUESDAYYYYY")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                
                Image(TacoTuesdayManager.shared.tacoTuesdayAlbumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.3), radius: 5)
                
                Button(action: {
                    let tacoSong = TacoTuesdayManager.shared.createTacoTuesdaySong()
                    viewModel.playSong(tacoSong)
                    
                    // The notification system will handle showing tacos
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.headline)
                        Text("Play Taco Tuesday Song")
                            .font(.headline)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .foregroundColor(.orange)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.2), radius: 2)
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
        .frame(height: 240)
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

// MARK: - Component Views

// Header component
struct HeaderView: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("lebron_banner")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            
            // Gradient overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .cornerRadius(12)
            
            // Title
            VStack(alignment: .leading) {
                Text("LEBRONIFY")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("The King's Parody Collection")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

// Random Song Button
struct RandomSongButton: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        Button(action: {
            viewModel.playRandomSong()
        }) {
            HStack {
                Image(systemName: "shuffle")
                    .font(.headline)
                Text("Random LeBron Song")
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.yellow)
            .foregroundColor(.black)
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// Song of the Day Section
struct SongOfDaySection: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LeBron Song of the Day")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if let songOfTheDay = viewModel.getSongOfTheDay() {
                HStack {
                    Image(songOfTheDay.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text(songOfTheDay.title)
                            .font(.headline)
                        Text(songOfTheDay.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.playSong(songOfTheDay)
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

// Playlists Section
struct PlaylistsSection: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var selectedTab: Int
    @State private var showingAddPlaylist = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Playlists")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingAddPlaylist = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Separate user playlists from system playlists
            let userPlaylists = viewModel.playlists.filter { !$0.isSystem }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Only show user-created playlists here 
                    ForEach(userPlaylists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist, selectedTab: $selectedTab)) {
                            VStack(alignment: .leading) {
                                // Use the helper to get the appropriate image view
                                playlist.getImageView(size: 150)
                                
                                Text(playlist.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text(playlist.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                // Show song count
                                Text("\(viewModel.getSongs(for: playlist).count) songs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 150)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingAddPlaylist) {
            PlaylistEditorViewWrapper()
                .environmentObject(viewModel)
        }
    }
}

// All Songs Section
struct AllSongsSection: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Songs")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(viewModel.allSongs) { song in
                SongRow(song: song)
                    .padding(.horizontal)
            }
        }
    }
}

// AD Overlay View
struct ADOverlayView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text(viewModel.currentAd?.title ?? "AD BREAK")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Image(viewModel.currentAd?.imageName ?? "anthony_davis_default")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 300)
                    .cornerRadius(12)
                
                Text(viewModel.currentAd?.message ?? "")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: {
                    viewModel.dismissAd()
                }) {
                    Text("Skip AD (Trade to Dallas)")
                        .font(.headline)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
            }
            .padding()
            .zIndex(100) // Ensure AD appears above everything
        }
    }
}

// Helper to get view height
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(LeBronifyViewModel())
    }
}
