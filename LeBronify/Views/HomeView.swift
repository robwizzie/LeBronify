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
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var showTacoRain = false
    @State private var shouldShowInitialTacos = true
    @State private var tacoObserver: NSObjectProtocol? = nil
    @State private var playCountObserver: NSObjectProtocol? = nil

    private let bgColor = Color(red: 0.07, green: 0.07, blue: 0.07)

    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    bgColor.ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            // Taco Tuesday Banner (only on Tuesdays)
                            if TacoTuesdayManager.shared.isTacoTuesday {
                                tacoTuesdayBanner
                            }

                            HeaderView()
                            RandomSongButton()
                            SongOfDaySection()

                            if !viewModel.recentlyPlayedSongs.isEmpty {
                                PlaylistRow(title: "Recently Played", songs: viewModel.recentlyPlayedSongs)
                            }

                            if !viewModel.topHitsSongs.isEmpty {
                                PlaylistRow(title: "Top Hits", songs: viewModel.topHitsSongs)
                            }

                            PlaylistsSection(selectedTab: $selectedTab)
                            AllSongsSection()
                        }
                        .padding(.vertical)
                        .padding(.bottom, viewModel.currentSong != nil ? 80 : 0)
                    }
                }
                .navigationBarHidden(true)
            }

            if showTacoRain || (shouldShowInitialTacos && TacoTuesdayManager.shared.isTacoTuesday) {
                TacoRain()
                    .allowsHitTesting(false)
                    .zIndex(1000)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.loadData()
            if TacoTuesdayManager.shared.isTacoTuesday && shouldShowInitialTacos {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { showTacoRain = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    withAnimation { showTacoRain = false; shouldShowInitialTacos = false }
                }
            }
            setupTacoNotifications()
        }
        .onDisappear { cleanupObservers() }
    }

    private func setupTacoNotifications() {
        tacoObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TacoSongStateChanged"),
            object: nil, queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let isPlaying = userInfo["isPlaying"] as? Bool else { return }
            withAnimation {
                self.showTacoRain = self.viewModel.isTacoSongPlaying && isPlaying
            }
        }

        playCountObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PlayCountUpdated"),
            object: nil, queue: .main
        ) { _ in
            DispatchQueue.main.async {
                self.viewModel.refreshDynamicPlaylists()
            }
        }
    }

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

    // Taco Tuesday Banner
    var tacoTuesdayBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("TACO TUESDAYYYYY")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 2)

                Image(TacoTuesdayManager.shared.tacoTuesdayAlbumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .cornerRadius(10)

                Button {
                    viewModel.playSong(TacoTuesdayManager.shared.createTacoTuesdaySong())
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("Play Taco Tuesday")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .foregroundColor(.orange)
                    .cornerRadius(25)
                }
            }
            .padding()
        }
        .frame(height: 220)
        .padding(.horizontal)
    }
}

// MARK: - Component Views

struct HeaderView: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("lebron_banner")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .clipped()
                .cornerRadius(16)

            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            .cornerRadius(16)

            VStack(alignment: .leading, spacing: 4) {
                Text("LEBRONIFY")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("The King's Parody Collection")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
        }
        .padding(.horizontal)
    }
}

struct RandomSongButton: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        Button { viewModel.playRandomSong() } label: {
            HStack(spacing: 8) {
                Image(systemName: "shuffle")
                    .font(.system(size: 16, weight: .bold))
                Text("Shuffle Play")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.yellow)
            .cornerRadius(25)
        }
        .padding(.horizontal)
    }
}

struct SongOfDaySection: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    private let cardColor = Color(red: 0.11, green: 0.11, blue: 0.11)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Song of the Day")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal)

            if let song = viewModel.getSongOfTheDay() {
                HStack(spacing: 14) {
                    Image(song.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(song.artist)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    Spacer()

                    Button { viewModel.playSong(song) } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 42))
                            .foregroundColor(Color.yellow)
                    }
                }
                .padding(14)
                .background(cardColor)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

struct PlaylistsSection: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var selectedTab: Int
    @State private var showingAddPlaylist = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Playlists")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    showingAddPlaylist = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("New")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal)

            let userPlaylists = viewModel.playlists.filter { !$0.isSystem }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(userPlaylists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist, selectedTab: $selectedTab)) {
                            VStack(alignment: .leading, spacing: 6) {
                                playlist.getImageView(size: 140)

                                Text(playlist.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text("\(viewModel.getSongs(for: playlist).count) songs")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .frame(width: 140)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingAddPlaylist) {
            PlaylistEditorViewWrapper()
                .environmentObject(viewModel)
        }
    }
}

struct AllSongsSection: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Songs")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal)

            ForEach(viewModel.allSongs) { song in
                SongRow(song: song)
                    .padding(.horizontal)
            }
        }
    }
}

struct ADOverlayView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    private let dismissTexts = [
        "Trade AD to Dallas",
        "Send AD to the Bench",
        "Waive AD",
        "AD Fouled Out - Skip",
        "AD is Day-to-Day - Skip",
        "Put AD on Injured Reserve",
    ]

    private var adDismissText: String {
        dismissTexts.randomElement() ?? "Skip AD"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(viewModel.currentAd?.title ?? "AD BREAK")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Image(viewModel.currentAd?.imageName ?? "anthony_davis_default")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 280)
                    .cornerRadius(12)

                Text(viewModel.currentAd?.message ?? "")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button { viewModel.dismissAd() } label: {
                    Text(adDismissText)
                        .font(.system(size: 15, weight: .bold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(25)
                }
            }
            .padding()
        }
    }
}

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
