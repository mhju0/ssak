import SpriteKit
import StrokeEngine

/// Render-time ink behavior — the same recipe inks differently in rain or
/// at night without touching the stroke data.
struct RenderStyle {
    /// 0 dry … 1 soaked: spreads dabs, lightens them, adds a drooping halo.
    var wetness: CGFloat = 0
    var ink = UIColor(red: 0.10, green: 0.095, blue: 0.09, alpha: 1)
}

enum StrokeTextures {
    /// Brush dab: firm ink core with a feathered rim.
    static let soft = radialDab { distance in
        distance < 0.42 ? 1 : pow(max(0, 1 - (distance - 0.42) / 0.58), 1.6)
    }

    /// Pooled dab: ink gathered toward the rim as a wash dries.
    static let pooled = radialDab { distance in
        let body = pow(max(0, 1 - distance), 1.4) * 0.55
        let rim = max(0, 1 - abs(distance - 0.72) / 0.28) * 0.75
        return min(1, body + rim)
    }

    private static func radialDab(alpha: (CGFloat) -> CGFloat) -> SKTexture {
        let size = 64
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let cg = context.cgContext
            let center = CGFloat(size) / 2
            for y in 0 ..< size {
                for x in 0 ..< size {
                    let dx = (CGFloat(x) + 0.5 - center) / center
                    let dy = (CGFloat(y) + 0.5 - center) / center
                    let a = alpha((dx * dx + dy * dy).squareRoot())
                    guard a > 0.003 else { continue }
                    cg.setFillColor(UIColor(white: 0, alpha: a).cgColor)
                    cg.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        return SKTexture(image: image)
    }
}

/// Renders a StrokeRecipe as stamped dab sprites and plays the
/// paint-itself-in reveal. Recipes are authored in a unit square, y-up.
final class RecipeNode: SKNode {
    private struct Stamp {
        let sprite: SKSpriteNode
        let targetAlpha: CGFloat
        let time: TimeInterval   // reveal time from the start of the recipe
    }

    private var stamps: [Stamp] = []
    /// Total reveal length in seconds.
    let revealDuration: TimeInterval

    init(recipe: StrokeRecipe, style: RenderStyle = RenderStyle(), scale: CGFloat) {
        var stamps: [Stamp] = []
        var clock: TimeInterval = 0

        for (strokeIndex, stroke) in recipe.strokes.enumerated() {
            // Space dabs off the *thinnest* part of the stroke so low-pressure
            // sections stay continuous, then compensate alpha per dab below.
            let minPressure = stroke.points.map(\.pressure).min() ?? 1
            let spacing = max(stroke.width / 2 * 0.38 * max(minPressure, 0.05), 0.0015)
            var rng = SeededRandom(seed: UInt64(strokeIndex &+ 1) &* 0x9E3779B9)

            for dab in stroke.dabs(spacing: spacing) {
                let t = CGFloat(dab.t)
                var radius = CGFloat(dab.radius) * scale
                // Flow compensation: heavily overlapped (wide) sections get
                // fainter stamps so built-up coverage is uniform ink, not mud.
                let flow = min(max(spacing * scale / max(radius, 0.5) * 0.95, 0.02), 0.6)
                var alpha = CGFloat(stroke.ink) * flow

                // The brush depletes as the stroke travels.
                alpha *= 1 - 0.30 * t

                // Dry-brush: contiguous streaks of missing ink, plus bristle
                // jitter. Two incommensurate waves make the gaps irregular.
                let dryness = CGFloat(stroke.dryness)
                if dryness > 0 {
                    let wave = 0.5 + 0.5 * sin(t * 43 + rng.phase)
                        * sin(t * 17.3 + rng.phase * 1.7)
                    if wave < dryness * 0.55 { alpha *= 0.12 }
                    alpha *= 1 - dryness * 0.35 * rng.next()
                }

                // Wet ink spreads, lightens, and droops.
                radius *= 1 + 0.45 * style.wetness
                alpha *= 1 - 0.38 * style.wetness

                var position = CGPoint(
                    x: CGFloat(dab.position.x) * scale,
                    y: CGFloat(dab.position.y) * scale
                )
                let jitterScale = 0.12 + 0.55 * CGFloat(stroke.dryness)
                position.x += (rng.next() - 0.5) * radius * jitterScale
                position.y += (rng.next() - 0.5) * radius * jitterScale
                position.y -= radius * 0.5 * style.wetness   // rain pulls ink down

                let time = clock + stroke.duration * Double(dab.t)
                stamps.append(Self.stamp(
                    texture: StrokeTextures.soft, position: position, radius: radius,
                    alpha: alpha, color: style.ink, time: time
                ))

                // Edge pooling at the stroke's start and end, where the
                // brush pauses.
                let pooling = CGFloat(stroke.pooling)
                if pooling > 0, t < 0.05 || t > 0.93 {
                    stamps.append(Self.stamp(
                        texture: StrokeTextures.pooled, position: position,
                        radius: radius * 1.1, alpha: alpha * pooling * 0.6,
                        color: style.ink, time: time
                    ))
                }

                // Soaked paper: a faint halo blooms around the stroke.
                if style.wetness > 0.05 {
                    stamps.append(Self.stamp(
                        texture: StrokeTextures.soft,
                        position: CGPoint(x: position.x, y: position.y - radius * 0.4 * style.wetness),
                        radius: radius * 1.9, alpha: alpha * 0.22 * style.wetness,
                        color: style.ink, time: time
                    ))
                }
            }
            clock += stroke.duration + recipe.strokeGap
        }

        self.stamps = stamps
        self.revealDuration = max(0, clock - recipe.strokeGap)
        super.init()
        stamps.forEach { addChild($0.sprite) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private static func stamp(
        texture: SKTexture, position: CGPoint, radius: CGFloat,
        alpha: CGFloat, color: UIColor, time: TimeInterval
    ) -> Stamp {
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: radius * 2, height: radius * 2)
        sprite.position = position
        sprite.color = color
        sprite.colorBlendFactor = 1
        sprite.alpha = 0
        return Stamp(sprite: sprite, targetAlpha: alpha, time: time)
    }

    /// Shows the finished recipe with no animation.
    func showInstantly() {
        for stamp in stamps {
            stamp.sprite.removeAllActions()
            stamp.sprite.alpha = stamp.targetAlpha
        }
    }

    /// Paints the recipe in over time. Returns the total duration.
    @discardableResult
    func reveal(after delay: TimeInterval = 0) -> TimeInterval {
        for stamp in stamps {
            stamp.sprite.removeAllActions()
            stamp.sprite.alpha = 0
            stamp.sprite.run(.sequence([
                .wait(forDuration: delay + stamp.time),
                .fadeAlpha(to: stamp.targetAlpha, duration: 0.09),
            ]))
        }
        return delay + revealDuration + 0.09
    }
}

/// Deterministic per-stroke randomness so a recipe always inks the same way.
private struct SeededRandom {
    private var state: UInt64
    let phase: CGFloat

    init(seed: UInt64) {
        state = seed == 0 ? 0x1234_5678 : seed
        _ = Self.step(&state)
        phase = CGFloat(Self.step(&state) % 6283) / 1000
    }

    mutating func next() -> CGFloat {
        CGFloat(Self.step(&state) % 10_000) / 10_000
    }

    private static func step(_ state: inout UInt64) -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state >> 33
    }
}
