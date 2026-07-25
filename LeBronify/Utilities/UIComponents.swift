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
                .fill(Theme.brandGradient)
                .frame(width: 24, height: 24)
                .shadow(color: Theme.royal.opacity(0.6), radius: 3)

            Text("\(rank)")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.white)
        }
    }
}

/// Three little equalizer bars that bounce while a track is playing.
/// Gives every list a clear "you are here" marker.
struct NowPlayingIndicator: View {
    let isAnimating: Bool

    @State private var animating = false

    // Differing peaks and durations keep the bars out of sync with each other
    private let peaks: [CGFloat] = [14, 8, 16]
    private let durations: [Double] = [0.50, 0.38, 0.62]

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Theme.accentText)
                    .frame(width: 2.5, height: animating ? peaks[index] : 4)
                    .animation(
                        animating
                            ? .easeInOut(duration: durations[index]).repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.2),
                        value: animating
                    )
            }
        }
        .frame(width: 14, height: 16, alignment: .bottom)
        .onAppear { animating = isAnimating }
        .onChange(of: isAnimating) {
            animating = isAnimating
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

    private var isNowPlaying: Bool {
        viewModel.currentSong?.id == song.id
    }

    var body: some View {
        Button {
            viewModel.playSong(song)
            Haptics.light()
        } label: {
            HStack(spacing: 12) {
                // Album art
                ZStack(alignment: .topLeading) {
                    Image(song.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))

                    if let rank = song.topRank(in: viewModel.allSongs) {
                        TopSongBadge(rank: rank)
                            .scaleEffect(0.7)
                            .offset(x: -6, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.system(size: 15, weight: isNowPlaying ? .bold : .medium))
                        .foregroundColor(isNowPlaying ? Theme.accentText : Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(song.artist)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)

                        if playCount > 0 {
                            Text("·")
                                .foregroundColor(Theme.textTertiary)
                            Text("\(playCount) plays")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }

                Spacer()

                // Live equalizer bars mark the track that's currently playing
                if isNowPlaying {
                    NowPlayingIndicator(isAnimating: viewModel.isPlaying)
                        .padding(.trailing, 2)
                }

                // Ellipsis menu
                Menu {
                    Button { viewModel.playSong(song) } label: {
                        Label("Play Now", systemImage: "play.fill")
                    }
                    Button {
                        viewModel.playNext(song)
                        Haptics.medium()
                    } label: {
                        Label("Up Next", systemImage: "text.insert")
                    }
                    Button {
                        viewModel.addToQueue(song)
                        Haptics.light()
                    } label: {
                        Label("Add to Queue", systemImage: "list.bullet")
                    }
                    Divider()
                    Button { showingAddToPlaylist = true } label: {
                        Label("Add to Playbook", systemImage: "plus.rectangle.on.folder")
                    }
                    Button {
                        if song.isFavorite {
                            viewModel.performTheDecision(song: song) {
                                viewModel.toggleFavorite(for: song.id)
                            }
                        } else {
                            viewModel.toggleFavorite(for: song.id)
                        }
                    } label: {
                        Label(
                            song.isFavorite ? "Remove from All-Stars" : "Crown as All-Star",
                            systemImage: song.isFavorite ? "star.fill" : "star"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .fill(isNowPlaying ? Theme.royal.opacity(0.14) : Color.clear)
            )
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
            
            Button {
                if song.isFavorite {
                    viewModel.performTheDecision(song: song) {
                        viewModel.toggleFavorite(for: song.id)
                    }
                } else {
                    viewModel.toggleFavorite(for: song.id)
                }
            } label: {
                Label(
                    song.isFavorite ? "Remove from All-Stars" : "Crown as All-Star",
                    systemImage: song.isFavorite ? "star.fill" : "star"
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

// Mini player that appears at bottom of screen - polished LeBronify design
struct MiniPlayerView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedTab: Int

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Brand-gradient progress bar at top
            GeometryReader { geo in
                let progress = viewModel.duration > 0
                    ? viewModel.currentPlaybackTime / viewModel.duration
                    : 0.0
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                    Rectangle()
                        .fill(Theme.brandGradient)
                        .frame(width: max(0, geo.size.width * progress))
                }
            }
            .frame(height: 3)

            // Main content
            HStack(spacing: 12) {
                // Album art + song info - tappable to go to Now Playing
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 1
                    }
                    Haptics.light()
                } label: {
                    HStack(spacing: 10) {
                        if let currentSong = viewModel.currentSong {
                            Image(currentSong.albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                        } else {
                            RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .foregroundColor(Theme.textTertiary)
                                )
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.currentSong?.title ?? "Not Playing")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                            Text(viewModel.currentSong?.artist ?? "LeBronify")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // Playback controls
                HStack(spacing: 18) {
                    Button {
                        viewModel.previousSong()
                        Haptics.light()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textPrimary.opacity(0.85))
                            .frame(width: 28, height: 28)
                    }
                    Button {
                        viewModel.togglePlayPause()
                        Haptics.medium()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Theme.brandGradient)
                                .frame(width: 34, height: 34)
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .offset(x: viewModel.isPlaying ? 0 : 1)
                        }
                    }
                    .pressable(scale: 0.9)
                    Button {
                        viewModel.nextSong()
                        Haptics.light()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textPrimary.opacity(0.85))
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Theme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 12, y: -4)
        .padding(.horizontal, 6)
        .offset(x: dragOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: dragOffset)
        // Swipe horizontally to skip tracks, swipe up to open the full player.
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        dragOffset = value.translation.width * 0.3
                    }
                }
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height

                    if abs(horizontal) > abs(vertical) {
                        if horizontal < -50 {
                            viewModel.nextSong()
                            Haptics.medium()
                        } else if horizontal > 50 {
                            viewModel.previousSong()
                            Haptics.medium()
                        }
                    } else if vertical < -40 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = 1
                        }
                        Haptics.light()
                    }

                    dragOffset = 0
                }
        )
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
                            .font(Theme.title(24))
                            .foregroundColor(Theme.textPrimary)

                        Text(playlist.description)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)

                        Text("\(songs.count) songs")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textTertiary)
                    }

                    Spacer()

                    // Edit button - only for non-system playlists
                    if !playlist.isSystem {
                        Button(action: {
                            showingEditPlaylist = true
                            Haptics.light()
                        }) {
                            Image(systemName: "pencil.circle")
                                .font(.title)
                                .foregroundColor(Theme.accentText)
                        }
                    }
                }
                .padding()

                // Play all button and sort options
                HStack(spacing: 10) {
                    Button(action: {
                        // Play all songs
                        viewModel.playPlaylist(playlist)
                        Haptics.medium()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Play All")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Theme.brandGradient)
                        .clipShape(Capsule())
                    }
                    .pressable()

                    // Add Shuffle button
                    Button(action: {
                        // Play shuffled
                        viewModel.playPlaylist(playlist, shuffled: true)
                        Haptics.medium()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "shuffle")
                            Text("Shuffle")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .pressable()

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
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal)

                // Song list
                if songs.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 56))
                            .foregroundColor(Theme.royal.opacity(0.5))

                        Text("This playbook is empty")
                            .font(Theme.title(18))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        if selectedTab == 0 { // Only show button if in library (tab 0)
                            Button(action: {
                                // Switch to all songs tab to add songs
                                selectedTab = 2 // Assuming "All Songs" is tab 2
                                Haptics.light()
                            }) {
                                Text("Add Songs")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Theme.brandGradient)
                                    .clipShape(Capsule())
                            }
                            .pressable()
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
                                .overlay(Theme.stroke)
                                .padding(.leading, 90)
                        }
                    }
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditPlaylist) {
            PlaylistEditorViewWrapper(playlist: playlist)
                .environmentObject(viewModel)
        }
    }
    
    // Helper function to sort songs based on the selected sort option
    private func sortedSongs(_ songs: [Song]) -> [Song] {
        songs.sorted(using: sortOption)
    }
}

