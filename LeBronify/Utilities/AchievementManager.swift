//
//  AchievementManager.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI
import Combine

// MARK: - Achievement Model

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    var unlockedDate: Date?
}

// MARK: - Achievement Manager

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    private let storageKey = "lebronify_achievements"

    @Published var achievements: [Achievement] = []
    @Published var newlyUnlockedAchievement: Achievement?

    private init() {
        loadAchievements()
    }

    // All possible achievements
    static let allAchievements: [Achievement] = [
        Achievement(
            id: "rookie_of_the_year",
            name: "Rookie of the Year",
            description: "Play your first song",
            icon: "star.circle.fill",
            isUnlocked: false
        ),
        Achievement(
            id: "sixth_man",
            name: "Sixth Man",
            description: "Play 6 different songs in one session",
            icon: "person.3.fill",
            isUnlocked: false
        ),
        Achievement(
            id: "triple_double",
            name: "Triple Double",
            description: "10 songs played, 10 All-Stars, 10 Playbooks",
            icon: "trophy.fill",
            isUnlocked: false
        ),
        Achievement(
            id: "mvp",
            name: "MVP",
            description: "Reach 100 total plays across all songs",
            icon: "medal.fill",
            isUnlocked: false
        ),
        Achievement(
            id: "forty_k_club",
            name: "40,000 Point Club",
            description: "Accumulate 40,000 seconds of total listening",
            icon: "flame.fill",
            isUnlocked: false
        ),
        Achievement(
            id: "ring_ceremony",
            name: "Ring Ceremony",
            description: "Listen to every song at least once",
            icon: "ring.circle.fill",
            isUnlocked: false
        ),
        Achievement(
            id: "hall_of_fame",
            name: "Hall of Fame",
            description: "Reach 500 total plays across all songs",
            icon: "building.columns.fill",
            isUnlocked: false
        )
    ]

    func checkAchievements(songs: [Song], playlists: [Playlist], sessionSongsPlayed: Set<UUID>) {
        let totalPlays = songs.reduce(0) { $0 + $1.playCount }
        let songsPlayed = songs.filter { $0.playCount > 0 }.count
        let allStars = songs.filter { $0.isFavorite }.count
        let userPlaybooks = playlists.filter { !$0.isSystem }.count
        let totalListenedSeconds = songs.reduce(0.0) { $0 + Double($1.playCount) * $1.duration }
        let allSongsPlayed = songs.allSatisfy { $0.playCount > 0 }

        let checks: [(String, Bool)] = [
            ("rookie_of_the_year", songsPlayed >= 1),
            ("sixth_man", sessionSongsPlayed.count >= 6),
            ("triple_double", songsPlayed >= 10 && allStars >= 10 && userPlaybooks >= 10),
            ("mvp", totalPlays >= 100),
            ("forty_k_club", totalListenedSeconds >= 40000),
            ("ring_ceremony", allSongsPlayed && !songs.isEmpty),
            ("hall_of_fame", totalPlays >= 500)
        ]

        for (id, met) in checks {
            if met, let idx = achievements.firstIndex(where: { $0.id == id && !$0.isUnlocked }) {
                achievements[idx].isUnlocked = true
                achievements[idx].unlockedDate = Date()
                saveAchievements()

                // Only show one at a time — queue handled by caller
                if newlyUnlockedAchievement == nil {
                    newlyUnlockedAchievement = achievements[idx]
                }
            }
        }
    }

    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Merge saved state with current definitions (in case new achievements were added)
            achievements = Self.allAchievements.map { definition in
                if let saved = saved.first(where: { $0.id == definition.id }) {
                    return saved
                }
                return definition
            }
        } else {
            achievements = Self.allAchievements
        }
    }

    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

// MARK: - Achievement Unlocked Overlay

struct AchievementUnlockedOverlay: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Text("ACHIEVEMENT UNLOCKED")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(3)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow, .orange],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .yellow.opacity(0.6), radius: 20)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 44))
                        .foregroundColor(.black)
                }
                .scaleEffect(showContent ? 1.0 : 0.3)

                Text(achievement.name)
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.yellow)

                Text(achievement.description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onDismiss()
            }
        }
    }
}

// MARK: - Achievements Tab View (for LibraryView)

struct AchievementsTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Trophy Case")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    let unlocked = viewModel.achievementManager.achievements.filter { $0.isUnlocked }.count
                    let total = viewModel.achievementManager.achievements.count
                    Text("\(unlocked)/\(total)")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal)
                .padding(.top)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.achievementManager.achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal)

                if viewModel.currentSong != nil {
                    Spacer().frame(height: 80)
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                          : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? .black : .gray)
            }

            Text(achievement.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(achievement.isUnlocked ? .white : .gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(achievement.isUnlocked ? achievement.description : "???")
                .font(.system(size: 11))
                .foregroundColor(achievement.isUnlocked ? .white.opacity(0.5) : .gray.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if achievement.isUnlocked, let date = achievement.unlockedDate {
                Text(date, style: .date)
                    .font(.system(size: 9))
                    .foregroundColor(.yellow.opacity(0.5))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(achievement.isUnlocked ? 0.06 : 0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.isUnlocked ? Color.yellow.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
