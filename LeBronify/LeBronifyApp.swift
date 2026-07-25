import SwiftUI
import UIKit

@main
struct LeBronifyApp: App {
    // Make this a static shared instance that can be accessed from anywhere
    static let viewModel = LeBronifyViewModel()
    
    // Use the shared viewModel instance
    @StateObject private var viewModel = LeBronifyApp.viewModel
    
    // Add the app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Register for background notifications on init
        setupAppForWidgetInteraction()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark) // App looks best in dark mode
                .onAppear {
                    // Play the taco song when app starts on Tuesday (after splash screen)
                    if TacoTuesdayManager.shared.isTacoTuesday {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                            let tacoSong = TacoTuesdayManager.shared.createTacoTuesdaySong()
                            viewModel.playSong(tacoSong)
                        }
                    }
                }
        }
    }
    
    // Setup app to handle widget interactions
    private func setupAppForWidgetInteraction() {
        // Listen for local notifications from widgets
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WidgetPlayPauseTapped"),
            object: nil, 
            queue: .main
        ) { _ in
            viewModel.togglePlayPause()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WidgetPreviousTapped"),
            object: nil, 
            queue: .main
        ) { _ in
            viewModel.previousSong()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WidgetNextTapped"),
            object: nil, 
            queue: .main
        ) { _ in
            viewModel.nextSong()
        }
    }
}

// MainTabView - Spotify-inspired dark tab interface
struct MainTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var selectedTab = 0
    @State private var showTacoRain = false
    @State private var tacoObserver: NSObjectProtocol? = nil

    init() {
        // Must run before the tab bar is created, so it can't live in .onAppear.
        Self.configureTabBarAppearance()
    }

    /// Opaque navy tab bar so the mini player doesn't blur into a translucent
    /// system background.
    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        appearance.shadowColor = UIColor(Theme.stroke)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tabs are declared in display order, but keep their original tags —
            // `selectedTab == 1` means Now Playing everywhere else in the app.
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "crown.fill")
                    }
                    .tag(0)

                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(3)

                PlayerView()
                    .tabItem {
                        Label("Now Playing", systemImage: "music.note")
                    }
                    .tag(1)

                LibraryView()
                    .tabItem {
                        Label("The Vault", systemImage: "rectangle.stack.fill")
                    }
                    .tag(2)
            }
            .accentColor(Theme.accentText)

            // Mini player overlay - appears above tab bar on non-player tabs
            if viewModel.currentSong != nil && selectedTab != 1 {
                VStack(spacing: 0) {
                    Spacer()
                    MiniPlayerView(selectedTab: $selectedTab)
                }
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom))
            }
        }
        .overlay(adOverlay)
        .overlay(tacoRainOverlay)
        .overlay(technicalFoulOverlay)
        .overlay(decisionOverlay)
        .overlay(chalkTossOverlay)
        .overlay(bellRingOverlay)
        .overlay(achievementOverlay)
        .preferredColorScheme(.dark)
        .onAppear { setupTacoNotifications() }
        .onDisappear {
            if let observer = tacoObserver {
                NotificationCenter.default.removeObserver(observer)
                tacoObserver = nil
            }
        }
    }

    @ViewBuilder
    private var adOverlay: some View {
        if viewModel.showingAd {
            ADOverlayView(selectedTab: $selectedTab)
        }
    }

    @ViewBuilder
    private var tacoRainOverlay: some View {
        if showTacoRain && TacoTuesdayManager.shared.isTacoTuesday {
            TacoRain()
                .allowsHitTesting(false)
                .transition(.opacity)
                .zIndex(1000)
        }
    }

    @ViewBuilder
    private var technicalFoulOverlay: some View {
        if viewModel.showingTechnicalFoul {
            TechnicalFoulOverlay(isShowing: $viewModel.showingTechnicalFoul)
        }
    }

    @ViewBuilder
    private var decisionOverlay: some View {
        if viewModel.showingDecision, let song = viewModel.decisionSong {
            TheDecisionOverlay(
                song: song,
                destination: viewModel.decisionDestination
            ) {
                viewModel.executeDecision()
            }
        }
    }

    @ViewBuilder
    private var chalkTossOverlay: some View {
        if viewModel.showingChalkToss {
            ChalkTossView {
                viewModel.chalkTossComplete()
            }
            .zIndex(999)
        }
    }

    @ViewBuilder
    private var bellRingOverlay: some View {
        if viewModel.showingBellRing {
            BellRingView {
                viewModel.bellRingComplete()
            }
            .zIndex(1001)
        }
    }

    @ViewBuilder
    private var achievementOverlay: some View {
        if viewModel.showingAchievement,
           let achievement = viewModel.achievementManager.newlyUnlockedAchievement {
            AchievementUnlockedOverlay(achievement: achievement) {
                viewModel.showingAchievement = false
                viewModel.achievementManager.newlyUnlockedAchievement = nil
            }
        }
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
    }
}
