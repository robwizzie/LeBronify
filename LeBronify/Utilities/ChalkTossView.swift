//
//  ChalkTossView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI

struct ChalkTossView: View {
    let onComplete: () -> Void

    @State private var particles: [ChalkParticle] = []
    @State private var timer: Timer?
    @State private var actionFired = false
    @State private var elapsed: TimeInterval = 0

    struct ChalkParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var velocityX: CGFloat
        var velocityY: CGFloat
        var rotation: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(max(0, 0.6 - elapsed * 0.3))
                    .ignoresSafeArea()

                // Chalk particles
                ForEach(particles) { p in
                    Circle()
                        .fill(
                            p.size > 6
                                ? Color.white
                                : Color.yellow.opacity(0.8)
                        )
                        .frame(width: p.size, height: p.size)
                        .opacity(p.opacity)
                        .blur(radius: p.size > 8 ? 2 : 0.5)
                        .position(x: p.x, y: p.y)
                }

                // Hands silhouette at bottom center
                if elapsed < 0.8 {
                    VStack(spacing: 0) {
                        Spacer()
                        Image(systemName: "hands.clap.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(max(0, 0.7 - elapsed)))
                            .scaleEffect(1.0 + CGFloat(elapsed) * 0.3)
                    }
                    .padding(.bottom, geo.size.height * 0.15)
                }
            }
            .onAppear {
                spawnParticles(in: geo.size)
                startTimer(in: geo.size)
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        .allowsHitTesting(false)
    }

    private func spawnParticles(in size: CGSize) {
        let centerX = size.width / 2
        let bottomY = size.height * 0.82

        for _ in 0..<50 {
            let particle = ChalkParticle(
                x: centerX + CGFloat.random(in: -60...60),
                y: bottomY + CGFloat.random(in: -20...20),
                size: CGFloat.random(in: 3...14),
                opacity: Double.random(in: 0.6...1.0),
                velocityX: CGFloat.random(in: -3...3),
                velocityY: CGFloat.random(in: (-8)...(-3)),
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
    }

    private func startTimer(in size: CGSize) {
        let interval: TimeInterval = 1.0 / 60.0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            elapsed += interval

            // Update particles
            for i in particles.indices {
                particles[i].x += particles[i].velocityX
                particles[i].y += particles[i].velocityY
                particles[i].velocityY += 0.15  // gravity
                particles[i].velocityX *= 0.99  // air resistance
                particles[i].opacity = max(0, particles[i].opacity - 0.008)
            }

            // Remove dead particles
            particles.removeAll { $0.opacity <= 0 }

            // Fire the action partway through so music starts while particles fade
            if elapsed >= 0.8 && !actionFired {
                actionFired = true
                DispatchQueue.main.async {
                    onComplete()
                }
            }
        }
    }
}
