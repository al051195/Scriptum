import SwiftUI

// MARK: - Color from Hex

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Liquid Glass Helpers

extension View {
    /// Apply Apple Liquid Glass with custom tint - uses .glassEffect() on iOS 26+
    @ViewBuilder
    func liquidGlass(
        cornerRadius: CGFloat = 24,
        tint: Color = .clear,
        opacity: Double = 1.0
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .tint(tint.opacity(opacity))
        } else {
            self.background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(opacity * 0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
        }
    }

    /// Card-style glass background used for note cards
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 20, tint: Color = .clear) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .tint(tint.opacity(0.08))
        } else {
            self.background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }

    /// Floating toolbar glass - heavier blur
    @ViewBuilder
    func glassToolbar(cornerRadius: CGFloat = 50) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: Capsule())
        } else {
            self.background(
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Animation Curves matching HTML design

extension Animation {
    static var spring: Animation { .spring(response: 0.4, dampingFraction: 0.7) }
    static var out: Animation { .timingCurve(0.16, 1, 0.3, 1, duration: 0.5) }
    static var easeInOut: Animation { .timingCurve(0.65, 0, 0.35, 1, duration: 0.4) }
    static var bounce: Animation { .spring(response: 0.5, dampingFraction: 0.65) }
}

// MARK: - Shimmer modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white.opacity(0.35), location: 0.5),
                    .init(color: .clear, location: 1),
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .rotationEffect(.degrees(20))
            .offset(x: phase * 400)
            .clipped()
        )
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Reveal / rise-in animation

struct RevealModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .onAppear {
                withAnimation(.out.delay(delay)) { appeared = true }
            }
    }
}

extension View {
    func revealIn(delay: Double = 0) -> some View { modifier(RevealModifier(delay: delay)) }
}

// MARK: - Gradient Text

extension View {
    func gradientForeground(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        )
        .mask(self)
    }
}

// MARK: - Blink animation

struct BlinkModifier: ViewModifier {
    @State private var visible = true
    func body(content: Content) -> some View {
        content.opacity(visible ? 1 : 0.25)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever()) { visible = false }
            }
    }
}

extension View {
    func blink() -> some View { modifier(BlinkModifier()) }
}

// MARK: - Haptics

struct Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

