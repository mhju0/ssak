import Foundation

/// The foraging art table — one distinct recipe per forageable, keyed by the
/// kernel's id (docs/design/unlock-tables.md §4). Archetypes: leafy,
/// mushroom-cap, fruit, flower. Darkest accents (gills, calyx, core) paint
/// last — hierarchy by stroke weight, the same readability rule as the fish.
extension Recipes {
    public static let forage: [String: StrokeRecipe] = [
        "mugwort": mugwort,
        "shepherds-purse": shepherdsPurse,
        "oyster-mushroom": oysterMushroom,
        "moon-mushroom": moonMushroom,
        "persimmon": persimmon,
        "pine-nuts": pineNuts,
        "matsutake": matsutake,
        "snow-lotus": snowLotus,
    ]

    // MARK: Leafy herbs

    /// Mugwort (쑥): a low clump of soft lobed leaves fanning from a base.
    public static let mugwort = StrokeRecipe(strokes: [
        // Central stem.
        Stroke(points: [
            StrokePoint(0.50, 0.08, pressure: 0.5),
            StrokePoint(0.50, 0.52, pressure: 0.18),
        ], width: 0.02, ink: 0.5, dryness: 0.3, pooling: 0.15, duration: 0.25),
        // Left leaf, lobed sweep.
        Stroke(points: [
            StrokePoint(0.50, 0.28, pressure: 0.45),
            StrokePoint(0.34, 0.42, pressure: 0.6),
            StrokePoint(0.22, 0.60, pressure: 0.12),
        ], width: 0.055, ink: 0.6, dryness: 0.35, pooling: 0.2, duration: 0.3),
        // Right leaf.
        Stroke(points: [
            StrokePoint(0.50, 0.33, pressure: 0.45),
            StrokePoint(0.67, 0.48, pressure: 0.6),
            StrokePoint(0.77, 0.66, pressure: 0.12),
        ], width: 0.055, ink: 0.57, dryness: 0.35, pooling: 0.2, duration: 0.3),
        // Low left leaf.
        Stroke(points: [
            StrokePoint(0.50, 0.18, pressure: 0.4),
            StrokePoint(0.33, 0.24, pressure: 0.5),
            StrokePoint(0.21, 0.34, pressure: 0.1),
        ], width: 0.045, ink: 0.54, dryness: 0.4, pooling: 0.15, duration: 0.28),
        // Top sprig, tallest.
        Stroke(points: [
            StrokePoint(0.50, 0.50, pressure: 0.4),
            StrokePoint(0.53, 0.70, pressure: 0.4),
            StrokePoint(0.50, 0.86, pressure: 0.1),
        ], width: 0.03, ink: 0.5, dryness: 0.3, pooling: 0.15, duration: 0.28),
    ])

    /// Shepherd's purse (냉이): a low rosette under a tall thin flowering
    /// stalk hung with tiny heart-shaped seedpods (the darkest marks, last).
    public static let shepherdsPurse = StrokeRecipe(strokes: [
        // Rosette leaf, left.
        Stroke(points: [
            StrokePoint(0.50, 0.10, pressure: 0.5),
            StrokePoint(0.34, 0.14, pressure: 0.55),
            StrokePoint(0.23, 0.22, pressure: 0.12),
        ], width: 0.05, ink: 0.55, dryness: 0.4, pooling: 0.15, duration: 0.28),
        // Rosette leaf, right.
        Stroke(points: [
            StrokePoint(0.50, 0.10, pressure: 0.5),
            StrokePoint(0.66, 0.13, pressure: 0.55),
            StrokePoint(0.77, 0.20, pressure: 0.12),
        ], width: 0.05, ink: 0.52, dryness: 0.4, pooling: 0.15, duration: 0.28),
        // Tall flowering stalk.
        Stroke(points: [
            StrokePoint(0.50, 0.13, pressure: 0.5),
            StrokePoint(0.53, 0.5, pressure: 0.35),
            StrokePoint(0.50, 0.82, pressure: 0.12),
        ], width: 0.016, ink: 0.6, dryness: 0.25, pooling: 0.1, duration: 0.3),
        // Seedpods — tiny hearts, dotted last.
        Stroke(points: [
            StrokePoint(0.505, 0.60, pressure: 0.8),
            StrokePoint(0.56, 0.63, pressure: 0.6),
        ], width: 0.03, ink: 0.75, dryness: 0.1, pooling: 0.6, duration: 0.18),
        Stroke(points: [
            StrokePoint(0.515, 0.72, pressure: 0.8),
            StrokePoint(0.45, 0.74, pressure: 0.6),
        ], width: 0.028, ink: 0.72, dryness: 0.1, pooling: 0.6, duration: 0.18),
        Stroke(points: [
            StrokePoint(0.50, 0.82, pressure: 0.7),
            StrokePoint(0.54, 0.85, pressure: 0.5),
        ], width: 0.025, ink: 0.7, dryness: 0.1, pooling: 0.6, duration: 0.16),
    ])

