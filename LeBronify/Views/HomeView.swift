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

    var body: some View {
        ZStack {
            NavigationView {
                ZStack(alignment: .top) {
                    Theme.background.ignoresSafeArea()

                    // Brand tint bleeding down from the top of the scroll view
                    Theme.ambientGradient
                        .frame(height: 380)
                        .ignoresSafeArea(edges: .top)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            GreetingBar()

                            // Taco Tuesday Banner (only on Tuesdays)
                            if TacoTuesdayManager.shared.isTacoTuesday {
                                tacoTuesdayBanner
                            }

                            HeaderView()
                            RandomSongButton()
                            ProcessMeterView()
                            SongOfDaySection()

                            if !viewModel.recentlyPlayedSongs.isEmpty {
                                JumpBackInSection()
                                PlaylistRow(title: "Recent Highlights", songs: viewModel.recentlyPlayedSongs)
                            }

                            if !viewModel.topHitsSongs.isEmpty {
                                PlaylistRow(title: "MVP Selections", songs: viewModel.topHitsSongs)
                            }

                            PlaylistsSection(selectedTab: $selectedTab)
                            Starting5Section()
                            AllSongsSection()
                        }
                        .padding(.vertical)
                        .padding(.bottom, viewModel.currentSong != nil ? 90 : 8)
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
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Theme.liberty],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("TACO TUESDAYYYYY")
                    .font(Theme.display(26))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 2)

                Image(TacoTuesdayManager.shared.tacoTuesdayAlbumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .cornerRadius(10)

                Button {
                    viewModel.playSong(TacoTuesdayManager.shared.createTacoTuesdaySong())
                    Haptics.medium()
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
                    .clipShape(Capsule())
                }
                .pressable()
            }
            .padding()
        }
        .frame(height: 220)
        .padding(.horizontal)
    }
}

// MARK: - Component Views

/// Time-aware greeting plus a quick shuffle shortcut.
struct GreetingBar: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5: return "Still up?"
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(Theme.display(24))
                    .foregroundColor(Theme.textPrimary)

                Text("Welcome to South Philly")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            Button {
                viewModel.playSongs(viewModel.allSongs, shuffled: true)
                Haptics.medium()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Theme.royal.opacity(0.9))
                    .clipShape(Circle())
            }
            .pressable()
        }
        .padding(.horizontal)
    }
}

struct HeaderView: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("lebron_banner")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .clipped()

            // Brand wash over the photo so it reads Sixers rather than Lakers
            LinearGradient(
                colors: [Theme.royal.opacity(0.55), .clear, Theme.navy.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("LEBRONIFY")
                        .font(Theme.display(32))
                        .foregroundColor(.white)

                    Text("PHL")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.liberty)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }

                Text("The King's Parody Collection")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(16)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct RandomSongButton: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        Button {
            viewModel.playRandomSong()
            Haptics.medium()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                Text("Let The King Decide")
            }
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .padding(.horizontal)
    }
}

/// Two-column grid of recently played songs — one tap back into what you were playing.
struct JumpBackInSection: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Jump Back In", subtitle: "Pick up where you left off")

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(viewModel.recentlyPlayedSongs.prefix(6))) { song in
                    Button {
                        viewModel.playSong(song)
                        Haptics.light()
                    } label: {
                        HStack(spacing: 10) {
                            Image(song.albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipped()

                            Text(song.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .padding(.trailing, 6)

                            Spacer(minLength: 0)
                        }
                        .frame(height: 48)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                    }
                    .pressable()
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SongOfDaySection: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "LeBron's Pick of the Day")

            if let song = viewModel.getSongOfTheDay() {
                Button {
                    viewModel.playSong(song)
                    Haptics.medium()
                } label: {
                    HStack(spacing: 14) {
                        Image(song.albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 72, height: 72)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("TODAY'S STARTER")
                                .eyebrowStyle(color: Theme.liberty)

                            Text(song.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)

                            Text(song.artist)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Theme.brandGradient)
                                .frame(width: 42, height: 42)

                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .offset(x: 1)
                        }
                    }
                    .padding(14)
                    .surfaceCard()
                }
                .pressable()
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
            SectionHeader(title: "Playbooks") {
                Button {
                    showingAddPlaylist = true
                    Haptics.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Draft")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.accentText)
                }
            }

            let userPlaylists = viewModel.playlists.filter { !$0.isSystem }

            if userPlaylists.isEmpty {
                Text("No playbooks drafted yet. Tap Draft to build your first lineup.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textTertiary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(userPlaylists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist, selectedTab: $selectedTab)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    playlist.getImageView(size: 140)

                                    Text(playlist.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                        .lineLimit(1)

                                    Text("\(viewModel.getSongs(for: playlist).count) songs")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textTertiary)
                                }
                                .frame(width: 140)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showingAddPlaylist) {
            PlaylistEditorViewWrapper()
                .environmentObject(viewModel)
        }
    }
}

struct Starting5Section: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var showingShareCard = false

    var body: some View {
        let hasPlays = viewModel.allSongs.contains { $0.playCount > 0 }
        if hasPlays {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "GOAT Debate")

                Button {
                    showingShareCard = true
                    Haptics.light()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Theme.liberty)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("My Starting 5")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Share your top played songs")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.accentText)
                    }
                    .padding(16)
                    .surfaceCard()
                }
                .pressable()
                .padding(.horizontal)
            }
            .sheet(isPresented: $showingShareCard) {
                ShareCardGeneratorView()
                    .environmentObject(viewModel)
            }
        }
    }
}

struct AllSongsSection: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "The Full Roster", subtitle: "\(viewModel.allSongs.count) tracks deep")

            ForEach(viewModel.allSongs.sorted { $0.playCount > $1.playCount }) { song in
                SongRow(song: song)
                    .padding(.horizontal)
            }
        }
    }
}

struct ADOverlayView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var selectedTab: Int
    @State private var dismissButtonVisible = false
    @State private var waitMessage = "AD is warming up..."
    @State private var adDismissText = "Skip AD"

    private let dismissTexts = [
        "Trade AD to Dallas",
        "Send AD to the Bench",
        "Waive AD",
        "AD Fouled Out - Skip",
        "AD is Day-to-Day - Skip",
        "Put AD on Injured Reserve",
    ]

    private let waitMessages = [
        "AD is warming up...",
        "The Brow demands your attention...",
        "AD stretching on the sideline...",
        "Commercial timeout...",
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tapping background also dismisses once button is visible
                    if dismissButtonVisible { dismissAndNavigate() }
                }

            VStack(spacing: 20) {
                Text(viewModel.currentAd?.title ?? "AD BREAK")
                    .font(Theme.display(28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Image(viewModel.currentAd?.imageName ?? "anthony_davis_default")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))

                Text(viewModel.currentAd?.message ?? "")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if dismissButtonVisible {
                    Button {
                        dismissAndNavigate()
                    } label: {
                        Text(adDismissText)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Theme.brandGradient)
                            .clipShape(Capsule())
                    }
                    .pressable()
                    .transition(.opacity.combined(with: .scale))
                } else {
                    Text(waitMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .padding()
        }
        .onAppear {
            waitMessage = waitMessages.randomElement() ?? "AD is warming up..."
            adDismissText = dismissTexts.randomElement() ?? "Skip AD"
            // Show dismiss button after 2 seconds - quick enough to not be annoying
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring()) { dismissButtonVisible = true }
            }
        }
    }

    private func dismissAndNavigate() {
        Haptics.light()
        viewModel.dismissAd()
        // Smoothly navigate to Now Playing after dismissing
        if viewModel.currentSong != nil {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 1
            }
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
