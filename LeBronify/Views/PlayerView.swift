//
//  PlayerView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI
import AVFoundation

// Sheet types for PlayerView
enum PlayerSheetType: Identifiable {
    case queue
    case addToPlaylist

    var id: Int {
        switch self {
        case .queue: return 1
        case .addToPlaylist: return 2
        }
    }
}

struct PlayerView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var playCountObserver: NSObjectProtocol? = nil
    @State private var activeSheet: PlayerSheetType?
    @State private var isDraggingSlider = false
    @State private var dragPosition: Double? = nil

    // LeBronify dark palette
    private let bgColor = Color(red: 0.07, green: 0.07, blue: 0.07)
    private let cardColor = Color(red: 0.11, green: 0.11, blue: 0.11)
    private let accentYellow = Color.yellow

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic gradient background based on current song
                if viewModel.currentSong != nil {
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.25), bgColor],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .ignoresSafeArea()
                } else {
                    bgColor.ignoresSafeArea()
                }

                if let song = viewModel.currentSong {
                    // Use ScrollViewReader to avoid gesture conflicts
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            playerContent(song: song, geometry: geometry)
                        }
                        .padding(.bottom, 100)
                    }
                    // Disable scroll when dragging slider to prevent conflict
                    .scrollDisabled(isDraggingSlider)
                } else {
                    emptyState(geometry: geometry)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .queue:
                QueueView()
            case .addToPlaylist:
                if let currentSong = viewModel.currentSong {
                    AddToPlaylistViewWrapper(song: currentSong)
                        .environmentObject(viewModel)
                }
            }
        }
        .onAppear { setupPlayCountObserver() }
        .onDisappear {
            if let observer = playCountObserver {
                NotificationCenter.default.removeObserver(observer)
                playCountObserver = nil
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Player Content

    @ViewBuilder
    private func playerContent(song: Song, geometry: GeometryProxy) -> some View {
        let artSize = min(geometry.size.width - 48, 340)

        VStack(spacing: 24) {
            // Album art
            Image(song.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: artSize, height: artSize)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                .padding(.top, 24)

            // Song info
            VStack(spacing: 6) {
                Text(song.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(.horizontal, 24)

            // Progress bar
            progressBar(geometry: geometry)

            // Main playback controls
            playbackControls

            // Secondary action row
            actionRow(song: song)

            // Queue preview
            queuePreview
        }
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private func progressBar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 6) {
            // Custom slim progress bar
            GeometryReader { sliderGeometry in
                let currentTime = dragPosition ?? viewModel.currentPlaybackTime
                let progress = viewModel.duration > 0
                    ? currentTime / viewModel.duration
                    : 0.0

                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: max(0, min(sliderGeometry.size.width * progress, sliderGeometry.size.width)), height: 4)

                    // Thumb - appears on drag
                    Circle()
                        .fill(Color.white)
                        .frame(width: isDraggingSlider ? 14 : 0, height: isDraggingSlider ? 14 : 0)
                        .offset(x: max(0, min(sliderGeometry.size.width * progress - 7, sliderGeometry.size.width - 14)))
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDraggingSlider = true
                            let fraction = max(0, min(value.location.x / sliderGeometry.size.width, 1.0))
                            dragPosition = fraction * viewModel.duration
                        }
                        .onEnded { value in
                            let fraction = max(0, min(value.location.x / sliderGeometry.size.width, 1.0))
                            let seekTime = fraction * viewModel.duration
                            viewModel.seek(to: seekTime)
                            dragPosition = nil
                            isDraggingSlider = false
                        }
                )
            }
            .frame(height: 20)
            .padding(.horizontal, 24)

            // Time labels
            HStack {
                Text(formatTime(dragPosition ?? viewModel.currentPlaybackTime))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Text("-" + formatTime(max(0, viewModel.duration - (dragPosition ?? viewModel.currentPlaybackTime))))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 0) {
            // Shuffle
            Button { viewModel.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.queueManager.shuffleEnabled ? accentYellow : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)

            // Previous
            Button { viewModel.previousSong() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            // Play/Pause
            Button { viewModel.togglePlayPause() } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)

                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.black)
                        .offset(x: viewModel.isPlaying ? 0 : 2)
                }
            }
            .frame(maxWidth: .infinity)

            // Next
            Button { viewModel.nextSong() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            // Repeat
            Button { viewModel.cycleRepeatMode() } label: {
                Image(systemName: repeatIcon)
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.queueManager.repeatMode == .off ? .white.opacity(0.6) : accentYellow)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Action Row

    @ViewBuilder
    private func actionRow(song: Song) -> some View {
        HStack(spacing: 0) {
            actionButton(
                icon: song.isFavorite ? "star.fill" : "star",
                label: "All-Star",
                color: song.isFavorite ? .yellow : .white.opacity(0.5)
            ) {
                viewModel.toggleFavorite(for: song.id)
                if let updated = viewModel.allSongs.first(where: { $0.id == song.id }) {
                    viewModel.currentSong = updated
                }
            }

            actionButton(icon: "list.bullet", label: "Queue", color: .white.opacity(0.5)) {
                activeSheet = .queue
            }

            actionButton(icon: "plus.circle", label: "Playbook", color: .white.opacity(0.5)) {
                activeSheet = .addToPlaylist
            }

            actionButton(icon: "sparkles", label: "Mix", color: .white.opacity(0.5)) {
                viewModel.playRandomPresetQueue()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(height: 24)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Queue Preview

    @ViewBuilder
    private var queuePreview: some View {
        let queue = viewModel.queueManager.currentQueue
        let currentIdx = viewModel.queueManager.queueIndex
        let upNext = currentIdx + 1 < queue.count ? Array(queue[(currentIdx + 1)..<min(currentIdx + 4, queue.count)]) : []

        if !upNext.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("On The Bench")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        activeSheet = .queue
                    } label: {
                        Text("Open Queue")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)

                ForEach(upNext) { song in
                    HStack(spacing: 12) {
                        Image(song.albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(4)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(song.artist)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.playSong(song)
                    }
                }
            }
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyState(geometry: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 80)

            Image("lebron_default")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .cornerRadius(90)
                .shadow(color: .yellow.opacity(0.3), radius: 20)

            Text("LEBRONIFY")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.yellow)

            Text("The King's Parody Collection")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))

            Text("\"I'm not playing right now,\nbut I'm always ready.\"")
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(.yellow.opacity(0.5))
                .multilineTextAlignment(.center)
                .italic()

            Button {
                if let song = viewModel.allSongs.randomElement() {
                    viewModel.playSong(song)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Let The King Play")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(accentYellow)
                .cornerRadius(25)
            }
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Helpers

    private var repeatIcon: String {
        switch viewModel.queueManager.repeatMode {
        case .off: return "repeat"
        case .all: return "repeat.circle.fill"
        case .one: return "repeat.1.circle.fill"
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func setupPlayCountObserver() {
        playCountObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PlayCountUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let songID = userInfo["songID"] as? UUID,
               let currentSong = self.viewModel.currentSong,
               currentSong.id == songID {
                if let updatedSong = self.viewModel.allSongs.first(where: { $0.id == songID }) {
                    DispatchQueue.main.async {
                        self.viewModel.currentSong = updatedSong
                    }
                }
            }
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
            .environmentObject(LeBronifyViewModel())
    }
}
