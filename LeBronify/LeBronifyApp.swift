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

    private let tabBarBg = Color(red: 0.07, green: 0.07, blue: 0.07)

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "crown.fill")
                    }
                    .tag(0)

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
            .accentColor(.yellow)

            // Mini player overlay - appears above tab bar on non-player tabs
            if viewModel.currentSong != nil && selectedTab != 1 {
                VStack(spacing: 0) {
                    Spacer()
                    MiniPlayerView(selectedTab: $selectedTab)
                        .padding(.bottom, 49) // standard tab bar height
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            }
        }
        .overlay(
            Group {
                if viewModel.showingAd {
                    ADOverlayView()
                }
            }
        )
        .overlay(
            Group {
                if showTacoRain && TacoTuesdayManager.shared.isTacoTuesday {
                    TacoRain()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .zIndex(1000)
                }
            }
        )
        .preferredColorScheme(.dark)
        .onAppear { setupTacoNotifications() }
        .onDisappear {
            if let observer = tacoObserver {
                NotificationCenter.default.removeObserver(observer)
                tacoObserver = nil
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
