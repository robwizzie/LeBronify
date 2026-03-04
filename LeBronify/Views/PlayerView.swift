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
    private let accentYellow = Color.yellow

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic gradient background
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
                    // Fixed layout - NO ScrollView so progress bar gestures work
                    playerContent(song: song, geometry: geometry)
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

    // MARK: - Player Content (Fixed Layout)

    @ViewBuilder
    private func playerContent(song: Song, geometry: GeometryProxy) -> some View {
        // Calculate album art size based on available space
        let safeHeight = geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
        let artSize = min(geometry.size.width - 64, safeHeight * 0.38, 320)

        VStack(spacing: 0) {
            // Album art - takes up flexible space
            Image(song.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: artSize, height: artSize)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                .padding(.top, 16)

            Spacer().frame(minHeight: 8, maxHeight: 20)

            // Song info
            VStack(spacing: 4) {
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

            Spacer().frame(minHeight: 8, maxHeight: 16)

            // Progress bar - NO ScrollView wrapping this, so gestures work perfectly
            progressBar(geometry: geometry)

            Spacer().frame(minHeight: 4, maxHeight: 12)

            // Main playback controls
            playbackControls

            Spacer().frame(minHeight: 4, maxHeight: 12)

            // Secondary action row
            actionRow(song: song)

            Spacer().frame(minHeight: 8, maxHeight: 20)

            // Queue preview - compact, showing next 2 songs
            queuePreview

            Spacer().frame(minHeight: 0)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private func progressBar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 6) {
            GeometryReader { sliderGeometry in
                let currentTime = dragPosition ?? viewModel.currentPlaybackTime
                let progress = viewModel.duration > 0
                    ? currentTime / viewModel.duration
                    : 0.0

                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: max(0, min(sliderGeometry.size.width * progress, sliderGeometry.size.width)), height: 4)

                    // Thumb - visible on drag
                    Circle()
                        .fill(Color.white)
                        .frame(width: isDraggingSlider ? 14 : 0, height: isDraggingSlider ? 14 : 0)
                        .offset(x: max(0, min(sliderGeometry.size.width * progress - 7, sliderGeometry.size.width - 14)))
                        .animation(.easeOut(duration: 0.1), value: isDraggingSlider)
                }
                .frame(height: 24)
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
            .frame(height: 24)
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
            Button { viewModel.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.queueManager.shuffleEnabled ? accentYellow : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)

            Button { viewModel.previousSong() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

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

            Button { viewModel.nextSong() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

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

    // MARK: - Queue Preview (compact)

    @ViewBuilder
    private var queuePreview: some View {
        let queue = viewModel.queueManager.currentQueue
        let currentIdx = viewModel.queueManager.queueIndex
        let upNext = currentIdx + 1 < queue.count ? Array(queue[(currentIdx + 1)..<min(currentIdx + 3, queue.count)]) : []

        if !upNext.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("On The Bench")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Button {
                        activeSheet = .queue
                    } label: {
                        Text("See All")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                ForEach(upNext) { song in
                    HStack(spacing: 10) {
                        Image(song.albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 34, height: 34)
                            .cornerRadius(4)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(song.title)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(song.artist)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.4))
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.playSong(song)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyState(geometry: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            Spacer()

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
