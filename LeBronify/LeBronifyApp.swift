import SwiftUI

@main
struct LeBronifyApp: App {
    // Make this a static shared instance that can be accessed from anywhere
    static let viewModel = LeBronifyViewModel()
    
    // Use the shared viewModel instance
    @StateObject private var viewModel = LeBronifyApp.viewModel
    
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
}

// MainTabView includes taco rain overlay directly when taco song plays
struct MainTabView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var selectedTab = 0
    @State private var showTacoRain = false
    @State private var tacoObserver: NSObjectProtocol? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                PlayerView()
                    .tabItem {
                        Label("Now Playing", systemImage: "music.note")
                    }
                    .tag(1)
                
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "rectangle.stack.fill")
                    }
                    .tag(2)
            }
            .accentColor(.yellow)
            
            // Mini player overlay with position adjustments
            if viewModel.currentSong != nil && selectedTab != 1 {
                VStack {
                    Spacer() // Push to bottom
                    MiniPlayerView(selectedTab: $selectedTab)
                        .padding(.bottom, 80) // Add padding for tab bar
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            }
        }
        .overlay(
            Group {
                if viewModel.showingAd {
                    ZStack {
                        Color.black.opacity(0.8)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            Text(viewModel.currentAd?.title ?? "AD BREAK")
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Image(viewModel.currentAd?.imageName ?? "anthony_davis_default")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 300)
                                .cornerRadius(12)
                            
                            Text(viewModel.currentAd?.message ?? "")
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button(action: {
                                viewModel.dismissAd()
                            }) {
                                Text("Skip AD (Trade to Dallas)")
                                    .font(.headline)
                                    .padding()
                                    .background(Color.yellow)
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .zIndex(100) // Ensure AD appears above everything
                    }
                }
            }
        )
        .onAppear {
            // Set up notification observer for taco song state changes
            setupTacoNotifications()
        }
        .onDisappear {
            // Clean up notification observer
            if let observer = tacoObserver {
                NotificationCenter.default.removeObserver(observer)
                tacoObserver = nil
            }
        }
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
    }
    
    // Set up notification observers for taco song state
    private func setupTacoNotifications() {
        // Store the observer so we can remove it later
        tacoObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TacoSongStateChanged"),
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let isPlaying = userInfo["isPlaying"] as? Bool else {
                return
            }
            
            // Only show tacos when taco song is actively playing
            if self.viewModel.isTacoSongPlaying && isPlaying {
                withAnimation {
                    self.showTacoRain = true
                }
            } else {
                withAnimation {
                    self.showTacoRain = false
                }
            }
        }
    }
}
