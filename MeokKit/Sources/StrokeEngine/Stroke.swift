import Foundation

/// A point in recipe space with brush pressure. Recipes are authored in an
/// arbitrary unit square; the renderer scales them onto the scene.
public struct StrokePoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    /// Brush pressure 0…1; stroke width at this point = width × pressure.
    public var pressure: Double

    public init(_ x: Double, _ y: Double, pressure: Double = 0.6) {
        self.x = x
        self.y = y
        self.pressure = pressure
    }
}

/// One brush stroke as pure data: a Catmull-Rom spline with ink dynamics.
/// Never a texture, never an image.
public struct Stroke: Codable, Equatable, Sendable {
    public var points: [StrokePoint]
    /// Maximum brush width in recipe units (reached at pressure 1).
    public var width: Double
    /// Ink load 0…1 — darkness of the stroke.
    public var ink: Double
    /// Dry-brush breakup 0…1 — streaks and missing ink.
    public var dryness: Double
    /// Edge pooling 0…1 — ink gathering at the stroke's start and end.
    public var pooling: Double
    /// Reveal time in seconds when the stroke paints itself in.
    public var duration: Double

    public init(
        points: [StrokePoint],
        width: Double,
        ink: Double = 0.85,
        dryness: Double = 0.15,
        pooling: Double = 0.5,
        duration: Double = 0.5
    ) {
        self.points = points
        self.width = width
        self.ink = ink
        self.dryness = dryness
        self.pooling = pooling
        self.duration = duration
    }
}

/// An ordered stroke sequence — how every asset in the game is defined.
public struct StrokeRecipe: Codable, Equatable, Sendable {
    public var strokes: [Stroke]
    /// Pause between consecutive strokes during the reveal, seconds.
    public var strokeGap: Double

    public init(strokes: [Stroke], strokeGap: Double = 0.12) {
        self.strokes = strokes
        self.strokeGap = strokeGap
    }
}
