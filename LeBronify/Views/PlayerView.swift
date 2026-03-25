//
//  PlayerView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI
import AVFoundation
import UIKit

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
    @State private var dominantColor: Color = .yellow

    // LeBronify dark palette
    private let bgColor = Color(red: 0.07, green: 0.07, blue: 0.07)
    private let accentYellow = Color.yellow

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic gradient background based on album art color
                if viewModel.currentSong != nil {
                    LinearGradient(
                        colors: [dominantColor.opacity(0.45), bgColor],
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
        .onChange(of: viewModel.currentSong?.id) { _ in
            updateDominantColor()
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
        .onAppear {
            setupPlayCountObserver()
            updateDominantColor()
        }
        .onDisappear {
            if let observer = playCountObserver {
                NotificationCenter.default.removeObserver(observer)
                playCountObserver = nil
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Player Content (Scrollable, Spotify-style)

    @ViewBuilder
    private func playerContent(song: Song, geometry: GeometryProxy) -> some View {
        let artSize = geometry.size.width - 48

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Large album art - Spotify style
                Image(song.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: artSize, height: artSize)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                    .padding(.top, 16)

                Spacer().frame(height: 28)

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

                Spacer().frame(height: 20)

                // Progress bar
                progressBar(geometry: geometry)

                Spacer().frame(height: 20)

                // Main playback controls
                playbackControls

                Spacer().frame(height: 28)

                // Secondary action row
                actionRow(song: song)

                Spacer().frame(height: 28)

                // Queue preview - showing next 6 songs
                queuePreview

                Spacer().frame(height: 24)
            }
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

            actionButton(icon: "trash", label: "Clear", color: .white.opacity(0.5)) {
                viewModel.clearQueue()
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
        let upNext = currentIdx + 1 < queue.count ? Array(queue[(currentIdx + 1)..<min(currentIdx + 7, queue.count)]) : []

        if !upNext.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
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

    private func updateDominantColor() {
        guard let song = viewModel.currentSong,
              let uiImage = UIImage(named: song.albumArt) else {
            dominantColor = .yellow
            return
        }

        // Render into a CGContext with explicit RGBA byte order so we know the channel layout
        let w = 80
        let h = 80
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // Use RGBA with non-premultiplied alpha so bytes are always [R, G, B, A]
        guard let context = CGContext(
            data: nil,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            dominantColor = .yellow
            return
        }
        context.draw(uiImage.cgImage!, in: CGRect(x: 0, y: 0, width: w, height: h))

        guard let ptr = context.data?.assumingMemoryBound(to: UInt8.self) else {
            dominantColor = .yellow
            return
        }

        let bytesPerPixel = 4
        let bytesPerRow = w * 4

        // Quantize each pixel's RGB to 4-bit per channel (16 levels each = 4096 possible colors)
        // Count raw frequency — the color that appears most wins
        var colorCounts: [Int: Int] = [:]  // quantized color key -> pixel count
        var colorTotals: [Int: (r: CGFloat, g: CGFloat, b: CGFloat)] = [:]  // accumulated actual RGB

        for y in 0..<h {
            for x in 0..<w {
                let offset = y * bytesPerRow + x * bytesPerPixel
                // Byte order is guaranteed RGBA by the context we created
                let r = CGFloat(ptr[offset]) / 255.0
                let g = CGFloat(ptr[offset + 1]) / 255.0
                let b = CGFloat(ptr[offset + 2]) / 255.0

                // Skip near-black and near-white pixels (not useful for gradient)
                let maxC = max(r, g, b)
                let minC = min(r, g, b)
                if maxC < 0.08 { continue }  // very dark
                if minC > 0.90 { continue }  // very white

                // Quantize to 4 bits per channel
                let qr = Int(r * 15.0)
                let qg = Int(g * 15.0)
                let qb = Int(b * 15.0)
                let key = (qr << 8) | (qg << 4) | qb

                colorCounts[key, default: 0] += 1
                let prev = colorTotals[key] ?? (0, 0, 0)
                colorTotals[key] = (prev.r + r, prev.g + g, prev.b + b)
            }
        }

        // Find the quantized color with the highest pixel count
        guard let (bestKey, bestCount) = colorCounts.max(by: { $0.value < $1.value }),
              bestCount > 0,
              let totals = colorTotals[bestKey] else {
            withAnimation(.easeInOut(duration: 0.6)) { dominantColor = .yellow }
            return
        }

        // Average the actual RGB values in that bucket for accuracy
        let count = CGFloat(bestCount)
        var avgR = totals.r / count
        var avgG = totals.g / count
        var avgB = totals.b / count

        // If the winner is too gray/muted, boost saturation slightly for a nicer gradient
        let maxVal = max(avgR, avgG, avgB)
        let minVal = min(avgR, avgG, avgB)
        let sat = maxVal > 0 ? (maxVal - minVal) / maxVal : 0

        if sat < 0.2 && maxVal > 0.15 {
            // Very desaturated — boost by pulling channels apart from the mean
            let mean = (avgR + avgG + avgB) / 3.0
            avgR = mean + (avgR - mean) * 2.0
            avgG = mean + (avgG - mean) * 2.0
            avgB = mean + (avgB - mean) * 2.0
            avgR = max(0, min(1, avgR))
            avgG = max(0, min(1, avgG))
            avgB = max(0, min(1, avgB))
        }

        // Ensure brightness is high enough for a visible gradient
        let brightness = max(avgR, avgG, avgB)
        if brightness < 0.4 {
            let boost = 0.4 / brightness
            avgR = min(1.0, avgR * boost)
            avgG = min(1.0, avgG * boost)
            avgB = min(1.0, avgB * boost)
        }

        let result = Color(red: Double(avgR), green: Double(avgG), blue: Double(avgB))

        withAnimation(.easeInOut(duration: 0.6)) {
            dominantColor = result
        }
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
