//
//  Theme.swift
//  LeBronify
//
//  Central design system for the Sixers-era rebrand.
//  Every color, radius, and spacing value in the app should come from here
//  so a future re-theme is a one-file change.
//

import SwiftUI
import UIKit

// MARK: - Hex Color Support

extension Color {
    /// Builds a Color from a 24-bit RGB hex value, e.g. `Color(hex: 0x006BB6)`.
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Theme

enum Theme {

    // MARK: Brand Palette
    // Philadelphia 76ers team colors. Colors themselves aren't protectable —
    // we deliberately use the palette only, never the team logo or wordmark.

    /// Primary brand blue — the app's main accent.
    static let royal = Color(hex: 0x006BB6)
    /// Secondary brand red — used for emphasis, live states, and destructive actions.
    static let liberty = Color(hex: 0xED174C)
    /// Deep navy — backgrounds, gradient anchors.
    static let navy = Color(hex: 0x002B5C)
    /// Cool silver — the "chrome" tone for secondary surfaces.
    static let silver = Color(hex: 0xC4CED4)
    /// A brighter blue for text and icons that must stay legible on dark surfaces.
    static let royalBright = Color(hex: 0x2C9BE8)

    // MARK: Semantic Tokens

    /// App-wide background. Near-black with a navy tint so the app reads as Sixers,
    /// not as generic dark mode.
    static let background = Color(hex: 0x0A0F16)
    /// Cards and rows sitting on `background`.
    static let surface = Color(hex: 0x141B26)
    /// Raised surfaces — mini player, sheets, sticky bars.
    static let elevated = Color(hex: 0x1E2836)
    /// Hairline dividers and card strokes.
    static let stroke = Color.white.opacity(0.08)

    /// The accent used for interactive affordances throughout the app.
    static let accent = royal
    /// Accent variant for text/icons where `royal` is too dim against dark backgrounds.
    static let accentText = royalBright

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)

    // MARK: Gradients

    /// Blue → red sweep. The signature brand gradient for heroes and CTAs.
    static let brandGradient = LinearGradient(
        colors: [royal, liberty],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Navy → royal. Calmer than `brandGradient`; used for large fills.
    static let courtGradient = LinearGradient(
        colors: [navy, royal],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Fades a brand tint into the app background — used behind scroll views.
    static let ambientGradient = LinearGradient(
        colors: [royal.opacity(0.28), background],
        startPoint: .top,
        endPoint: .center
    )

    /// Radial glow for celebratory moments (achievements, bell ring).
    static let celebrationGradient = RadialGradient(
        colors: [liberty, royal],
        center: .center,
        startRadius: 0,
        endRadius: 60
    )

    // MARK: Geometry

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 12
        static let large: CGFloat = 18
        static let pill: CGFloat = 999
    }

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: Typography

    /// Display face for headings — heavy and rounded, matching the app's playful tone.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func title(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular)
    }

    /// Small all-caps label styling ("ON THE COURT", "UP NEXT").
    static func eyebrow(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .heavy)
    }

    static func stat(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .black, design: .monospaced)
    }
}

// MARK: - Haptics

/// Thin wrapper so haptic calls read clearly at call sites and stay consistent.
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

// MARK: - Button Styles

/// Buttons shrink slightly while held. Small touch, but it makes the whole app
/// feel responsive rather than static.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// The app's primary call-to-action: full-width brand-gradient pill.
struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.brandGradient)
            .clipShape(Capsule())
            .shadow(color: Theme.royal.opacity(0.35), radius: 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - View Modifiers

extension View {
    /// Standard card treatment: surface fill, rounded corners, hairline stroke.
    func surfaceCard(cornerRadius: CGFloat = Theme.Radius.medium) -> some View {
        self
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }

    /// Small all-caps section eyebrow, tinted with the brand accent.
    func eyebrowStyle(color: Color = Theme.accentText) -> some View {
        self
            .font(Theme.eyebrow())
            .foregroundColor(color)
            .tracking(1.4)
    }

    /// Applies the pressable shrink effect to any tappable view.
    func pressable(scale: CGFloat = 0.96) -> some View {
        buttonStyle(PressableButtonStyle(scale: scale))
    }
}

// MARK: - Section Header

/// Reusable section heading with an optional trailing action.
/// Replaces the ad-hoc `Text(...).font(.system(size: 20, weight: .bold))` blocks
/// that were duplicated across every screen.
struct SectionHeader<Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let trailing: Trailing

    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.title(20))
                    .foregroundColor(Theme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                }
            }

            Spacer()

            trailing
        }
        .padding(.horizontal)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() })
    }
}
