import Foundation

/// Authored stroke recipes — the first entries of the species art table.
/// Coordinates live in a unit square, y-up.
public enum Recipes {
    /// The carp (잉어): ~10 strokes in classical order, eye dotted last.
    public static let carp = StrokeRecipe(strokes: [
        // Back sweep: nose over the arched back to the tail base.
        Stroke(points: [
            StrokePoint(0.78, 0.52, pressure: 0.45),
            StrokePoint(0.68, 0.60, pressure: 0.85),
            StrokePoint(0.48, 0.63, pressure: 1.0),
            StrokePoint(0.32, 0.55, pressure: 0.55),
            StrokePoint(0.24, 0.50, pressure: 0.22),
        ], width: 0.115, ink: 0.92, dryness: 0.22, pooling: 0.35, duration: 0.95),

        // Belly: lighter wash, leaves a breath of paper between the two.
        Stroke(points: [
            StrokePoint(0.74, 0.47, pressure: 0.4),
            StrokePoint(0.55, 0.435, pressure: 0.8),
            StrokePoint(0.38, 0.455, pressure: 0.5),
            StrokePoint(0.27, 0.48, pressure: 0.18),
        ], width: 0.085, ink: 0.5, dryness: 0.35, pooling: 0.25, duration: 0.7),

        // Gill arc behind the head.
        Stroke(points: [
            StrokePoint(0.70, 0.585, pressure: 0.35),
            StrokePoint(0.665, 0.52, pressure: 0.65),
            StrokePoint(0.675, 0.465, pressure: 0.25),
        ], width: 0.035, ink: 0.78, dryness: 0.3, pooling: 0.4, duration: 0.4),

        // Tail: two flicks fanning from the base.
        Stroke(points: [
            StrokePoint(0.24, 0.505, pressure: 0.7),
            StrokePoint(0.13, 0.60, pressure: 0.35),
            StrokePoint(0.065, 0.665, pressure: 0.08),
        ], width: 0.07, ink: 0.82, dryness: 0.5, pooling: 0.2, duration: 0.45),
        Stroke(points: [
            StrokePoint(0.24, 0.49, pressure: 0.7),
            StrokePoint(0.125, 0.415, pressure: 0.3),
            StrokePoint(0.075, 0.35, pressure: 0.08),
        ], width: 0.07, ink: 0.82, dryness: 0.55, pooling: 0.2, duration: 0.45),

        // Dorsal fin: one soft fan on the back.
        Stroke(points: [
            StrokePoint(0.53, 0.665, pressure: 0.18),
            StrokePoint(0.455, 0.72, pressure: 0.5),
            StrokePoint(0.385, 0.665, pressure: 0.2),
        ], width: 0.05, ink: 0.68, dryness: 0.5, pooling: 0.2, duration: 0.4),

        // Pectoral fin under the head, trailing back.
        Stroke(points: [
            StrokePoint(0.655, 0.445, pressure: 0.55),
            StrokePoint(0.60, 0.365, pressure: 0.28),
            StrokePoint(0.565, 0.315, pressure: 0.08),
        ], width: 0.05, ink: 0.62, dryness: 0.45, pooling: 0.2, duration: 0.35),

        // Ventral fin, smaller.
        Stroke(points: [
            StrokePoint(0.445, 0.425, pressure: 0.45),
            StrokePoint(0.405, 0.35, pressure: 0.12),
        ], width: 0.04, ink: 0.5, dryness: 0.5, pooling: 0.2, duration: 0.3),

        // Barbel — the carp's whisker.
        Stroke(points: [
            StrokePoint(0.775, 0.485, pressure: 0.28),
            StrokePoint(0.815, 0.44, pressure: 0.07),
        ], width: 0.02, ink: 0.7, dryness: 0.2, pooling: 0.1, duration: 0.25),

        // The eye, dotted last — 화룡점정.
        Stroke(points: [
            StrokePoint(0.715, 0.555, pressure: 0.95),
            StrokePoint(0.705, 0.545, pressure: 0.85),
        ], width: 0.032, ink: 1.0, dryness: 0.0, pooling: 0.85, duration: 0.2),
    ])
}