    // MARK: Mushrooms

    /// Oyster mushroom (느타리): overlapping shelf caps on a short cluster
    /// stem — a fan grown on wood.
    public static let oysterMushroom = StrokeRecipe(strokes: [
        // Broad lower shelf cap.
        Stroke(points: [
            StrokePoint(0.26, 0.36, pressure: 0.5),
            StrokePoint(0.50, 0.47, pressure: 0.85),
            StrokePoint(0.73, 0.36, pressure: 0.4),
        ], width: 0.14, ink: 0.55, dryness: 0.3, pooling: 0.3, duration: 0.4),
        // Upper offset cap.
        Stroke(points: [
            StrokePoint(0.40, 0.53, pressure: 0.45),
            StrokePoint(0.56, 0.61, pressure: 0.75),
            StrokePoint(0.69, 0.52, pressure: 0.35),
        ], width: 0.10, ink: 0.5, dryness: 0.35, pooling: 0.25, duration: 0.35),
        // Cluster stems.
        Stroke(points: [
            StrokePoint(0.46, 0.35, pressure: 0.5),
            StrokePoint(0.47, 0.20, pressure: 0.25),
        ], width: 0.04, ink: 0.6, dryness: 0.3, pooling: 0.2, duration: 0.22),
        Stroke(points: [
            StrokePoint(0.55, 0.36, pressure: 0.45),
            StrokePoint(0.58, 0.22, pressure: 0.2),
        ], width: 0.035, ink: 0.55, dryness: 0.3, pooling: 0.2, duration: 0.22),
        // Gill hint under the lower cap — darkest, last.
        Stroke(points: [
            StrokePoint(0.33, 0.34, pressure: 0.4),
            StrokePoint(0.50, 0.40, pressure: 0.5),
            StrokePoint(0.67, 0.34, pressure: 0.4),
        ], width: 0.025, ink: 0.75, dryness: 0.45, pooling: 0.15, duration: 0.25),
    ])

    /// Moon mushroom (달버섯): a single slender-stemmed mushroom with a
    /// domed cap — the night forageable.
    public static let moonMushroom = StrokeRecipe(strokes: [
        // Domed cap.
        Stroke(points: [
            StrokePoint(0.36, 0.60, pressure: 0.45),
            StrokePoint(0.50, 0.73, pressure: 0.9),
            StrokePoint(0.64, 0.60, pressure: 0.45),
        ], width: 0.13, ink: 0.6, dryness: 0.25, pooling: 0.4, duration: 0.4),
        // Slender stem.
        Stroke(points: [
            StrokePoint(0.50, 0.60, pressure: 0.55),
            StrokePoint(0.50, 0.22, pressure: 0.4),
        ], width: 0.05, ink: 0.5, dryness: 0.3, pooling: 0.3, duration: 0.3),
        // Stem base flare.
        Stroke(points: [
            StrokePoint(0.44, 0.22, pressure: 0.4),
            StrokePoint(0.56, 0.22, pressure: 0.4),
        ], width: 0.04, ink: 0.45, dryness: 0.35, pooling: 0.2, duration: 0.2),
        // Cap rim shadow — darkest, last.
        Stroke(points: [
            StrokePoint(0.38, 0.585, pressure: 0.4),
            StrokePoint(0.50, 0.635, pressure: 0.5),
            StrokePoint(0.62, 0.585, pressure: 0.4),
        ], width: 0.024, ink: 0.78, dryness: 0.2, pooling: 0.2, duration: 0.22),
    ])

