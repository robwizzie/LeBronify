//
//  ProcessMeterView.swift
//  LeBronify
//
//  "Trust The Process" — a running progress meter on the home screen that
//  turns total play count into a franchise-rebuild arc, from tanking to a title.
//

import SwiftUI

// MARK: - Process Tier

struct ProcessTier {
    let name: String
    let blurb: String
    let threshold: Int
    let icon: String

    /// The rebuild, in order. `threshold` is the total play count needed to reach the tier.
    static let all: [ProcessTier] = [
        ProcessTier(name: "Tanking",
                    blurb: "Every dynasty starts somewhere.",
                    threshold: 0,
                    icon: "arrow.down.circle.fill"),
        ProcessTier(name: "The Process Begins",
                    blurb: "Lottery balls are bouncing your way.",
                    threshold: 10,
                    icon: "hourglass"),
        ProcessTier(name: "Rebuilding",
                    blurb: "The young core is developing nicely.",
                    threshold: 50,
                    icon: "hammer.fill"),
        ProcessTier(name: "Playoff Push",
                    blurb: "You're in the play-in conversation.",
                    threshold: 150,
                    icon: "chart.line.uptrend.xyaxis"),
        ProcessTier(name: "Contender",
                    blurb: "Homecourt advantage secured.",
                    threshold: 350,
                    icon: "flame.fill"),
        ProcessTier(name: "Championship Or Bust",
                    blurb: "Broad Street is ready for a parade.",
                    threshold: 700,
                    icon: "trophy.fill")
    ]

    /// Highest tier reached at the given play count.
    static func current(for plays: Int) -> ProcessTier {
        all.last { plays >= $0.threshold } ?? all[0]
    }

    /// The tier after the current one, or nil once the arc is complete.
    static func next(for plays: Int) -> ProcessTier? {
        all.first { plays < $0.threshold }
    }
}

// MARK: - Meter Card

struct ProcessMeterView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @State private var animatedProgress: Double = 0

    var body: some View {
        let totalPlays = viewModel.allSongs.reduce(0) { $0 + $1.playCount }
        let tier = ProcessTier.current(for: totalPlays)
        let nextTier = ProcessTier.next(for: totalPlays)
        let progress = progressToNext(plays: totalPlays, tier: tier, next: nextTier)

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.brandGradient)
                        .frame(width: 44, height: 44)

                    Image(systemName: tier.icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("TRUST THE PROCESS")
                        .eyebrowStyle()

                    Text(tier.name)
                        .font(Theme.title(19))
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(totalPlays)")
                        .font(Theme.stat(20))
                        .foregroundColor(Theme.accentText)
                    Text("plays")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textTertiary)
                }
            }

            Text(tier.blurb)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)

            // Progress track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    Capsule()
                        .fill(Theme.brandGradient)
                        .frame(width: max(0, geo.size.width * animatedProgress), height: 8)
                        .shadow(color: Theme.royal.opacity(0.5), radius: 6)
                }
            }
            .frame(height: 8)

            if let nextTier {
                HStack {
                    Text("Next: \(nextTier.name)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)

                    Spacer()

                    Text("\(max(0, nextTier.threshold - totalPlays)) plays to go")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textTertiary)
                }
            } else {
                Text("Maxed out. The Process is complete. 🏆")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.liberty)
            }
        }
        .padding(16)
        .surfaceCard()
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: totalPlays) {
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = progressToNext(
                    plays: totalPlays,
                    tier: ProcessTier.current(for: totalPlays),
                    next: ProcessTier.next(for: totalPlays)
                )
            }
        }
    }

    /// Fraction of the way from the current tier's threshold to the next one.
    private func progressToNext(plays: Int, tier: ProcessTier, next: ProcessTier?) -> Double {
        guard let next else { return 1.0 }
        let span = next.threshold - tier.threshold
        guard span > 0 else { return 1.0 }
        let travelled = plays - tier.threshold
        return min(1.0, max(0.0, Double(travelled) / Double(span)))
    }
}

struct ProcessMeterView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessMeterView()
            .environmentObject(LeBronifyViewModel())
            .background(Theme.background)
    }
}
