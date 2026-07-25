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
        ),
        Achievement(
            id: "bell_ringer",
            name: "Bell Ringer",
            description: "Reach 10 total plays and ring the bell",
            icon: "bell.fill",
            isUnlocked: false
        ),
        Achievement(
            id: "brotherly_love",
            name: "Brotherly Love",
            description: "Crown 20 songs as All-Stars",
            icon: "heart.fill",
            isUnlocked: false
        ),
        Achievement(
            id: "the_answer",
            name: "The Answer",
            description: "Play 3 different songs 3 times each",
            icon: "3.circle.fill",
            isUnlocked: false
        ),
        Achievement(
            id: "broad_street_run",
            name: "Broad Street Run",
            description: "Play 10 different songs in one session",
            icon: "figure.run",
            isUnlocked: false
        ),
        Achievement(
            id: "trust_the_process",
            name: "Trust The Process",
            description: "Reach Contender status — 350 total plays",
            icon: "crown.fill",
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

        let songsPlayedThrice = songs.filter { $0.playCount >= 3 }.count

        let checks: [(String, Bool)] = [
            ("rookie_of_the_year", songsPlayed >= 1),
            ("sixth_man", sessionSongsPlayed.count >= 6),
            ("triple_double", songsPlayed >= 10 && allStars >= 10 && userPlaybooks >= 10),
            ("mvp", totalPlays >= 100),
            ("forty_k_club", totalListenedSeconds >= 40000),
            ("ring_ceremony", allSongsPlayed && !songs.isEmpty),
            ("hall_of_fame", totalPlays >= 500),
            ("bell_ringer", totalPlays >= 10),
            ("brotherly_love", allStars >= 20),
            ("the_answer", songsPlayedThrice >= 3),
            ("broad_street_run", sessionSongsPlayed.count >= 10),
            ("trust_the_process", totalPlays >= 350)
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
                        .fill(Theme.celebrationGradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: Theme.royal.opacity(0.7), radius: 22)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .scaleEffect(showContent ? 1.0 : 0.3)

                Text(achievement.name)
                    .font(Theme.display(26))
                    .foregroundStyle(Theme.brandGradient)

                Text(achievement.description)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textSecondary)
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
                        .font(Theme.title(20))
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    let unlocked = viewModel.achievementManager.achievements.filter { $0.isUnlocked }.count
                    let total = viewModel.achievementManager.achievements.count
                    Text("\(unlocked)/\(total)")
                        .font(Theme.stat(15))
                        .foregroundColor(Theme.accentText)
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
                          ? AnyShapeStyle(Theme.brandGradient)
                          : AnyShapeStyle(Color.white.opacity(0.08)))
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? .white : Theme.textTertiary)
            }

            Text(achievement.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(achievement.isUnlocked ? Theme.textPrimary : Theme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(achievement.isUnlocked ? achievement.description : "???")
                .font(.system(size: 11))
                .foregroundColor(achievement.isUnlocked ? Theme.textSecondary : Theme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if achievement.isUnlocked, let date = achievement.unlockedDate {
                Text(date, style: .date)
                    .font(.system(size: 9))
                    .foregroundColor(Theme.accentText.opacity(0.7))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .stroke(achievement.isUnlocked ? Theme.royal.opacity(0.5) : Theme.stroke, lineWidth: 1)
        )
    }
}
