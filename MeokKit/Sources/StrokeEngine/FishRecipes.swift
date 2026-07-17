import Foundation

/// The fishing species art table — one distinct recipe per species,
/// keyed by the kernel's species id (docs/design/unlock-tables.md §5).
/// Archetypes: carp-shape, slender-shape, whisker-shape, small-fry.
/// All fish face right; the eye is dotted last (화룡점정).
extension Recipes {
    public static let fish: [String: StrokeRecipe] = [
        "common-carp": carp,
        "crucian-carp": crucianCarp,
        "pale-chub": paleChub,
        "catfish": catfish,
        "eel": eel,
        "mandarin-fish": mandarinFish,
        "snakehead": snakehead,
        "icefish": icefish,
        "cherry-trout": cherryTrout,
        "pale-carp": paleCarp,
        "ink-carp": inkCarp,
    ]

    /// Crucian carp (붕어): the carp's rounder cousin — deeper arch,
    /// shorter head, no barbel, stubby tail.
    public static let crucianCarp = StrokeRecipe(strokes: [
        // Deep back arch.
        Stroke(points: [
            StrokePoint(0.76, 0.50, pressure: 0.4),
            StrokePoint(0.64, 0.62, pressure: 0.9),
            StrokePoint(0.45, 0.66, pressure: 1.0),
            StrokePoint(0.30, 0.56, pressure: 0.5),
            StrokePoint(0.25, 0.50, pressure: 0.2),
        ], width: 0.12, ink: 0.9, dryness: 0.2, pooling: 0.35, duration: 0.9),
        // Round belly.
        Stroke(points: [
            StrokePoint(0.73, 0.45, pressure: 0.35),
            StrokePoint(0.55, 0.40, pressure: 0.85),
            StrokePoint(0.36, 0.43, pressure: 0.5),
            StrokePoint(0.27, 0.47, pressure: 0.15),
        ], width: 0.09, ink: 0.5, dryness: 0.35, pooling: 0.25, duration: 0.65),
        // Gill arc.
        Stroke(points: [
            StrokePoint(0.68, 0.57, pressure: 0.35),
            StrokePoint(0.65, 0.51, pressure: 0.6),
            StrokePoint(0.66, 0.46, pressure: 0.22),
        ], width: 0.032, ink: 0.75, dryness: 0.3, pooling: 0.4, duration: 0.35),
        // Stubby tail, two flicks.
        Stroke(points: [
            StrokePoint(0.25, 0.51, pressure: 0.65),
            StrokePoint(0.15, 0.575, pressure: 0.3),
            StrokePoint(0.10, 0.62, pressure: 0.08),
        ], width: 0.06, ink: 0.8, dryness: 0.5, pooling: 0.2, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.25, 0.48, pressure: 0.65),
            StrokePoint(0.155, 0.43, pressure: 0.28),
            StrokePoint(0.105, 0.385, pressure: 0.08),
        ], width: 0.06, ink: 0.8, dryness: 0.55, pooling: 0.2, duration: 0.4),
        // Long low dorsal.
        Stroke(points: [
            StrokePoint(0.58, 0.66, pressure: 0.2),
            StrokePoint(0.50, 0.715, pressure: 0.5),
            StrokePoint(0.41, 0.685, pressure: 0.2),
        ], width: 0.05, ink: 0.66, dryness: 0.5, pooling: 0.2, duration: 0.4),
        // Small pectoral.
        Stroke(points: [
            StrokePoint(0.63, 0.43, pressure: 0.5),
            StrokePoint(0.585, 0.36, pressure: 0.12),
        ], width: 0.04, ink: 0.58, dryness: 0.45, pooling: 0.2, duration: 0.3),
        // Eye.
        Stroke(points: [
            StrokePoint(0.70, 0.535, pressure: 0.95),
            StrokePoint(0.695, 0.525, pressure: 0.85),
        ], width: 0.028, ink: 1.0, dryness: 0.0, pooling: 0.85, duration: 0.2),
    ])

    /// Pale chub (피라미): a slim silver dart — light ink, dry lateral
    /// stripe, forked tail.
    public static let paleChub = StrokeRecipe(strokes: [
        // Spindle body.
        Stroke(points: [
            StrokePoint(0.78, 0.52, pressure: 0.3),
            StrokePoint(0.60, 0.565, pressure: 0.75),
            StrokePoint(0.40, 0.55, pressure: 0.6),
            StrokePoint(0.26, 0.51, pressure: 0.25),
        ], width: 0.06, ink: 0.6, dryness: 0.25, pooling: 0.3, duration: 0.6),
        // Belly gleam.
        Stroke(points: [
            StrokePoint(0.72, 0.49, pressure: 0.3),
            StrokePoint(0.50, 0.475, pressure: 0.5),
            StrokePoint(0.32, 0.485, pressure: 0.18),
        ], width: 0.035, ink: 0.35, dryness: 0.35, pooling: 0.2, duration: 0.4),
        // Dry lateral stripe.
        Stroke(points: [
            StrokePoint(0.70, 0.525, pressure: 0.3),
            StrokePoint(0.45, 0.53, pressure: 0.4),
            StrokePoint(0.30, 0.51, pressure: 0.15),
        ], width: 0.015, ink: 0.5, dryness: 0.6, pooling: 0.1, duration: 0.35),
        // Forked tail.
        Stroke(points: [
            StrokePoint(0.26, 0.52, pressure: 0.45),
            StrokePoint(0.16, 0.575, pressure: 0.2),
            StrokePoint(0.115, 0.60, pressure: 0.06),
        ], width: 0.035, ink: 0.55, dryness: 0.5, pooling: 0.15, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.26, 0.50, pressure: 0.45),
            StrokePoint(0.165, 0.45, pressure: 0.2),
            StrokePoint(0.12, 0.425, pressure: 0.06),
        ], width: 0.035, ink: 0.55, dryness: 0.5, pooling: 0.15, duration: 0.3),
        // Eye.
        Stroke(points: [
            StrokePoint(0.735, 0.53, pressure: 0.9),
            StrokePoint(0.73, 0.522, pressure: 0.8),
        ], width: 0.02, ink: 1.0, dryness: 0.0, pooling: 0.8, duration: 0.15),
    ])

    /// Catfish (메기): broad flat head, tapered body, the long barbels
    /// that name the archetype.
    public static let catfish = StrokeRecipe(strokes: [
        // Head mass — one wide wash, kept light so the eye stays legible.
        Stroke(points: [
            StrokePoint(0.80, 0.52, pressure: 0.8),
            StrokePoint(0.70, 0.56, pressure: 1.0),
            StrokePoint(0.60, 0.545, pressure: 0.9),
        ], width: 0.15, ink: 0.58, dryness: 0.2, pooling: 0.35, duration: 0.5),
        // Body tapering away.
        Stroke(points: [
            StrokePoint(0.60, 0.53, pressure: 0.9),
            StrokePoint(0.42, 0.52, pressure: 0.65),
            StrokePoint(0.25, 0.485, pressure: 0.3),
        ], width: 0.13, ink: 0.68, dryness: 0.3, pooling: 0.25, duration: 0.6),
        // Rounded tail flicks.
        Stroke(points: [
            StrokePoint(0.25, 0.49, pressure: 0.5),
            StrokePoint(0.15, 0.52, pressure: 0.25),
            StrokePoint(0.10, 0.56, pressure: 0.08),
        ], width: 0.05, ink: 0.7, dryness: 0.45, pooling: 0.2, duration: 0.35),
        Stroke(points: [
            StrokePoint(0.25, 0.475, pressure: 0.5),
            StrokePoint(0.16, 0.44, pressure: 0.2),
        ], width: 0.05, ink: 0.7, dryness: 0.5, pooling: 0.2, duration: 0.3),
        // Pale belly.
        Stroke(points: [
            StrokePoint(0.74, 0.465, pressure: 0.4),
            StrokePoint(0.55, 0.45, pressure: 0.55),
            StrokePoint(0.35, 0.455, pressure: 0.2),
        ], width: 0.06, ink: 0.38, dryness: 0.35, pooling: 0.2, duration: 0.4),
        // The long barbels — one up, one down.
        Stroke(points: [
            StrokePoint(0.80, 0.54, pressure: 0.25),
            StrokePoint(0.90, 0.60, pressure: 0.06),
        ], width: 0.012, ink: 0.8, dryness: 0.15, pooling: 0.1, duration: 0.25),
        Stroke(points: [
            StrokePoint(0.80, 0.50, pressure: 0.25),
            StrokePoint(0.905, 0.44, pressure: 0.06),
        ], width: 0.012, ink: 0.8, dryness: 0.15, pooling: 0.1, duration: 0.25),
        // Short second barbel.
        Stroke(points: [
            StrokePoint(0.775, 0.47, pressure: 0.2),
            StrokePoint(0.83, 0.41, pressure: 0.05),
        ], width: 0.01, ink: 0.7, dryness: 0.2, pooling: 0.1, duration: 0.2),
        // Small dorsal.
        Stroke(points: [
            StrokePoint(0.55, 0.585, pressure: 0.2),
            StrokePoint(0.51, 0.63, pressure: 0.4),
            StrokePoint(0.475, 0.59, pressure: 0.15),
        ], width: 0.035, ink: 0.6, dryness: 0.4, pooling: 0.2, duration: 0.3),
        // Small deep-set eye.
        Stroke(points: [
            StrokePoint(0.735, 0.545, pressure: 0.9),
            StrokePoint(0.73, 0.538, pressure: 0.8),
        ], width: 0.018, ink: 1.0, dryness: 0.0, pooling: 0.8, duration: 0.15),
    ])

    /// Eel (뱀장어): one long S-curve — the body is a single breath.
    public static let eel = StrokeRecipe(strokes: [
        // The S.
        Stroke(points: [
            StrokePoint(0.80, 0.55, pressure: 0.35),
            StrokePoint(0.65, 0.62, pressure: 0.6),
            StrokePoint(0.48, 0.55, pressure: 0.65),
            StrokePoint(0.33, 0.44, pressure: 0.55),
            StrokePoint(0.18, 0.40, pressure: 0.35),
            StrokePoint(0.10, 0.44, pressure: 0.12),
        ], width: 0.075, ink: 0.8, dryness: 0.2, pooling: 0.35, duration: 1.1),
        // Dorsal ribbon shadowing the back.
        Stroke(points: [
            StrokePoint(0.62, 0.645, pressure: 0.3),
            StrokePoint(0.46, 0.585, pressure: 0.4),
            StrokePoint(0.31, 0.475, pressure: 0.3),
            StrokePoint(0.17, 0.44, pressure: 0.12),
        ], width: 0.02, ink: 0.5, dryness: 0.55, pooling: 0.15, duration: 0.6),
        // Jaw.
        Stroke(points: [
            StrokePoint(0.80, 0.545, pressure: 0.3),
            StrokePoint(0.845, 0.53, pressure: 0.1),
        ], width: 0.03, ink: 0.7, dryness: 0.2, pooling: 0.2, duration: 0.2),
        // Belly gleam along the curve.
        Stroke(points: [
            StrokePoint(0.60, 0.585, pressure: 0.25),
            StrokePoint(0.47, 0.52, pressure: 0.35),
            StrokePoint(0.35, 0.43, pressure: 0.15),
        ], width: 0.018, ink: 0.3, dryness: 0.45, pooling: 0.1, duration: 0.4),
        // Eye.
        Stroke(points: [
            StrokePoint(0.79, 0.565, pressure: 0.9),
            StrokePoint(0.785, 0.558, pressure: 0.8),
        ], width: 0.018, ink: 1.0, dryness: 0.0, pooling: 0.8, duration: 0.15),
    ])

    /// Mandarin fish (쏘가리): carp-shape gone regal — spiny dorsal,
    /// mottled flanks, the big jaw.
    public static let mandarinFish = StrokeRecipe(strokes: [
        // Back.
        Stroke(points: [
            StrokePoint(0.77, 0.50, pressure: 0.4),
            StrokePoint(0.62, 0.60, pressure: 0.9),
            StrokePoint(0.44, 0.615, pressure: 0.95),
            StrokePoint(0.29, 0.53, pressure: 0.4),
            StrokePoint(0.24, 0.49, pressure: 0.2),
        ], width: 0.105, ink: 0.85, dryness: 0.22, pooling: 0.35, duration: 0.9),
        // Belly.
        Stroke(points: [
            StrokePoint(0.73, 0.455, pressure: 0.4),
            StrokePoint(0.52, 0.43, pressure: 0.75),
            StrokePoint(0.34, 0.45, pressure: 0.45),
            StrokePoint(0.27, 0.47, pressure: 0.15),
        ], width: 0.08, ink: 0.5, dryness: 0.35, pooling: 0.25, duration: 0.65),
        // Three dorsal spines.
        Stroke(points: [
            StrokePoint(0.575, 0.615, pressure: 0.4),
            StrokePoint(0.555, 0.685, pressure: 0.12),
        ], width: 0.022, ink: 0.8, dryness: 0.3, pooling: 0.15, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.51, 0.63, pressure: 0.4),
            StrokePoint(0.49, 0.70, pressure: 0.12),
        ], width: 0.022, ink: 0.8, dryness: 0.3, pooling: 0.15, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.445, 0.625, pressure: 0.35),
            StrokePoint(0.425, 0.685, pressure: 0.1),
        ], width: 0.022, ink: 0.8, dryness: 0.3, pooling: 0.15, duration: 0.2),
        // Web between the spines.
        Stroke(points: [
            StrokePoint(0.575, 0.64, pressure: 0.3),
            StrokePoint(0.50, 0.665, pressure: 0.45),
            StrokePoint(0.435, 0.645, pressure: 0.2),
        ], width: 0.035, ink: 0.45, dryness: 0.5, pooling: 0.15, duration: 0.3),
        // Mottled blotches.
        Stroke(points: [
            StrokePoint(0.60, 0.53, pressure: 0.7),
            StrokePoint(0.58, 0.515, pressure: 0.5),
        ], width: 0.06, ink: 0.45, dryness: 0.3, pooling: 0.1, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.48, 0.55, pressure: 0.7),
            StrokePoint(0.46, 0.53, pressure: 0.5),
        ], width: 0.07, ink: 0.42, dryness: 0.3, pooling: 0.1, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.37, 0.50, pressure: 0.6),
            StrokePoint(0.355, 0.49, pressure: 0.45),
        ], width: 0.05, ink: 0.4, dryness: 0.3, pooling: 0.1, duration: 0.2),
        // Broad tail.
        Stroke(points: [
            StrokePoint(0.24, 0.50, pressure: 0.6),
            StrokePoint(0.14, 0.545, pressure: 0.3),
            StrokePoint(0.095, 0.575, pressure: 0.08),
        ], width: 0.06, ink: 0.78, dryness: 0.45, pooling: 0.2, duration: 0.35),
        Stroke(points: [
            StrokePoint(0.24, 0.485, pressure: 0.6),
            StrokePoint(0.15, 0.435, pressure: 0.25),
        ], width: 0.06, ink: 0.78, dryness: 0.5, pooling: 0.2, duration: 0.3),
        // The jaw.
        Stroke(points: [
            StrokePoint(0.77, 0.475, pressure: 0.35),
            StrokePoint(0.815, 0.455, pressure: 0.1),
        ], width: 0.025, ink: 0.7, dryness: 0.2, pooling: 0.2, duration: 0.2),
        // Eye.
        Stroke(points: [
            StrokePoint(0.71, 0.54, pressure: 0.95),
            StrokePoint(0.70, 0.53, pressure: 0.85),
        ], width: 0.028, ink: 1.0, dryness: 0.0, pooling: 0.85, duration: 0.2),
    ])

    /// Snakehead (가물치): a torpedo under a full-length dorsal ribbon.
    public static let snakehead = StrokeRecipe(strokes: [
        // Torpedo body.
        Stroke(points: [
            StrokePoint(0.79, 0.50, pressure: 0.5),
            StrokePoint(0.60, 0.535, pressure: 0.85),
            StrokePoint(0.40, 0.53, pressure: 0.8),
            StrokePoint(0.24, 0.50, pressure: 0.4),
        ], width: 0.10, ink: 0.88, dryness: 0.25, pooling: 0.3, duration: 0.9),
        // Dorsal ribbon, nose to tail.
        Stroke(points: [
            StrokePoint(0.68, 0.57, pressure: 0.35),
            StrokePoint(0.52, 0.595, pressure: 0.5),
            StrokePoint(0.36, 0.585, pressure: 0.4),
            StrokePoint(0.26, 0.55, pressure: 0.15),
        ], width: 0.035, ink: 0.6, dryness: 0.4, pooling: 0.2, duration: 0.55),
        // Belly.
        Stroke(points: [
            StrokePoint(0.72, 0.465, pressure: 0.35),
            StrokePoint(0.50, 0.455, pressure: 0.5),
            StrokePoint(0.32, 0.465, pressure: 0.2),
        ], width: 0.05, ink: 0.45, dryness: 0.35, pooling: 0.2, duration: 0.4),
        // Anal ribbon answering the dorsal.
        Stroke(points: [
            StrokePoint(0.55, 0.44, pressure: 0.3),
            StrokePoint(0.42, 0.43, pressure: 0.4),
            StrokePoint(0.30, 0.445, pressure: 0.12),
        ], width: 0.025, ink: 0.5, dryness: 0.45, pooling: 0.15, duration: 0.35),
        // Rounded tail fan.
        Stroke(points: [
            StrokePoint(0.24, 0.50, pressure: 0.5),
            StrokePoint(0.155, 0.53, pressure: 0.25),
            StrokePoint(0.115, 0.55, pressure: 0.08),
        ], width: 0.05, ink: 0.8, dryness: 0.45, pooling: 0.2, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.24, 0.49, pressure: 0.5),
            StrokePoint(0.16, 0.455, pressure: 0.22),
            StrokePoint(0.12, 0.435, pressure: 0.07),
        ], width: 0.05, ink: 0.8, dryness: 0.5, pooling: 0.2, duration: 0.3),
        // Jaw line.
        Stroke(points: [
            StrokePoint(0.79, 0.485, pressure: 0.3),
            StrokePoint(0.835, 0.47, pressure: 0.09),
        ], width: 0.022, ink: 0.75, dryness: 0.2, pooling: 0.2, duration: 0.2),
        // Eye.
        Stroke(points: [
            StrokePoint(0.745, 0.52, pressure: 0.9),
            StrokePoint(0.74, 0.512, pressure: 0.8),
        ], width: 0.02, ink: 1.0, dryness: 0.0, pooling: 0.8, duration: 0.15),
    ])

    /// Icefish (빙어): nearly transparent — a ghost of an outline around
    /// one dark eye. The paper does most of the painting.
    public static let icefish = StrokeRecipe(strokes: [
        // Faint body outline.
        Stroke(points: [
            StrokePoint(0.76, 0.52, pressure: 0.25),
            StrokePoint(0.58, 0.545, pressure: 0.45),
            StrokePoint(0.40, 0.535, pressure: 0.4),
            StrokePoint(0.28, 0.51, pressure: 0.15),
        ], width: 0.045, ink: 0.32, dryness: 0.3, pooling: 0.25, duration: 0.55),
        // Fainter belly.
        Stroke(points: [
            StrokePoint(0.71, 0.50, pressure: 0.2),
            StrokePoint(0.50, 0.49, pressure: 0.3),
            StrokePoint(0.33, 0.50, pressure: 0.12),
        ], width: 0.03, ink: 0.22, dryness: 0.35, pooling: 0.15, duration: 0.4),
        // Dry spine hint.
        Stroke(points: [
            StrokePoint(0.68, 0.525, pressure: 0.25),
            StrokePoint(0.48, 0.53, pressure: 0.3),
            StrokePoint(0.34, 0.515, pressure: 0.1),
        ], width: 0.012, ink: 0.4, dryness: 0.7, pooling: 0.1, duration: 0.35),
        // Tiny tail fork.
        Stroke(points: [
            StrokePoint(0.28, 0.515, pressure: 0.2),
            StrokePoint(0.20, 0.55, pressure: 0.08),
        ], width: 0.02, ink: 0.3, dryness: 0.5, pooling: 0.1, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.28, 0.505, pressure: 0.2),
            StrokePoint(0.205, 0.47, pressure: 0.08),
        ], width: 0.02, ink: 0.3, dryness: 0.5, pooling: 0.1, duration: 0.2),
        // The one dark thing: the eye.
        Stroke(points: [
            StrokePoint(0.72, 0.525, pressure: 0.95),
            StrokePoint(0.715, 0.518, pressure: 0.85),
        ], width: 0.022, ink: 1.0, dryness: 0.0, pooling: 0.85, duration: 0.15),
    ])

    /// Cherry trout (산천어): mountain-stream slender-shape with the parr
    /// marks it never outgrows.
    public static let cherryTrout = StrokeRecipe(strokes: [
        // Back.
        Stroke(points: [
            StrokePoint(0.77, 0.53, pressure: 0.4),
            StrokePoint(0.60, 0.60, pressure: 0.85),
            StrokePoint(0.42, 0.595, pressure: 0.8),
            StrokePoint(0.27, 0.53, pressure: 0.35),
        ], width: 0.095, ink: 0.8, dryness: 0.25, pooling: 0.3, duration: 0.8),
        // Belly.
        Stroke(points: [
            StrokePoint(0.72, 0.475, pressure: 0.35),
            StrokePoint(0.52, 0.455, pressure: 0.6),
            StrokePoint(0.34, 0.475, pressure: 0.35),
            StrokePoint(0.28, 0.49, pressure: 0.12),
        ], width: 0.065, ink: 0.42, dryness: 0.35, pooling: 0.2, duration: 0.55),
        // Parr marks — four soft vertical dabs.
        Stroke(points: [
            StrokePoint(0.62, 0.55, pressure: 0.55),
            StrokePoint(0.615, 0.51, pressure: 0.4),
        ], width: 0.045, ink: 0.5, dryness: 0.25, pooling: 0.1, duration: 0.18),
        Stroke(points: [
            StrokePoint(0.53, 0.555, pressure: 0.55),
            StrokePoint(0.525, 0.51, pressure: 0.4),
        ], width: 0.045, ink: 0.48, dryness: 0.25, pooling: 0.1, duration: 0.18),
        Stroke(points: [
            StrokePoint(0.44, 0.545, pressure: 0.5),
            StrokePoint(0.435, 0.505, pressure: 0.38),
        ], width: 0.045, ink: 0.46, dryness: 0.25, pooling: 0.1, duration: 0.18),
        Stroke(points: [
            StrokePoint(0.36, 0.525, pressure: 0.45),
            StrokePoint(0.355, 0.495, pressure: 0.32),
        ], width: 0.04, ink: 0.44, dryness: 0.25, pooling: 0.1, duration: 0.18),
        // Dorsal + the little adipose behind it.
        Stroke(points: [
            StrokePoint(0.52, 0.60, pressure: 0.25),
            StrokePoint(0.47, 0.655, pressure: 0.5),
            StrokePoint(0.42, 0.615, pressure: 0.2),
        ], width: 0.04, ink: 0.6, dryness: 0.45, pooling: 0.2, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.35, 0.585, pressure: 0.3),
            StrokePoint(0.33, 0.605, pressure: 0.1),
        ], width: 0.025, ink: 0.5, dryness: 0.4, pooling: 0.15, duration: 0.15),
        // Forked tail.
        Stroke(points: [
            StrokePoint(0.27, 0.535, pressure: 0.55),
            StrokePoint(0.17, 0.585, pressure: 0.28),
            StrokePoint(0.125, 0.615, pressure: 0.08),
        ], width: 0.055, ink: 0.75, dryness: 0.45, pooling: 0.2, duration: 0.35),
        Stroke(points: [
            StrokePoint(0.27, 0.515, pressure: 0.55),
            StrokePoint(0.175, 0.465, pressure: 0.26),
            StrokePoint(0.13, 0.435, pressure: 0.08),
        ], width: 0.055, ink: 0.75, dryness: 0.5, pooling: 0.2, duration: 0.35),
        // Eye.
        Stroke(points: [
            StrokePoint(0.715, 0.55, pressure: 0.95),
            StrokePoint(0.708, 0.542, pressure: 0.85),
        ], width: 0.024, ink: 1.0, dryness: 0.0, pooling: 0.85, duration: 0.15),
    ])

    /// Pale carp (흰잉어): the fog rarity — a carp mostly made of paper,
    /// trailing long fins; only the eye is certain.
    public static let paleCarp = StrokeRecipe(strokes: [
        // Soft back arch.
        Stroke(points: [
            StrokePoint(0.77, 0.52, pressure: 0.4),
            StrokePoint(0.66, 0.60, pressure: 0.8),
            StrokePoint(0.47, 0.625, pressure: 0.9),
            StrokePoint(0.31, 0.545, pressure: 0.45),
            StrokePoint(0.25, 0.50, pressure: 0.2),
        ], width: 0.11, ink: 0.38, dryness: 0.15, pooling: 0.3, duration: 0.95),
        // Barely-there belly.
        Stroke(points: [
            StrokePoint(0.73, 0.47, pressure: 0.35),
            StrokePoint(0.54, 0.445, pressure: 0.65),
            StrokePoint(0.37, 0.46, pressure: 0.4),
            StrokePoint(0.28, 0.48, pressure: 0.12),
        ], width: 0.08, ink: 0.22, dryness: 0.25, pooling: 0.2, duration: 0.6),
        // Long trailing tail, both lobes.
        Stroke(points: [
            StrokePoint(0.25, 0.51, pressure: 0.5),
            StrokePoint(0.13, 0.58, pressure: 0.3),
            StrokePoint(0.06, 0.645, pressure: 0.06),
        ], width: 0.06, ink: 0.3, dryness: 0.45, pooling: 0.15, duration: 0.45),
        Stroke(points: [
            StrokePoint(0.25, 0.49, pressure: 0.5),
            StrokePoint(0.14, 0.42, pressure: 0.28),
            StrokePoint(0.07, 0.35, pressure: 0.05),
        ], width: 0.06, ink: 0.3, dryness: 0.5, pooling: 0.15, duration: 0.45),
        // Trailing dorsal.
        Stroke(points: [
            StrokePoint(0.55, 0.63, pressure: 0.2),
            StrokePoint(0.46, 0.70, pressure: 0.3),
            StrokePoint(0.37, 0.665, pressure: 0.12),
        ], width: 0.045, ink: 0.28, dryness: 0.5, pooling: 0.15, duration: 0.35),
        // Faint gill.
        Stroke(points: [
            StrokePoint(0.69, 0.575, pressure: 0.3),
            StrokePoint(0.66, 0.51, pressure: 0.5),
            StrokePoint(0.67, 0.465, pressure: 0.2),
        ], width: 0.03, ink: 0.3, dryness: 0.3, pooling: 0.3, duration: 0.3),
        // Barbel.
        Stroke(points: [
            StrokePoint(0.765, 0.485, pressure: 0.2),
            StrokePoint(0.805, 0.445, pressure: 0.06),
        ], width: 0.016, ink: 0.35, dryness: 0.2, pooling: 0.1, duration: 0.2),
        // The certain eye.
        Stroke(points: [
            StrokePoint(0.705, 0.55, pressure: 0.95),
            StrokePoint(0.695, 0.54, pressure: 0.85),
        ], width: 0.028, ink: 0.9, dryness: 0.0, pooling: 0.85, duration: 0.2),
    ])

    /// Ink carp (먹잉어): the storm-night apex and the game's namesake —
    /// maximal wet ink, grand fins, everything pooled.
    public static let inkCarp = StrokeRecipe(strokes: [
        // Soaked back sweep.
        Stroke(points: [
            StrokePoint(0.78, 0.51, pressure: 0.5),
            StrokePoint(0.67, 0.61, pressure: 0.95),
            StrokePoint(0.46, 0.645, pressure: 1.0),
            StrokePoint(0.30, 0.55, pressure: 0.6),
            StrokePoint(0.23, 0.49, pressure: 0.25),
        ], width: 0.14, ink: 1.0, dryness: 0.05, pooling: 0.6, duration: 1.2),
        // Heavy belly mass.
        Stroke(points: [
            StrokePoint(0.74, 0.46, pressure: 0.5),
            StrokePoint(0.54, 0.42, pressure: 0.9),
            StrokePoint(0.36, 0.445, pressure: 0.6),
            StrokePoint(0.27, 0.47, pressure: 0.2),
        ], width: 0.10, ink: 0.8, dryness: 0.1, pooling: 0.5, duration: 0.8),
        // Gill.
        Stroke(points: [
            StrokePoint(0.70, 0.585, pressure: 0.4),
            StrokePoint(0.66, 0.51, pressure: 0.7),
            StrokePoint(0.675, 0.455, pressure: 0.25),
        ], width: 0.038, ink: 0.95, dryness: 0.15, pooling: 0.45, duration: 0.4),
        // The grand tail.
        Stroke(points: [
            StrokePoint(0.23, 0.50, pressure: 0.75),
            StrokePoint(0.11, 0.61, pressure: 0.45),
            StrokePoint(0.045, 0.685, pressure: 0.1),
        ], width: 0.085, ink: 0.95, dryness: 0.3, pooling: 0.4, duration: 0.5),
        Stroke(points: [
            StrokePoint(0.23, 0.48, pressure: 0.75),
            StrokePoint(0.12, 0.39, pressure: 0.4),
            StrokePoint(0.05, 0.31, pressure: 0.08),
        ], width: 0.085, ink: 0.95, dryness: 0.35, pooling: 0.4, duration: 0.5),
        // Large dorsal.
        Stroke(points: [
            StrokePoint(0.56, 0.645, pressure: 0.25),
            StrokePoint(0.465, 0.735, pressure: 0.55),
            StrokePoint(0.375, 0.665, pressure: 0.2),
        ], width: 0.06, ink: 0.9, dryness: 0.35, pooling: 0.3, duration: 0.45),
        // Pectoral trailing deep.
        Stroke(points: [
            StrokePoint(0.655, 0.435, pressure: 0.6),
            StrokePoint(0.59, 0.34, pressure: 0.25),
            StrokePoint(0.55, 0.29, pressure: 0.06),
        ], width: 0.055, ink: 0.85, dryness: 0.35, pooling: 0.25, duration: 0.4),
        // Both barbels.
        Stroke(points: [
            StrokePoint(0.775, 0.475, pressure: 0.3),
            StrokePoint(0.82, 0.43, pressure: 0.07),
        ], width: 0.02, ink: 0.9, dryness: 0.15, pooling: 0.15, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.78, 0.50, pressure: 0.25),
            StrokePoint(0.83, 0.475, pressure: 0.06),
        ], width: 0.018, ink: 0.85, dryness: 0.15, pooling: 0.15, duration: 0.2),
        // The eye, pooled black.
        Stroke(points: [
            StrokePoint(0.715, 0.555, pressure: 1.0),
            StrokePoint(0.703, 0.545, pressure: 0.9),
        ], width: 0.036, ink: 1.0, dryness: 0.0, pooling: 0.9, duration: 0.25),
    ])
}
