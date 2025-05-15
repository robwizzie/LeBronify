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
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // LeBron face with a funny bobblehead effect
                Image("lebron_default")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(headRotation))
                    .scaleEffect(headScale)
                    .shadow(color: .yellow.opacity(0.3), radius: 6, x: 0, y: 3) // More subtle glow
                
                // App title
                Text("LEBRONIFY")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.4), radius: 1, x: 0, y: 0) // Subtle text glow
                
                // Subtitle
                Text("The King's Parody Collection")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                // Taco Tuesday subtitle - only on Tuesdays
                if TacoTuesdayManager.shared.isTacoTuesday {
                    Text("IT'S TACO TUESDAY!")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.2))
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
            // Create a bobblehead/nodding effect
            withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                self.headRotation = 10
                self.headScale = 1.05
                self.opacity = 1.0
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
