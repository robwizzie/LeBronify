//
//  SplashScreen.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/29/25.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var headRotation: Double = -10
    @State private var headScale: CGFloat = 0.95
    @State private var opacity = 0.7
    @State private var showTacoRain = false
    @State private var loadingPhrase = ""
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.0

    private let loadingPhrases = [
        "Trusting the process...",
        "Checking LeBron's playlist...",
        "Polishing the crown...",
        "Loading 4 rings worth of bangers...",
        "Warming up at the Wells Fargo Center...",
        "Ringing the bell...",
        "Reviewing game film... I mean, songs...",
        "The King has arrived in Philly.",
        "LeLoading...",
        "Preparing the chalk toss...",
        "Booing something, anything...",
        "Counting triple-doubles...",
        "Activating playoff mode...",
        "Fixing the bell, it's cracked...",
    ]

    var body: some View {
        ZStack {
            // Navy-to-black wash instead of flat black
            LinearGradient(
                colors: [Theme.navy, Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 26) {
                // LeBron face with a funny bobblehead effect, ringed in brand blue
                ZStack {
                    Circle()
                        .stroke(Theme.brandGradient, lineWidth: 4)
                        .frame(width: 236, height: 236)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Image("lebron_default")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(headRotation))
                        .scaleEffect(headScale)
                        .shadow(color: Theme.royal.opacity(0.5), radius: 18, x: 0, y: 6)
                }

                VStack(spacing: 10) {
                    // App title
                    HStack(spacing: 10) {
                        Text("LEBRONIFY")
                            .font(Theme.display(42))
                            .foregroundColor(.white)

                        Text("PHL")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.liberty)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }

                    // Subtitle
                    Text("The King's Parody Collection")
                        .font(.headline)
                        .foregroundColor(Theme.textSecondary)

                    Text("TRUST THE PROCESS")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Theme.accentText)
                        .tracking(3)
                }

                // Funny loading phrase
                Text(loadingPhrase)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                    .transition(.opacity)
                    .id(loadingPhrase) // Force transition on change

                // Taco Tuesday subtitle - only on Tuesdays
                if TacoTuesdayManager.shared.isTacoTuesday {
                    Text("IT'S TACO TUESDAY!")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.15))
                        )
                }
            }
            .opacity(opacity)

            // Taco rain overlay (only on Tuesdays)
            if showTacoRain && TacoTuesdayManager.shared.isTacoTuesday {
                TacoRain()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .onAppear {
            // Show first loading phrase
            withAnimation { loadingPhrase = loadingPhrases.randomElement() ?? "" }

            // Cycle through funny phrases
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { loadingPhrase = loadingPhrases.randomElement() ?? "" }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation { loadingPhrase = loadingPhrases.randomElement() ?? "" }
            }

            // Create a bobblehead/nodding effect
            withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                self.headRotation = 10
                self.headScale = 1.05
                self.opacity = 1.0
            }

            // Pulsing brand ring around the portrait
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                self.ringScale = 1.05
                self.ringOpacity = 0.85
            }

            // Show taco rain on Tuesdays
            if TacoTuesdayManager.shared.isTacoTuesday {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showTacoRain = true
                    }
                }
            }

            // After 2.5 seconds, transition to the main app
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.isActive = true
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            MainTabView()
                .environmentObject(LeBronifyApp.viewModel)
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
