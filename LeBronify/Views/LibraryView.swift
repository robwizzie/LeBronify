//
//  LibraryView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI
import UIKit

struct LibraryView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var selectedTab = 0
    @State private var showingAddPlaylist = false
    @State private var sortOption: SortOption = .title

    var tabs = ["Playbooks", "All-Stars", "Trophies"]

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    VaultStatsBar()

                    TabSelectorView(tabs: tabs, selectedTab: $selectedTab)

                    TabView(selection: $selectedTab) {
                        PlaylistsTabView(showingAddPlaylist: $showingAddPlaylist)
                            .tag(0)
                        FavoritesTabView(sortOption: $sortOption)
                            .tag(1)
                        AchievementsTabView()
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarTitle("The Vault", displayMode: .large)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingAddPlaylist) {
            PlaylistEditorViewWrapper()
                .environmentObject(viewModel)
        }
    }
}

/// Three-up stat strip across the top of the Vault: plays, All-Stars, trophies.
struct VaultStatsBar: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        let totalPlays = viewModel.allSongs.reduce(0) { $0 + $1.playCount }
        let allStars = viewModel.allSongs.filter { $0.isFavorite }.count
        let trophies = viewModel.achievementManager.achievements.filter { $0.isUnlocked }.count

        HStack(spacing: 10) {
            statTile(value: "\(totalPlays)", label: "PLAYS", tint: Theme.royal)
            statTile(value: "\(allStars)", label: "ALL-STARS", tint: Theme.liberty)
            statTile(value: "\(trophies)", label: "TROPHIES", tint: Theme.royalBright)
        }
        .padding(.horizontal)
        .padding(.bottom, 14)
    }

    private func statTile(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.stat(20))
                .foregroundColor(tint)

            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(Theme.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .surfaceCard()
    }
}

// Tab selector view
struct TabSelectorView: View {
    let tabs: [String]
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) { selectedTab = index }
                    Haptics.selection()
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 15, weight: selectedTab == index ? .bold : .medium))
                            .foregroundColor(selectedTab == index ? Theme.textPrimary : Theme.textTertiary)
                            .lineLimit(1)

                        // Indicator for selected tab
                        Capsule()
                            .fill(selectedTab == index ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.clear))
                            .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
}

// Playlists tab view
struct PlaylistsTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var showingAddPlaylist: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Your Playbooks")
                        .font(Theme.title(20))
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    Button(action: {
                        showingAddPlaylist = true
                        Haptics.light()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("New Playbook")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.accentText)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                if viewModel.playlists.isEmpty {
                    EmptyPlaylistsView(showingAddPlaylist: $showingAddPlaylist)
                        .padding(.top, 50)
                } else {
                    // Separate playlists by type
                    let systemPlaylists = viewModel.playlists.filter { $0.isSystem }
                    let userPlaylists = viewModel.playlists.filter { !$0.isSystem }

                    // System playlists section
                    if !systemPlaylists.isEmpty {
                        Text("SYSTEM PLAYBOOKS")
                            .eyebrowStyle()
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ForEach(systemPlaylists) { playlist in
                            PlaylistRowView(playlist: playlist)
                        }
                    }

                    // User playlists section
                    if !userPlaylists.isEmpty {
                        Text("YOUR CUSTOM PLAYBOOKS")
                            .eyebrowStyle(color: Theme.liberty)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ForEach(userPlaylists) { playlist in
                            PlaylistRowView(playlist: playlist)
                        }
                    }
                }

                // Add padding at bottom for mini player
                if viewModel.currentSong != nil {
                    Spacer()
                        .frame(height: 90)
                }
            }
        }
    }
}

// Empty playlists view
struct EmptyPlaylistsView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var showingAddPlaylist: Bool

    init(showingAddPlaylist: Binding<Bool>? = nil) {
        self._showingAddPlaylist = showingAddPlaylist ?? .constant(false)
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "music.note.list")
                .font(.system(size: 56))
                .foregroundColor(Theme.royal.opacity(0.5))

            Text("No playbooks yet")
                .font(Theme.title(19))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Text("Build your own lineup like Morey builds a roster.")
                .font(.system(size: 14))
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button(action: {
                showingAddPlaylist = true
                Haptics.light()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Draft a Playbook")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.brandGradient)
                .clipShape(Capsule())
            }
            .pressable()
        }
        .frame(maxWidth: .infinity)
    }
}

// Playlist row view
struct PlaylistRowView: View {
    let playlist: Playlist
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
            HStack(spacing: 12) {
                // Use the helper to get the appropriate image view
                playlist.getImageView(size: 70)

                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)