// Sort options enum for playlists and libraries
enum SortOption {
    case `default`, title, artist, plays, recent
}

extension Array where Element == Song {
    /// Single home for the song-sorting logic that used to be copy-pasted into
    /// every list view.
    func sorted(using option: SortOption) -> [Song] {
        switch option {
        case .default:
            return self
        case .title:
            return sorted { $0.title < $1.title }
        case .artist:
            return sorted { $0.artist < $1.artist }
        case .plays:
            return sorted { $0.playCount > $1.playCount }
        case .recent:
            return sorted { ($0.lastPlayed ?? Date.distantPast) > ($1.lastPlayed ?? Date.distantPast) }
        }
    }
}

// MARK: - Technical Foul Overlay (Flop Counter)

struct TechnicalFoulOverlay: View {
    @Binding var isShowing: Bool
    @State private var showContent = false
    @State private var dismissText = "I wasn't flopping!"

    private let messages = [
        "Stop flopping! This isn't the playoffs!",
        "The refs are watching... stop faking those pauses!",
        "LeBron never flops... okay maybe sometimes.",
        "That's a flop! Even Vlade Divac is impressed.",
        "Pause abuse detected. The league office will review this.",
        "You've been fined $50,000 for flopping. Just kidding.",
    ]

    private let dismissTexts = [
        "I wasn't flopping!",
        "Challenge the call",
        "Accept the foul",
        "Review the play",
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    if showContent { isShowing = false }
                }

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.5), radius: 10)

                Text("TECHNICAL FOUL!")
                    .font(Theme.display(28))
                    .foregroundColor(Theme.liberty)

                Text(messages.randomElement() ?? messages[0])
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    isShowing = false
                    Haptics.light()
                } label: {
                    Text(dismissText)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Theme.brandGradient)
                        .clipShape(Capsule())
                }
                .pressable()
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.5)
        }
        .onAppear {
            dismissText = dismissTexts.randomElement() ?? dismissTexts[0]
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                isShowing = false
            }
        }
    }
}

