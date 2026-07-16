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

    /// The keeper, standing with staff: 7 strokes. The 갓 is the darkest ink
    /// (readability rule: hierarchy by stroke weight).
    public static let keeperStanding = StrokeRecipe(strokes: [
        // 갓 brim: one wide shallow cone.
        Stroke(points: [
            StrokePoint(0.34, 0.775, pressure: 0.28),
            StrokePoint(0.50, 0.825, pressure: 0.6),
            StrokePoint(0.66, 0.775, pressure: 0.28),
        ], width: 0.06, ink: 0.95, dryness: 0.15, pooling: 0.3, duration: 0.35),
        // 갓 crown.
        Stroke(points: [
            StrokePoint(0.47, 0.84, pressure: 0.7),
            StrokePoint(0.53, 0.885, pressure: 0.5),
        ], width: 0.09, ink: 0.95, dryness: 0.1, pooling: 0.3, duration: 0.2),
        // Face hint — barely there.
        Stroke(points: [
            StrokePoint(0.50, 0.77, pressure: 0.5),
            StrokePoint(0.50, 0.72, pressure: 0.35),
        ], width: 0.05, ink: 0.35, dryness: 0.2, pooling: 0.1, duration: 0.15),
        // Robe: one pull, flaring to the hem.
        Stroke(points: [
            StrokePoint(0.50, 0.72, pressure: 0.45),
            StrokePoint(0.47, 0.48, pressure: 0.8),
            StrokePoint(0.44, 0.20, pressure: 1.0),
        ], width: 0.20, ink: 0.7, dryness: 0.25, pooling: 0.4, duration: 0.5),
        // Sleeve falling open.
        Stroke(points: [
            StrokePoint(0.54, 0.68, pressure: 0.35),
            StrokePoint(0.62, 0.48, pressure: 0.55),
            StrokePoint(0.66, 0.30, pressure: 0.22),
        ], width: 0.10, ink: 0.6, dryness: 0.35, pooling: 0.25, duration: 0.35),
        // Hem shadow.
        Stroke(points: [
            StrokePoint(0.38, 0.16, pressure: 0.5),
            StrokePoint(0.58, 0.18, pressure: 0.35),
        ], width: 0.05, ink: 0.42, dryness: 0.4, pooling: 0.2, duration: 0.25),
        // Staff.
        Stroke(points: [
            StrokePoint(0.655, 0.62, pressure: 0.5),
            StrokePoint(0.69, 0.14, pressure: 0.35),
        ], width: 0.022, ink: 0.85, dryness: 0.08, pooling: 0.25, duration: 0.35),
    ])

    /// The keeper, seated: 6 strokes, hunched forward.
    public static let keeperSeated = StrokeRecipe(strokes: [
        // 갓 brim.
        Stroke(points: [
            StrokePoint(0.34, 0.635, pressure: 0.28),
            StrokePoint(0.50, 0.685, pressure: 0.6),
            StrokePoint(0.66, 0.635, pressure: 0.28),
        ], width: 0.06, ink: 0.95, dryness: 0.15, pooling: 0.3, duration: 0.35),
        // 갓 crown.
        Stroke(points: [
            StrokePoint(0.47, 0.70, pressure: 0.7),
            StrokePoint(0.53, 0.745, pressure: 0.5),
        ], width: 0.09, ink: 0.95, dryness: 0.1, pooling: 0.3, duration: 0.2),
        // Hunched back sliding to the ground.
        Stroke(points: [
            StrokePoint(0.50, 0.62, pressure: 0.5),
            StrokePoint(0.42, 0.45, pressure: 0.9),
            StrokePoint(0.38, 0.22, pressure: 0.85),
        ], width: 0.20, ink: 0.7, dryness: 0.25, pooling: 0.4, duration: 0.5),
        // Lap and folded knees.
        Stroke(points: [
            StrokePoint(0.40, 0.30, pressure: 0.7),
            StrokePoint(0.60, 0.26, pressure: 0.9),
            StrokePoint(0.70, 0.30, pressure: 0.3),
        ], width: 0.13, ink: 0.62, dryness: 0.3, pooling: 0.3, duration: 0.4),
        // Arm resting toward the knees.
        Stroke(points: [
            StrokePoint(0.52, 0.55, pressure: 0.35),
            StrokePoint(0.62, 0.38, pressure: 0.5),
        ], width: 0.09, ink: 0.55, dryness: 0.35, pooling: 0.2, duration: 0.3),
        // Ground shadow under the sitting fold.
        Stroke(points: [
            StrokePoint(0.36, 0.16, pressure: 0.4),
            StrokePoint(0.66, 0.18, pressure: 0.45),
        ], width: 0.05, ink: 0.38, dryness: 0.45, pooling: 0.2, duration: 0.25),
    ])
}
