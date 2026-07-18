import Foundation

/// The Artistry composition scenes (spec §2), one framed landscape per zone,
/// keyed by the kernel's composition id. These strokes double as the ghost
/// paths the player traces; the live sky bakes in at render time via
/// RenderStyle (wetness/darkness), so rain vs. snow is a different work.
extension Recipes {
    public static let composition: [String: StrokeRecipe] = [
        "pond-vista": pondVista,
        "hermitage": hermitageScene,
        "peak": peakScene,
        "forest": forestScene,
        "terrace": terraceScene,
    ]

    /// A pond: far shore, water line, reeds, a fish rising, a ripple.
    public static let pondVista = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.06, 0.58, pressure: 0.4),
            StrokePoint(0.50, 0.56, pressure: 0.6),
            StrokePoint(0.94, 0.58, pressure: 0.35),
        ], width: 0.05, ink: 0.3, dryness: 0.35, pooling: 0.2, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.08, 0.40, pressure: 0.35),
            StrokePoint(0.50, 0.38, pressure: 0.5),
            StrokePoint(0.92, 0.40, pressure: 0.3),
        ], width: 0.04, ink: 0.24, dryness: 0.4, pooling: 0.15, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.20, 0.40, pressure: 0.4),
            StrokePoint(0.18, 0.64, pressure: 0.1),
        ], width: 0.016, ink: 0.6, dryness: 0.25, pooling: 0.15, duration: 0.25),
        Stroke(points: [
            StrokePoint(0.24, 0.40, pressure: 0.4),
            StrokePoint(0.27, 0.68, pressure: 0.08),
        ], width: 0.016, ink: 0.55, dryness: 0.25, pooling: 0.15, duration: 0.25),
        Stroke(points: [
            StrokePoint(0.56, 0.30, pressure: 0.4),
            StrokePoint(0.65, 0.36, pressure: 0.7),
            StrokePoint(0.73, 0.30, pressure: 0.4),
        ], width: 0.035, ink: 0.6, dryness: 0.3, pooling: 0.3, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.62, 0.35, pressure: 0.7),
            StrokePoint(0.60, 0.34, pressure: 0.6),
        ], width: 0.03, ink: 0.85, dryness: 0.0, pooling: 0.6, duration: 0.2),
    ])

    /// The hermitage: ground, a thatched hut, a pine at the side.
    public static let hermitageScene = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.06, 0.24, pressure: 0.5),
            StrokePoint(0.94, 0.22, pressure: 0.4),
        ], width: 0.04, ink: 0.35, dryness: 0.35, pooling: 0.15, duration: 0.35),
        Stroke(points: [
            StrokePoint(0.28, 0.50, pressure: 0.35),
            StrokePoint(0.50, 0.64, pressure: 0.85),
            StrokePoint(0.72, 0.50, pressure: 0.35),
        ], width: 0.06, ink: 0.7, dryness: 0.3, pooling: 0.3, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.34, 0.50, pressure: 0.5),
            StrokePoint(0.35, 0.25, pressure: 0.4),
        ], width: 0.03, ink: 0.6, dryness: 0.15, pooling: 0.2, duration: 0.25),
        Stroke(points: [
            StrokePoint(0.66, 0.50, pressure: 0.5),
            StrokePoint(0.65, 0.25, pressure: 0.4),
        ], width: 0.03, ink: 0.6, dryness: 0.15, pooling: 0.2, duration: 0.25),
        Stroke(points: [
            StrokePoint(0.50, 0.44, pressure: 0.7),
            StrokePoint(0.50, 0.26, pressure: 0.6),
        ], width: 0.055, ink: 0.72, dryness: 0.1, pooling: 0.4, duration: 0.25),
        Stroke(points: [
            StrokePoint(0.83, 0.24, pressure: 0.6),
            StrokePoint(0.81, 0.48, pressure: 0.4),
            StrokePoint(0.85, 0.68, pressure: 0.2),
        ], width: 0.05, ink: 0.55, dryness: 0.5, pooling: 0.15, duration: 0.35),
    ])

    /// The peak: a mountain profile behind a mist band and a near ridge.
    public static let peakScene = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.12, 0.30, pressure: 0.4),
            StrokePoint(0.42, 0.80, pressure: 0.85),
            StrokePoint(0.56, 0.62, pressure: 0.5),
            StrokePoint(0.86, 0.32, pressure: 0.35),
        ], width: 0.05, ink: 0.55, dryness: 0.35, pooling: 0.25, duration: 0.5),
        Stroke(points: [
            StrokePoint(0.60, 0.42, pressure: 0.35),
            StrokePoint(0.74, 0.58, pressure: 0.5),
            StrokePoint(0.90, 0.42, pressure: 0.3),
        ], width: 0.04, ink: 0.38, dryness: 0.4, pooling: 0.2, duration: 0.35),
        Stroke(points: [
            StrokePoint(0.05, 0.46, pressure: 0.4),
            StrokePoint(0.50, 0.44, pressure: 0.55),
            StrokePoint(0.95, 0.46, pressure: 0.35),
        ], width: 0.09, ink: 0.18, dryness: 0.5, pooling: 0.15, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.06, 0.24, pressure: 0.45),
            StrokePoint(0.34, 0.40, pressure: 0.7),
            StrokePoint(0.62, 0.26, pressure: 0.4),
        ], width: 0.06, ink: 0.45, dryness: 0.4, pooling: 0.2, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.72, 0.26, pressure: 0.4),
            StrokePoint(0.80, 0.40, pressure: 0.55),
            StrokePoint(0.90, 0.26, pressure: 0.35),
        ], width: 0.045, ink: 0.4, dryness: 0.4, pooling: 0.2, duration: 0.3),
    ])

    /// The forest: three ink trees on a ground line.
    public static let forestScene = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.06, 0.22, pressure: 0.5),
            StrokePoint(0.94, 0.20, pressure: 0.4),
        ], width: 0.04, ink: 0.35, dryness: 0.35, pooling: 0.15, duration: 0.35),
        Stroke(points: [
            StrokePoint(0.25, 0.21, pressure: 0.6),
            StrokePoint(0.26, 0.52, pressure: 0.35),
        ], width: 0.03, ink: 0.65, dryness: 0.3, pooling: 0.2, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.14, 0.52, pressure: 0.5),
            StrokePoint(0.26, 0.68, pressure: 0.8),
            StrokePoint(0.38, 0.52, pressure: 0.5),
        ], width: 0.10, ink: 0.42, dryness: 0.5, pooling: 0.2, duration: 0.35),
        Stroke(points: [
            StrokePoint(0.50, 0.21, pressure: 0.6),
            StrokePoint(0.50, 0.56, pressure: 0.35),
        ], width: 0.032, ink: 0.68, dryness: 0.3, pooling: 0.2, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.39, 0.56, pressure: 0.5),
            StrokePoint(0.50, 0.74, pressure: 0.85),
            StrokePoint(0.61, 0.56, pressure: 0.5),
        ], width: 0.11, ink: 0.45, dryness: 0.5, pooling: 0.2, duration: 0.38),
        Stroke(points: [
            StrokePoint(0.73, 0.21, pressure: 0.55),
            StrokePoint(0.74, 0.50, pressure: 0.3),
        ], width: 0.028, ink: 0.6, dryness: 0.3, pooling: 0.2, duration: 0.28),
        Stroke(points: [
            StrokePoint(0.63, 0.50, pressure: 0.45),
            StrokePoint(0.74, 0.64, pressure: 0.75),
            StrokePoint(0.85, 0.50, pressure: 0.45),
        ], width: 0.09, ink: 0.4, dryness: 0.5, pooling: 0.2, duration: 0.35),
    ])

    /// The terrace: garden bed rows, a sprout, a tree at the edge, a fence.
    public static let terraceScene = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.10, 0.30, pressure: 0.45),
            StrokePoint(0.90, 0.28, pressure: 0.4),
        ], width: 0.04, ink: 0.4, dryness: 0.35, pooling: 0.15, duration: 0.32),
        Stroke(points: [
            StrokePoint(0.10, 0.20, pressure: 0.45),
            StrokePoint(0.90, 0.18, pressure: 0.4),
        ], width: 0.04, ink: 0.38, dryness: 0.35, pooling: 0.15, duration: 0.32),
        Stroke(points: [
            StrokePoint(0.35, 0.30, pressure: 0.4),
            StrokePoint(0.36, 0.46, pressure: 0.12),
        ], width: 0.02, ink: 0.55, dryness: 0.3, pooling: 0.15, duration: 0.22),
        Stroke(points: [
            StrokePoint(0.36, 0.40, pressure: 0.3),
            StrokePoint(0.28, 0.47, pressure: 0.1),
        ], width: 0.018, ink: 0.5, dryness: 0.3, pooling: 0.12, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.80, 0.20, pressure: 0.55),
            StrokePoint(0.79, 0.50, pressure: 0.35),
            StrokePoint(0.83, 0.66, pressure: 0.15),
        ], width: 0.045, ink: 0.55, dryness: 0.45, pooling: 0.15, duration: 0.35),
        Stroke(points: [
            StrokePoint(0.14, 0.34, pressure: 0.4),
            StrokePoint(0.52, 0.33, pressure: 0.35),
        ], width: 0.016, ink: 0.5, dryness: 0.2, pooling: 0.1, duration: 0.25),
    ])
}