// MARK: - The Decision Overlay

struct TheDecisionOverlay: View {
    let song: Song
    let destination: String
    let onComplete: () -> Void
    @State private var phase = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                if phase >= 0 {
                    // Breaking News banner
                    Text("BREAKING NEWS")
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(4)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Theme.liberty)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if phase >= 1 {
                    // Song album art
                    Image(song.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                }

                if phase >= 2 {
                    // The reveal
                    VStack(spacing: 12) {
                        Text("\"\(song.title)\"")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("is taking its talents to South Beach... I mean Broad Street...")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .italic()
                    }
                    .transition(.opacity)
                }

                if phase >= 3 {
                    // The destination
                    Text(destination.uppercased())
                        .font(Theme.display(26))
                        .foregroundStyle(Theme.brandGradient)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            // Phase 0: Breaking news (immediate)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                phase = 0
            }
            // Phase 1: Show album art
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { phase = 1 }
            }
            // Phase 2: "Taking its talents..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 0.3)) { phase = 2 }
            }
            // Phase 3: Destination reveal
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { phase = 3 }
            }
            // Complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete()
            }
        }
    }
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
                LinearGradient(
                    colors: [Theme.navy, Theme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
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
                                    .fill(Theme.royal.opacity(0.35))
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        Image(systemName: playlist?.coverImage ?? "music.note.list")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                    )
                            }

                            Button(action: {
                                showingImagePicker = true
                                Haptics.light()
                            }) {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .padding(10)
                                    .background(Theme.brandGradient)
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
                                alertMessage = "Every team needs a name, King!"
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
                            Text(playlist == nil ? "Draft Playbook" : "Update Playbook")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.brandGradient)
                                .clipShape(Capsule())
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
    // Known asset image names used for playlist covers
    private static let assetCoverImages: Set<String> = [
        "lebron_recent", "lebron_top", "lebron_favorites",
        "lebron_lakers", "lebron_crown", "lebron_love",
        "lebron_ball", "lebron_meme", "lebron_default",
        "ilyaugust"
    ]

    @ViewBuilder
    func getImageView(size: CGFloat) -> some View {
        if Self.assetCoverImages.contains(coverImage) {
            // Asset catalog image (system playlists + category playlists)
            Image(coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipped()
                .cornerRadius(size * 0.1)
                .shadow(radius: 2)
        } else if coverImage.hasPrefix("playlist_") {
            // Custom uploaded image
            CustomPlaylistImageView(imageName: coverImage)
                .frame(width: size, height: size)
                .cornerRadius(size * 0.1)
        } else if UIImage(systemName: coverImage) != nil {
            // Valid SF Symbol
            Image(systemName: coverImage)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .padding(size * 0.25)
                .frame(width: size, height: size)
                .background(Theme.courtGradient)
                .cornerRadius(size * 0.1)
        } else {
            // Fallback
            Image(systemName: "music.note.list")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .padding(size * 0.2)
                .frame(width: size, height: size)
                .background(Theme.courtGradient)
                .cornerRadius(size * 0.1)
        }
    }
}
