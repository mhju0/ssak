import Foundation

/// Dish art — deliberately cheap (spec §3 budget: "dish art from 2 archetypes,
/// bowl + skewer"). Dishes are consumed for buffs, not collected, so they
/// share two recipes keyed by the dish's `archetype` (not its id, unlike the
/// specimen tables).
extension Recipes {
    public static let dishArt: [String: StrokeRecipe] = [
        "bowl": bowl,
        "skewer": skewer,
    ]

    /// A steaming bowl — body, rim, a mound of contents, two steam wisps.
    public static let bowl = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.26, 0.46, pressure: 0.5),
            StrokePoint(0.50, 0.28, pressure: 0.9),
            StrokePoint(0.74, 0.46, pressure: 0.5),
        ], width: 0.06, ink: 0.7, dryness: 0.2, pooling: 0.3, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.26, 0.47, pressure: 0.5),
            StrokePoint(0.50, 0.53, pressure: 0.7),
            StrokePoint(0.74, 0.47, pressure: 0.5),
        ], width: 0.03, ink: 0.8, dryness: 0.15, pooling: 0.35, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.38, 0.47, pressure: 0.5),
            StrokePoint(0.50, 0.56, pressure: 0.75),
            StrokePoint(0.62, 0.47, pressure: 0.5),
        ], width: 0.08, ink: 0.45, dryness: 0.35, pooling: 0.25, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.44, 0.57, pressure: 0.3),
            StrokePoint(0.47, 0.67, pressure: 0.2),
            StrokePoint(0.43, 0.77, pressure: 0.08),
        ], width: 0.02, ink: 0.4, dryness: 0.3, pooling: 0.1, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.56, 0.57, pressure: 0.3),
            StrokePoint(0.53, 0.68, pressure: 0.2),
            StrokePoint(0.57, 0.78, pressure: 0.08),
        ], width: 0.02, ink: 0.38, dryness: 0.3, pooling: 0.1, duration: 0.3),
    ])

    /// A grilled fish on a skewer — stick, body, tail, two char marks.
    public static let skewer = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.16, 0.34, pressure: 0.4),
            StrokePoint(0.84, 0.46, pressure: 0.4),
        ], width: 0.02, ink: 0.7, dryness: 0.25, pooling: 0.1, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.34, 0.42, pressure: 0.5),
            StrokePoint(0.50, 0.52, pressure: 0.9),
            StrokePoint(0.66, 0.46, pressure: 0.5),
        ], width: 0.09, ink: 0.55, dryness: 0.3, pooling: 0.3, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.34, 0.42, pressure: 0.5),
            StrokePoint(0.50, 0.32, pressure: 0.8),
            StrokePoint(0.66, 0.44, pressure: 0.5),
        ], width: 0.08, ink: 0.5, dryness: 0.3, pooling: 0.3, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.66, 0.45, pressure: 0.4),
            StrokePoint(0.77, 0.52, pressure: 0.15),
        ], width: 0.04, ink: 0.55, dryness: 0.4, pooling: 0.15, duration: 0.25),
        Stroke(points: [
            StrokePoint(0.44, 0.40, pressure: 0.4),
            StrokePoint(0.46, 0.50, pressure: 0.3),
        ], width: 0.015, ink: 0.85, dryness: 0.2, pooling: 0.1, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.54, 0.40, pressure: 0.4),
            StrokePoint(0.56, 0.50, pressure: 0.3),
        ], width: 0.015, ink: 0.85, dryness: 0.2, pooling: 0.1, duration: 0.2),
    ])
}
