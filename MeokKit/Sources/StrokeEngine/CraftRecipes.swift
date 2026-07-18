import Foundation

/// Crafting art — two cheap archetypes (spec §3 budget: tool + furniture),
/// keyed by the craftable's `archetype`. Rods, brushes, and kits render as the
/// tool; baskets, furniture, and lanterns as the furnishing.
extension Recipes {
    public static let craftArt: [String: StrokeRecipe] = [
        "tool": tool,
        "furniture": furniture,
    ]

    /// A brush/rod implement — a slim shaft, a binding, a splayed tuft.
    public static let tool = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.28, 0.20, pressure: 0.5),
            StrokePoint(0.58, 0.72, pressure: 0.35),
        ], width: 0.028, ink: 0.7, dryness: 0.2, pooling: 0.15, duration: 0.35),
        Stroke(points: [
            StrokePoint(0.50, 0.58, pressure: 0.5),
            StrokePoint(0.55, 0.65, pressure: 0.5),
        ], width: 0.03, ink: 0.85, dryness: 0.1, pooling: 0.3, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.58, 0.72, pressure: 0.4),
            StrokePoint(0.55, 0.88, pressure: 0.1),
        ], width: 0.02, ink: 0.6, dryness: 0.4, pooling: 0.1, duration: 0.22),
        Stroke(points: [
            StrokePoint(0.58, 0.72, pressure: 0.4),
            StrokePoint(0.63, 0.88, pressure: 0.1),
        ], width: 0.02, ink: 0.58, dryness: 0.4, pooling: 0.1, duration: 0.22),
        Stroke(points: [
            StrokePoint(0.58, 0.72, pressure: 0.4),
            StrokePoint(0.60, 0.90, pressure: 0.1),
        ], width: 0.018, ink: 0.55, dryness: 0.4, pooling: 0.1, duration: 0.22),
        Stroke(points: [
            StrokePoint(0.28, 0.20, pressure: 0.4),
            StrokePoint(0.24, 0.13, pressure: 0.2),
        ], width: 0.03, ink: 0.65, dryness: 0.2, pooling: 0.2, duration: 0.2),
    ])

    /// A low table — plank top, front edge, two legs.
    public static let furniture = StrokeRecipe(strokes: [
        Stroke(points: [
            StrokePoint(0.22, 0.56, pressure: 0.6),
            StrokePoint(0.50, 0.60, pressure: 0.8),
            StrokePoint(0.78, 0.56, pressure: 0.6),
        ], width: 0.06, ink: 0.6, dryness: 0.25, pooling: 0.3, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.24, 0.53, pressure: 0.4),
            StrokePoint(0.76, 0.53, pressure: 0.4),
        ], width: 0.02, ink: 0.75, dryness: 0.2, pooling: 0.15, duration: 0.25),
        Stroke(points: [
            StrokePoint(0.31, 0.53, pressure: 0.5),
            StrokePoint(0.30, 0.30, pressure: 0.4),
        ], width: 0.03, ink: 0.7, dryness: 0.2, pooling: 0.2, duration: 0.28),
        Stroke(points: [
            StrokePoint(0.69, 0.53, pressure: 0.5),
            StrokePoint(0.70, 0.30, pressure: 0.4),
        ], width: 0.03, ink: 0.7, dryness: 0.2, pooling: 0.2, duration: 0.28),
        Stroke(points: [
            StrokePoint(0.30, 0.31, pressure: 0.35),
            StrokePoint(0.70, 0.31, pressure: 0.35),
        ], width: 0.018, ink: 0.5, dryness: 0.3, pooling: 0.15, duration: 0.22),
    ])
}
