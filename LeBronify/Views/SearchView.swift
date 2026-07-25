//
//  SearchView.swift
//  LeBronify
//
//  Full-roster search. With ~100 tracks the app badly needed a way to jump
//  straight to a song instead of scrolling the Full Roster list.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var query: String = ""
    @State private var recentSearches: [String] = []
    @State private var activeCategory: String? = nil
    @FocusState private var searchFocused: Bool

    private let recentsKey = "lebronify_recent_searches"
    private let maxRecents = 8

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchField

                    if query.isEmpty && activeCategory == nil {
                        browseContent
                    } else {
                        resultsContent
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: loadRecents)
    }

    // MARK: - Search Field

    private var searchField: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)

                TextField("Search the roster", text: $query)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textPrimary)
                    .tint(Theme.accentText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onSubmit { commitSearch() }

                if !query.isEmpty {
                    Button {
                        query = ""
                        Haptics.light()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(searchFocused ? Theme.royal : Theme.stroke, lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.2), value: searchFocused)

            // Active category filter chip
            if let category = activeCategory {
                HStack {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { activeCategory = nil }
                        Haptics.light()
                    } label: {
                        HStack(spacing: 6) {
                            Text(category)
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.royal)
                        .clipShape(Capsule())
                    }

                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Browse (empty query)

    private var browseContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Recent Searches")
                                .font(Theme.title(18))
                                .foregroundColor(Theme.textPrimary)

                            Spacer()

                            Button("Clear") {
                                clearRecents()
                                Haptics.light()
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.accentText)
                        }

                        ForEach(recentSearches, id: \.self) { term in
                            Button {
                                query = term
                                Haptics.light()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 15))
                                        .foregroundColor(Theme.textTertiary)
                                        .frame(width: 22)

                                    Text(term)
                                        .font(.system(size: 15))
                                        .foregroundColor(Theme.textSecondary)

                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Browse the Locker Room")
                        .font(Theme.title(18))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(Array(allCategories.enumerated()), id: \.element) { index, category in
                            categoryTile(category, index: index)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer().frame(height: viewModel.currentSong != nil ? 120 : 40)
            }
            .padding(.top, 4)
        }
    }

    private func categoryTile(_ category: String, index: Int) -> some View {
        // Alternate the two brand colors so the grid reads as a Sixers palette
        // rather than a wall of identical blue tiles.
        let tints: [Color] = [Theme.royal, Theme.liberty, Theme.navy, Theme.royalBright]
        let tint = tints[index % tints.count]
        let count = viewModel.allSongs.filter { $0.categories.contains(category) }.count

        return Button {
            withAnimation(.easeOut(duration: 0.2)) { activeCategory = category }
            Haptics.medium()
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("\(count) \(count == 1 ? "track" : "tracks")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(14)
            }
            .frame(height: 88)
        }
        .pressable()
    }

    // MARK: - Results

    private var resultsContent: some View {
        Group {
            let results = filteredSongs

            if results.isEmpty {
                emptyResults
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(results.count) \(results.count == 1 ? "result" : "results")")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textTertiary)

                            Spacer()

                            Button {
                                viewModel.playSongs(results, shuffled: true)
                                Haptics.medium()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "shuffle")
                                    Text("Shuffle these")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.accentText)
                            }
                        }
                        .padding(.horizontal)

                        ForEach(results) { song in
                            SongRow(song: song)
                                .padding(.horizontal)
                        }

                        Spacer().frame(height: viewModel.currentSong != nil ? 120 : 40)
                    }
                }
            }
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "airplayaudio.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(Theme.royal.opacity(0.5))

            Text("Air ball.")
                .font(Theme.display(22))
                .foregroundColor(Theme.textPrimary)

            Text("Nothing on the roster matches \"\(query)\".\nTry a different name.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Data

    private var allCategories: [String] {
        Array(Set(viewModel.allSongs.flatMap { $0.categories })).sorted()
    }

    private var filteredSongs: [Song] {
        var songs = viewModel.allSongs

        if let category = activeCategory {
            songs = songs.filter { $0.categories.contains(category) }
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return songs.sorted { $0.playCount > $1.playCount }
        }

        let needle = trimmed.lowercased()
        let matches = songs.filter { song in
            song.title.lowercased().contains(needle)
                || song.artist.lowercased().contains(needle)
                || song.categories.contains { $0.lowercased().contains(needle) }
        }

        // Rank title matches above artist/category matches, and prefix matches
        // above mid-string matches, so the obvious hit lands first.
        return matches.sorted { a, b in
            let aScore = matchScore(a, needle: needle)
            let bScore = matchScore(b, needle: needle)
            if aScore != bScore { return aScore > bScore }
            return a.playCount > b.playCount
        }
    }

    private func matchScore(_ song: Song, needle: String) -> Int {
        let title = song.title.lowercased()
        if title.hasPrefix(needle) { return 4 }
        if title.contains(needle) { return 3 }
        if song.artist.lowercased().hasPrefix(needle) { return 2 }
        if song.artist.lowercased().contains(needle) { return 1 }
        return 0
    }

    // MARK: - Recent Searches

    private func commitSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }

        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > maxRecents {
            recentSearches = Array(recentSearches.prefix(maxRecents))
        }
        UserDefaults.standard.set(recentSearches, forKey: recentsKey)
    }

    private func loadRecents() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentsKey) ?? []
    }

    private func clearRecents() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentsKey)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(LeBronifyViewModel())
    }
}
