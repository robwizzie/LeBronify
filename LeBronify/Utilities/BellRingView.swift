//
//  BellRingView.swift
//  LeBronify
//
//  Philly celebration moment. The Sixers ring the bell before tip-off, so
//  milestones in the app ring it too — swinging bell, expanding sound rings,
//  and a burst of red/blue confetti.
//

import SwiftUI

struct BellRingView: View {
    let onComplete: () -> Void

    @State private var bellAngle: Double = 0
    @State private var bellScale: CGFloat = 0.4
    @State private var bellOpacity: Double = 0
    @State private var rings: [SoundRing] = []
    @State private var confetti: [ConfettiPiece] = []
    @State private var timer: Timer?
    @State private var elapsed: TimeInterval = 0
    @State private var completionFired = false

    struct SoundRing: Identifiable {
        let id = UUID()
        var scale: CGFloat
        var opacity: Double
    }

    struct ConfettiPiece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var velocityX: CGFloat
        var velocityY: CGFloat
        var rotation: Double
        var rotationSpeed: Double
        var size: CGFloat
        var color: Color
        var opacity: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(max(0, 0.55 - elapsed * 0.22))
                    .ignoresSafeArea()

                // Expanding sound rings behind the bell
                ForEach(rings) { ring in
                    Circle()
                        .stroke(Theme.royalBright.opacity(ring.opacity), lineWidth: 3)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ring.scale)
                }

                // Confetti in Sixers colors
                ForEach(confetti) { piece in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 1.8)
                        .rotationEffect(.degrees(piece.rotation))
                        .opacity(piece.opacity)
                        .position(x: piece.x, y: piece.y)
                }

                // The bell itself
                VStack(spacing: 14) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 74))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.silver, Color(hex: 0x8A959C)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(bellAngle), anchor: .top)
                        .scaleEffect(bellScale)
                        .shadow(color: Theme.royal.opacity(0.6), radius: 20)

                    Text("RING THE BELL")
                        .font(Theme.display(20))
                        .foregroundColor(.white)
                        .tracking(2)
                        .shadow(color: Theme.liberty.opacity(0.8), radius: 8)
                }
                .opacity(bellOpacity)
            }
            .onAppear {
                start(in: geo.size)
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Animation

    private func start(in size: CGSize) {
        Haptics.heavy()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            bellScale = 1.0
            bellOpacity = 1.0
        }

        // Swing the bell back and forth, decaying over time
        withAnimation(.easeInOut(duration: 0.18).repeatCount(7, autoreverses: true)) {
            bellAngle = 16
        }

        spawnConfetti(in: size)
        startTimer(in: size)
    }

    private func spawnConfetti(in size: CGSize) {
        let palette: [Color] = [Theme.royal, Theme.liberty, .white, Theme.royalBright, Theme.silver]
        let originX = size.width / 2
        let originY = size.height / 2 - 40

        for _ in 0..<70 {
            confetti.append(
                ConfettiPiece(
                    x: originX + CGFloat.random(in: -50...50),
                    y: originY + CGFloat.random(in: -30...30),
                    velocityX: CGFloat.random(in: -7...7),
                    velocityY: CGFloat.random(in: (-13)...(-4)),
                    rotation: Double.random(in: 0...360),
                    rotationSpeed: Double.random(in: -14...14),
                    size: CGFloat.random(in: 4...9),
                    color: palette.randomElement() ?? Theme.royal,
                    opacity: 1.0
                )
            )
        }
    }

    private func startTimer(in size: CGSize) {
        let interval: TimeInterval = 1.0 / 60.0
        var ringTick: TimeInterval = 0

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            elapsed += interval
            ringTick += interval

            // Emit a new sound ring roughly every 0.35s for the first second
            if ringTick >= 0.35 && elapsed < 1.1 {
                ringTick = 0
                rings.append(SoundRing(scale: 0.5, opacity: 0.7))
                Haptics.light()
            }

            for i in rings.indices {
                rings[i].scale += 0.035
                rings[i].opacity = max(0, rings[i].opacity - 0.012)
            }
            rings.removeAll { $0.opacity <= 0 }

            for i in confetti.indices {
                confetti[i].x += confetti[i].velocityX
                confetti[i].y += confetti[i].velocityY
                confetti[i].velocityY += 0.32          // gravity
                confetti[i].velocityX *= 0.99          // air resistance
                confetti[i].rotation += confetti[i].rotationSpeed
                if elapsed > 1.0 {
                    confetti[i].opacity = max(0, confetti[i].opacity - 0.016)
                }
            }
            confetti.removeAll { $0.opacity <= 0 || $0.y > size.height + 60 }

            // Fade the bell out near the end
            if elapsed > 1.6 {
                withAnimation(.easeOut(duration: 0.4)) {
                    bellOpacity = 0
                }
            }

            if elapsed >= 2.2 && !completionFired {
                completionFired = true
                timer?.invalidate()
                timer = nil
                DispatchQueue.main.async {
                    onComplete()
                }
            }
        }
    }
}