    /// Matsutake (송이): the prized stout mushroom — a thick stem under a
    /// firm domed cap with a veil ring.
    public static let matsutake = StrokeRecipe(strokes: [
        // Thick stem, left edge.
        Stroke(points: [
            StrokePoint(0.44, 0.15, pressure: 0.7),
            StrokePoint(0.45, 0.44, pressure: 0.85),
            StrokePoint(0.47, 0.60, pressure: 0.5),
        ], width: 0.11, ink: 0.5, dryness: 0.3, pooling: 0.3, duration: 0.4),
        // Stem right edge.
        Stroke(points: [
            StrokePoint(0.56, 0.15, pressure: 0.5),
            StrokePoint(0.55, 0.44, pressure: 0.6),
            StrokePoint(0.53, 0.60, pressure: 0.35),
        ], width: 0.05, ink: 0.45, dryness: 0.35, pooling: 0.25, duration: 0.32),
        // Firm domed cap.
        Stroke(points: [
            StrokePoint(0.34, 0.62, pressure: 0.5),
            StrokePoint(0.50, 0.75, pressure: 0.95),
            StrokePoint(0.66, 0.62, pressure: 0.5),
        ], width: 0.13, ink: 0.64, dryness: 0.25, pooling: 0.4, duration: 0.42),
        // Veil ring — darkest, last.
        Stroke(points: [
            StrokePoint(0.41, 0.585, pressure: 0.45),
            StrokePoint(0.50, 0.60, pressure: 0.55),
            StrokePoint(0.59, 0.585, pressure: 0.45),
        ], width: 0.03, ink: 0.8, dryness: 0.2, pooling: 0.25, duration: 0.24),
    ])

    // MARK: Fruit of the boughs

    /// Persimmon (감): a round autumn fruit crowned by the four-lobed calyx
    /// (the darkest mark, dotted last) on a short stem.
    public static let persimmon = StrokeRecipe(strokes: [
        // Domed upper body.
        Stroke(points: [
            StrokePoint(0.33, 0.46, pressure: 0.5),
            StrokePoint(0.50, 0.30, pressure: 0.9),
            StrokePoint(0.67, 0.46, pressure: 0.5),
        ], width: 0.16, ink: 0.6, dryness: 0.2, pooling: 0.45, duration: 0.45),
        // Rounded lower body.
        Stroke(points: [
            StrokePoint(0.36, 0.44, pressure: 0.5),
            StrokePoint(0.50, 0.56, pressure: 0.85),
            StrokePoint(0.64, 0.44, pressure: 0.5),
        ], width: 0.15, ink: 0.58, dryness: 0.2, pooling: 0.45, duration: 0.42),
        // Soft belly wash so the round body reads solid, not a hollow ring.
        Stroke(points: [
            StrokePoint(0.40, 0.43, pressure: 0.6),
            StrokePoint(0.50, 0.45, pressure: 0.75),
            StrokePoint(0.60, 0.43, pressure: 0.6),
        ], width: 0.13, ink: 0.4, dryness: 0.25, pooling: 0.3, duration: 0.35),
        // Stem.
        Stroke(points: [
            StrokePoint(0.50, 0.55, pressure: 0.4),
            StrokePoint(0.50, 0.64, pressure: 0.2),
        ], width: 0.022, ink: 0.8, dryness: 0.15, pooling: 0.2, duration: 0.2),
        // Four-lobed calyx — darkest, last.
        Stroke(points: [
            StrokePoint(0.40, 0.54, pressure: 0.5),
            StrokePoint(0.50, 0.58, pressure: 0.7),
            StrokePoint(0.60, 0.54, pressure: 0.5),
        ], width: 0.05, ink: 0.85, dryness: 0.2, pooling: 0.3, duration: 0.26),
        Stroke(points: [
            StrokePoint(0.46, 0.60, pressure: 0.5),
            StrokePoint(0.50, 0.54, pressure: 0.6),
            StrokePoint(0.54, 0.60, pressure: 0.5),
        ], width: 0.04, ink: 0.82, dryness: 0.2, pooling: 0.3, duration: 0.24),
    ])

