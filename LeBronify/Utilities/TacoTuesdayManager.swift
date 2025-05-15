//
//  TacoTuesdayManager.swift
//  LeBronify
//
//  Created by Robert Wiscount on 4/1/25.
//


import SwiftUI
import Combine

class TacoTuesdayManager {
    static let shared = TacoTuesdayManager()
    
    // Check if today is Tuesday
    var isTacoTuesday: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // weekday 3 = Tuesday (1 is Sunday in Calendar)
        return weekday == 3
    }
    
    // Taco Tuesday assets
    let tacoTuesdayBannerImage = "lebron_taco_tuesday"
    let tacoTuesdayAlbumArt = "taco_tuesday"
    let tacoTuesdayAudioFile = "Taco Tuesday"
    
    // Taco Ad Models
    func getTacoAds() -> [AnthonyDavisAd] {
        return [
            AnthonyDavisAd(
                title: "TACO TUESDAY SPECIAL!",
                imageName: "taco_tuesday_ad_1",
                message: "LeBron says it's TACO TUESDAYYYYY! Get your tacos now!"
            ),
            AnthonyDavisAd(
                title: "TACO TIME WITH THE KING",
                imageName: "taco_tuesday_ad_2",
                message: "Join LeBron for his famous Taco Tuesday celebration!"
            )
        ]
    }
    
    // Create the special Taco Tuesday song
    func createTacoTuesdaySong() -> Song {
        return Song(
            id: UUID(),
            title: "TACO TUESDAYYYYY",
            artist: "LeBron James",
            albumArt: tacoTuesdayAlbumArt,
            audioFileName: tacoTuesdayAudioFile,
            duration: 30.0, // Assuming 30 seconds for the jingle
            playCount: 0,
            lastPlayed: nil,
            isFavorite: false,
            categories: ["LeBron", "Meme", "Taco"]
        )
    }
}

struct TacoRain: View {
    @State private var tacos: [TacoParticle] = []
    
    struct TacoParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var size: CGFloat
        var speed: CGFloat
        var opacity: Double
    }
    
    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // This creates a transparent overlay over the entire screen
                Color.clear
                    .edgesIgnoringSafeArea(.all)
                
                // Falling tacos
                ForEach(tacos) { taco in
                    Image("taco_image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: taco.size, height: taco.size)
                        .position(x: taco.x, y: taco.y)
                        .rotationEffect(.degrees(taco.rotation))
                        .opacity(taco.opacity)
                        .shadow(color: .black.opacity(0.2), radius: 1)
                }
            }
            .onAppear {
                // Initialize with tacos distributed across the full screen width
                spawnTacos(count: 25, geometry: geometry)
            }
            .onReceive(timer) { _ in
                // Move tacos down
                updateTacos(geometry: geometry)
                
                // Occasionally spawn new tacos
                if Int.random(in: 0...100) < 5 {
                    spawnTacos(count: 1, geometry: geometry)
                }
            }
        }
    }
    
    private func spawnTacos(count: Int, geometry: GeometryProxy) {
        let screenWidth = geometry.size.width
        let topPadding: CGFloat = 50 // Adjust for notches and top bars
        
        for _ in 0..<count {
            tacos.append(
                TacoParticle(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: -topPadding - CGFloat.random(in: 0...100), // Start above screen with variation
                    rotation: Double.random(in: 0...360),
                    size: CGFloat.random(in: 35...70), // Slightly larger tacos for better visibility
                    speed: CGFloat.random(in: 2...6),
                    opacity: Double.random(in: 0.7...1.0) // Varying opacity for depth effect
                )
            )
        }
    }
    
    private func updateTacos(geometry: GeometryProxy) {
        let screenHeight = geometry.size.height
        
        for i in (0..<tacos.count).reversed() {
            // Update position
            tacos[i].y += tacos[i].speed
            // Update rotation slightly for a spinning effect
            tacos[i].rotation += Double(tacos[i].speed * 0.5)
            
            // Remove tacos that have fallen off screen
            if tacos[i].y > screenHeight + 50 {
                tacos.remove(at: i)
            }
        }
    }
}
