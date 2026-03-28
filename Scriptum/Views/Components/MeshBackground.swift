import SwiftUI
import simd
import Combine

// MARK: - Mesh Gradient Background
// Matches the animated radial gradient canvas in the HTML design

struct MeshBackgroundView: View {
    @State private var phase: Double = 0
    @Environment(\.colorScheme) private var scheme

    private let timer = Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base background
                Color(hex: "09100F")
                    .ignoresSafeArea()

                if #available(iOS 18.0, *) {
                    // Use native MeshGradient on iOS 18+
                    AnimatedMeshGradient(phase: phase)
                        .opacity(0.55)
                        .ignoresSafeArea()
                        .blendMode(.screen)
                } else {
                    // Fallback: layered radial gradients
                    FallbackMeshGradient(phase: phase, size: geo.size)
                        .opacity(0.50)
                        .ignoresSafeArea()
                        .blendMode(.screen)
                }
            }
        }
        .onReceive(timer) { _ in
            phase += 0.004
        }
        .ignoresSafeArea()
    }
}

// MARK: - iOS 18+ Mesh Gradient

@available(iOS 18.0, *)
struct AnimatedMeshGradient: View {
    let phase: Double

    private var p0: SIMD2<Float> { orb(0.10, 0.15, 0.4, 0.3, phase) }
    private var p1: SIMD2<Float> { orb(0.90, 0.10, 0.35, 0.25, phase + 1.2) }
    private var p2: SIMD2<Float> { orb(0.75, 0.85, 0.30, 0.20, phase + 2.4) }
    private var p3: SIMD2<Float> { orb(0.20, 0.80, 0.25, 0.28, phase + 3.6) }
    private var p4: SIMD2<Float> { [0.50, 0.45] }

    private func orb(_ bx: Float, _ by: Float, _ ax: Float, _ ay: Float, _ t: Double) -> SIMD2<Float> {
        let s = Float(sin(t * 0.4))
        let c = Float(cos(t * 0.3))
        return [bx + s * ax * 0.15, by + c * ay * 0.12]
    }

    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                p0, [Float(0.5), p0.y], p1,
                [p0.x, Float(0.5)], p4, [p1.x, Float(0.5)],
                p3, [Float(0.5), p2.y], p2
            ],
            colors: [
                Color(hue: 38/360, saturation: 0.9, brightness: 0.55).opacity(0.35),
                Color(hue: 174/360, saturation: 0.8, brightness: 0.55).opacity(0.20),
                Color(hue: 174/360, saturation: 0.8, brightness: 0.55).opacity(0.35),
                Color(hue: 38/360, saturation: 0.85, brightness: 0.55).opacity(0.20),
                Color(hue: 60/360, saturation: 0.85, brightness: 0.60).opacity(0.18),
                Color(hue: 200/360, saturation: 0.7, brightness: 0.55).opacity(0.20),
                Color(hue: 200/360, saturation: 0.7, brightness: 0.55).opacity(0.35),
                Color(hue: 350/360, saturation: 0.8, brightness: 0.60).opacity(0.20),
                Color(hue: 350/360, saturation: 0.8, brightness: 0.60).opacity(0.35),
            ]
        )
    }
}

// MARK: - Fallback Canvas Gradient

struct FallbackMeshGradient: View {
    let phase: Double
    let size: CGSize

    struct Orb {
        var relX, relY: CGFloat
        var radius: CGFloat
        var hue: CGFloat
        var phaseOffset: Double
    }

    private let orbs: [Orb] = [
        Orb(relX: 0.10, relY: 0.15, radius: 380, hue: 38/360,  phaseOffset: 0),
        Orb(relX: 0.90, relY: 0.10, radius: 420, hue: 174/360, phaseOffset: 1.2),
        Orb(relX: 0.75, relY: 0.85, radius: 360, hue: 350/360, phaseOffset: 2.4),
        Orb(relX: 0.20, relY: 0.80, radius: 340, hue: 200/360, phaseOffset: 3.6),
        Orb(relX: 0.50, relY: 0.45, radius: 300, hue: 60/360,  phaseOffset: 1.8),
    ]

    var body: some View {
        Canvas { ctx, canvasSize in
            for orb in orbs {
                let px = orb.relX * canvasSize.width  + sin(phase * 0.4 + orb.phaseOffset) * 60
                let py = orb.relY * canvasSize.height + cos(phase * 0.3 + orb.phaseOffset) * 50
                let gradient = RadialGradient(
                    colors: [
                        Color(hue: orb.hue, saturation: 0.85, brightness: 0.6).opacity(0.35),
                        .clear
                    ],
                    center: .init(x: px / canvasSize.width, y: py / canvasSize.height),
                    startRadius: 0,
                    endRadius: orb.radius
                )
                ctx.fill(
                    Path(CGRect(origin: .zero, size: canvasSize)),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hue: orb.hue, saturation: 0.85, brightness: 0.6).opacity(0.35),
                            .clear
                        ]),
                        startPoint: CGPoint(x: px, y: py),
                        endPoint: CGPoint(x: px + orb.radius, y: py + orb.radius)
                    )
                )
            }
        }
    }
}