    /// Pine nuts (잣): the pinecone they come in — a scaled ovoid on a short
    /// needle sprig.
    public static let pineNuts = StrokeRecipe(strokes: [
        // Cone upper.
        Stroke(points: [
            StrokePoint(0.40, 0.54, pressure: 0.5),
            StrokePoint(0.50, 0.42, pressure: 0.85),
            StrokePoint(0.60, 0.54, pressure: 0.5),
        ], width: 0.11, ink: 0.55, dryness: 0.3, pooling: 0.3, duration: 0.4),
        // Cone lower.
        Stroke(points: [
            StrokePoint(0.42, 0.52, pressure: 0.5),
            StrokePoint(0.50, 0.66, pressure: 0.8),
            StrokePoint(0.58, 0.52, pressure: 0.5),
        ], width: 0.10, ink: 0.58, dryness: 0.3, pooling: 0.3, duration: 0.38),
        // Needle sprig at the base.
        Stroke(points: [
            StrokePoint(0.50, 0.44, pressure: 0.4),
            StrokePoint(0.62, 0.30, pressure: 0.1),
        ], width: 0.018, ink: 0.5, dryness: 0.4, pooling: 0.1, duration: 0.24),
        Stroke(points: [
            StrokePoint(0.50, 0.44, pressure: 0.4),
            StrokePoint(0.40, 0.28, pressure: 0.1),
        ], width: 0.018, ink: 0.48, dryness: 0.4, pooling: 0.1, duration: 0.24),
        // Scale ridges — darkest, last.
        Stroke(points: [
            StrokePoint(0.43, 0.50, pressure: 0.4),
            StrokePoint(0.57, 0.50, pressure: 0.4),
        ], width: 0.02, ink: 0.75, dryness: 0.35, pooling: 0.15, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.44, 0.57, pressure: 0.4),
            StrokePoint(0.56, 0.57, pressure: 0.4),
        ], width: 0.02, ink: 0.72, dryness: 0.35, pooling: 0.15, duration: 0.2),
    ])

    // MARK: The apex bloom

    /// Snow lotus (설련화): a radial rosette of pointed bracts around a soft
    /// woolly core — blooms only in falling snow.
    public static let snowLotus = StrokeRecipe(strokes: [
        // Petals radiating out (painted before the core so it sits on top).
        Stroke(points: [
            StrokePoint(0.50, 0.45, pressure: 0.5),
            StrokePoint(0.50, 0.73, pressure: 0.1),
        ], width: 0.05, ink: 0.55, dryness: 0.35, pooling: 0.15, duration: 0.24),
        Stroke(points: [
            StrokePoint(0.50, 0.45, pressure: 0.5),
            StrokePoint(0.33, 0.63, pressure: 0.1),
        ], width: 0.05, ink: 0.52, dryness: 0.35, pooling: 0.15, duration: 0.24),
        Stroke(points: [
            StrokePoint(0.50, 0.45, pressure: 0.5),
            StrokePoint(0.67, 0.63, pressure: 0.1),
        ], width: 0.05, ink: 0.52, dryness: 0.35, pooling: 0.15, duration: 0.24),
        Stroke(points: [
            StrokePoint(0.48, 0.43, pressure: 0.5),
            StrokePoint(0.25, 0.45, pressure: 0.1),
        ], width: 0.045, ink: 0.5, dryness: 0.35, pooling: 0.15, duration: 0.24),
        Stroke(points: [
            StrokePoint(0.52, 0.43, pressure: 0.5),
            StrokePoint(0.75, 0.45, pressure: 0.1),
        ], width: 0.045, ink: 0.5, dryness: 0.35, pooling: 0.15, duration: 0.24),
        Stroke(points: [
            StrokePoint(0.48, 0.41, pressure: 0.5),
            StrokePoint(0.36, 0.24, pressure: 0.1),
        ], width: 0.045, ink: 0.48, dryness: 0.35, pooling: 0.15, duration: 0.24),
        Stroke(points: [
            StrokePoint(0.52, 0.41, pressure: 0.5),
            StrokePoint(0.64, 0.24, pressure: 0.1),
        ], width: 0.045, ink: 0.48, dryness: 0.35, pooling: 0.15, duration: 0.24),
        // Woolly core — soft and pooled, last.
        Stroke(points: [
            StrokePoint(0.47, 0.43, pressure: 0.8),
            StrokePoint(0.53, 0.47, pressure: 0.8),
        ], width: 0.09, ink: 0.5, dryness: 0.5, pooling: 0.7, duration: 0.28),
    ])
}
