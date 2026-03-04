//
//  QueueView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 5/14/25.
//

import SwiftUI

struct QueueView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isEditing = false

    // LeBronify dark palette
    private let bgColor = Color(red: 0.07, green: 0.07, blue: 0.07)
    private let cardColor = Color(red: 0.11, green: 0.11, blue: 0.11)
    private let accentYellow = Color.yellow

    var body: some View {
        NavigationView {
            ZStack {
                bgColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Drag indicator
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)

                    // Now Playing card
                    if let currentSong = viewModel.currentSong {
                        nowPlayingCard(currentSong)
                    }

                    // Up Next list
                    let upcoming = getUpcomingSongs()
                    if upcoming.isEmpty {
                        emptyQueueView
                    } else {
                        queueList(upcoming)
                    }

                    // Bottom controls
                    queueControls
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text("Queue")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(bgColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Now Playing Card

    @ViewBuilder
    private func nowPlayingCard(_ song: Song) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Image(song.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text("NOW PLAYING")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentYellow)
                        .tracking(1.2)

                    Text(song.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(song.artist)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                // Compact controls
                HStack(spacing: 20) {
                    Button { viewModel.previousSong() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }

                    Button { viewModel.togglePlayPause() } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.white)
                    }

                    Button { viewModel.nextSong() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 14)
        .background(cardColor)
    }

    // MARK: - Queue List

    @ViewBuilder
    private func queueList(_ upcoming: [(offset: Int, song: Song)]) -> some View {
        List {
            Section(header:
                HStack {
                    Text("UP NEXT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1)

                    Spacer()

                    Text("\(upcoming.count) \(upcoming.count == 1 ? "song" : "songs")")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.vertical, 4)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            ) {
                ForEach(Array(upcoming.enumerated()), id: \.element.offset) { displayIndex, item in
                    queueRow(song: item.song, displayIndex: displayIndex + 1, realIndex: item.offset)
                        .listRowBackground(bgColor)
                        .listRowSeparatorTint(Color.white.opacity(0.06))
                }
                .onMove { source, destination in
                    guard let sourceIndex = source.first else { return }
                    moveQueueItem(from: sourceIndex, to: destination, upcoming: upcoming)
                }
                .onDelete { indexSet in
                    removeSelectedItems(indexSet, upcoming: upcoming)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }

    @ViewBuilder
    private func queueRow(song: Song, displayIndex: Int, realIndex: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(displayIndex)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: 22, alignment: .trailing)

            Image(song.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .cornerRadius(4)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                viewModel.playSong(song)
            } label: {
                Image(systemName: "play.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                viewModel.removeFromQueue(at: realIndex)
            } label: {
                Label("Remove from Queue", systemImage: "minus.circle")
            }

            Button {
                viewModel.playSong(song)
            } label: {
                Label("Play Now", systemImage: "play.fill")
            }
        }
    }

    // MARK: - Empty Queue

    private var emptyQueueView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.yellow.opacity(0.3))

            Text("The King's queue is empty")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            Text("Even LeBron can't score without the ball.\nAdd some songs to get the party started!")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Bottom Controls

    private var queueControls: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.08))

            HStack(spacing: 0) {
                controlButton(
                    icon: "trash",
                    label: "Clear",
                    isActive: false,
                    disabled: getUpcomingSongs().isEmpty
                ) {
                    viewModel.clearQueue()
                }

                controlButton(
                    icon: viewModel.queueManager.shuffleEnabled ? "shuffle.circle.fill" : "shuffle",
                    label: "Shuffle",
                    isActive: viewModel.queueManager.shuffleEnabled
                ) {
                    viewModel.queueManager.toggleShuffle()
                }

                controlButton(
                    icon: repeatIcon,
                    label: "Repeat",
                    isActive: viewModel.queueManager.repeatMode != .off
                ) {
                    viewModel.queueManager.cycleRepeatMode()
                }

                controlButton(
                    icon: "sparkles",
                    label: "Mix",
                    isActive: false
                ) {
                    viewModel.playRandomPresetQueue()
                }
            }
            .padding(.vertical, 10)
        }
        .background(cardColor)
    }

    @ViewBuilder
    private func controlButton(icon: String, label: String, isActive: Bool, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? accentYellow : .white.opacity(disabled ? 0.2 : 0.6))
                    .frame(height: 26)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isActive ? accentYellow : .white.opacity(disabled ? 0.2 : 0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(disabled)
    }

    private var repeatIcon: String {
        switch viewModel.queueManager.repeatMode {
        case .off: return "repeat"
        case .all: return "repeat.circle.fill"
        case .one: return "repeat.1.circle.fill"
        }
    }

    // MARK: - Queue Data Helpers

    /// Returns upcoming songs as (realQueueIndex, song) tuples for proper index tracking
    private func getUpcomingSongs() -> [(offset: Int, song: Song)] {
        let queue = viewModel.queueManager.currentQueue
        let currentIndex = viewModel.queueManager.queueIndex
        let startIndex = currentIndex + 1

        guard startIndex < queue.count else { return [] }

        return queue[startIndex...].enumerated().map { (index, song) in
            (offset: startIndex + index, song: song)
        }
    }

    private func removeSelectedItems(_ indexSet: IndexSet, upcoming: [(offset: Int, song: Song)]) {
        // Remove in reverse order so indices don't shift
        let realIndices = indexSet.map { upcoming[$0].offset }.sorted(by: >)
        for realIndex in realIndices {
            viewModel.queueManager.removeFromQueue(at: realIndex)
        }
    }

    private func moveQueueItem(from source: Int, to destination: Int, upcoming: [(offset: Int, song: Song)]) {
        guard source < upcoming.count else { return }

        let realSource = upcoming[source].offset
        let realDestination: Int

        if destination >= upcoming.count {
            realDestination = viewModel.queueManager.currentQueue.count
        } else {
            realDestination = upcoming[destination].offset
        }

        viewModel.queueManager.moveItem(from: realSource, to: realDestination)
    }
}

struct QueueView_Previews: PreviewProvider {
    static var previews: some View {
        QueueView()
            .environmentObject(LeBronifyViewModel())
    }
}