                    Text(playlist.description)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)

                    Text("\(viewModel.getSongs(for: playlist).count) songs")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(12)
            .surfaceCard()
            .padding(.horizontal)
        }
    }
}

// Artists tab view
struct ArtistsTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var sortOption: SortOption

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Artists")
                        .font(Theme.title(20))
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    SortMenuView(sortOption: $sortOption, showRecent: false)
                }
                .padding(.horizontal)
                .padding(.top)

                // Get unique artists
                let artists = Array(Set(viewModel.allSongs.map { $0.artist })).sorted()

                ForEach(artists, id: \.self) { artist in
                    ArtistSectionView(artist: artist, sortOption: sortOption)
                }

                // Space for mini player if needed
                if viewModel.currentSong != nil {
                    Spacer()
                        .frame(height: 90)
                }
            }
        }
    }
}

// Artist section view
struct ArtistSectionView: View {
    let artist: String
    let sortOption: SortOption
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(artist)
                .font(Theme.title(17))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal)
                .padding(.top, 8)

            let artistSongs = sortSongs(viewModel.allSongs.filter { $0.artist == artist })

            ForEach(artistSongs) { song in
                SongRow(song: song)
                    .padding(.horizontal)
            }
        }
    }

    private func sortSongs(_ songs: [Song]) -> [Song] {
        songs.sorted(using: sortOption)
    }
}

// Categories tab view
struct CategoriesTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var sortOption: SortOption

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Categories")
                        .font(Theme.title(20))
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    SortMenuView(sortOption: $sortOption, showRecent: false)
                }
                .padding(.horizontal)
                .padding(.top)

                // Get unique categories
                let allCategories = viewModel.allSongs.flatMap { $0.categories }
                let categories = Array(Set(allCategories)).sorted()

                ForEach(categories, id: \.self) { category in
                    CategorySectionView(category: category, sortOption: sortOption)
                }

                // Space for mini player if needed
                if viewModel.currentSong != nil {
                    Spacer()
                        .frame(height: 90)
                }
            }
        }
    }
}

// Category section view
struct CategorySectionView: View {
    let category: String
    let sortOption: SortOption
    @EnvironmentObject var viewModel: LeBronifyViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(category)
                .font(Theme.title(17))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal)
                .padding(.top, 8)

            let categorySongs = sortSongs(viewModel.allSongs.filter { $0.categories.contains(category) })

            ForEach(categorySongs) { song in
                SongRow(song: song)
                    .padding(.horizontal)
            }
        }
    }

    private func sortSongs(_ songs: [Song]) -> [Song] {
        songs.sorted(using: sortOption)
    }
}

// Favorites tab view
struct FavoritesTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Binding var sortOption: SortOption

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("All-Stars")
                        .font(Theme.title(20))
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    let favorites = viewModel.allSongs.filter { $0.isFavorite }
                    if !favorites.isEmpty {
                        Button {
                            viewModel.playSongs(favorites, shuffled: true)
                            Haptics.medium()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "shuffle")
                                Text("Shuffle")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.accentText)
                        }
                    }

                    SortMenuView(sortOption: $sortOption, showRecent: true)
                }
                .padding(.horizontal)
                .padding(.top)

                let favorites = viewModel.allSongs.filter { $0.isFavorite }.sorted(using: sortOption)

                if favorites.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ForEach(favorites) { song in
                        SongRow(song: song)
                            .padding(.horizontal)
                    }
                }

                // Space for mini player if needed
                if viewModel.currentSong != nil {
                    Spacer()
                        .frame(height: 90)
                }
            }
        }
    }
}

// Empty favorites view
struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 48))
                .foregroundColor(Theme.liberty.opacity(0.5))
                .padding(.top, 50)

            Text("No All-Stars yet")
                .font(Theme.title(18))
                .foregroundColor(Theme.textSecondary)

            Text("Even the King has his favorites.\nCrown a song as an All-Star from the menu!")
                .font(.system(size: 14))
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

// Sort menu view
struct SortMenuView: View {
    @Binding var sortOption: SortOption
    let showRecent: Bool

    var body: some View {
        Menu {
            Button("Default") { sortOption = .default }
            Button("Alphabetical") { sortOption = .title }
            Button("Most Played") { sortOption = .plays }
            if showRecent {
                Button("Recently Played") { sortOption = .recent }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(8)
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .environmentObject(LeBronifyViewModel())
    }
}
