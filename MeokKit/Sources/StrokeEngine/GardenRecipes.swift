import Foundation

/// The gardening art table — one recipe per plantable (docs/design/unlock-
/// tables.md §4), keyed by the kernel's id. Growth stages don't multiply the
/// table: earlier stages render `gardenSeedling` (shared) or this recipe at a
/// smaller scale, so 6 plantables stay 6 recipes (pine reuses the M1 prop).
extension Recipes {
    public static let garden: [String: StrokeRecipe] = [
        "radish": radish,
        "cabbage": cabbage,
        "plum-tree": plumTree,
        "pine-tree": pine,
        "persimmon-tree": persimmonTree,
        "old-ginkgo": ginkgo,
    ]

    /// A generic seedling — the seed/sprout stage for any plantable, drawn
    /// small. Shared so growth never adds art (spec §3 budget).
    public static let gardenSeedling = StrokeRecipe(strokes: [
        // Soil mound.
        Stroke(points: [
            StrokePoint(0.35, 0.15, pressure: 0.4),
            StrokePoint(0.50, 0.20, pressure: 0.55),
            StrokePoint(0.65, 0.15, pressure: 0.4),
        ], width: 0.06, ink: 0.35, dryness: 0.4, pooling: 0.2, duration: 0.25),
        // Shoot.
        Stroke(points: [
            StrokePoint(0.50, 0.18, pressure: 0.5),
            StrokePoint(0.50, 0.44, pressure: 0.2),
        ], width: 0.02, ink: 0.55, dryness: 0.25, pooling: 0.1, duration: 0.2),
        // Two first leaves.
        Stroke(points: [
            StrokePoint(0.50, 0.34, pressure: 0.35),
            StrokePoint(0.37, 0.44, pressure: 0.1),
        ], width: 0.03, ink: 0.5, dryness: 0.3, pooling: 0.15, duration: 0.18),
        Stroke(points: [
            StrokePoint(0.50, 0.34, pressure: 0.35),
            StrokePoint(0.63, 0.44, pressure: 0.1),
        ], width: 0.03, ink: 0.5, dryness: 0.3, pooling: 0.15, duration: 0.18),
    ])

    // MARK: Crops

    /// Radish (무): a rounded root below, leafy tops above.
    public static let radish = StrokeRecipe(strokes: [
        // Root bulb (two arcs meeting as an oval).
        Stroke(points: [
            StrokePoint(0.36, 0.34, pressure: 0.5),
            StrokePoint(0.50, 0.46, pressure: 0.9),
            StrokePoint(0.64, 0.34, pressure: 0.5),
        ], width: 0.14, ink: 0.5, dryness: 0.2, pooling: 0.45, duration: 0.4),
        Stroke(points: [
            StrokePoint(0.38, 0.32, pressure: 0.5),
            StrokePoint(0.50, 0.22, pressure: 0.8),
            StrokePoint(0.62, 0.32, pressure: 0.5),
        ], width: 0.12, ink: 0.45, dryness: 0.2, pooling: 0.45, duration: 0.4),
        // Soft belly so the bulb reads solid, not a hollow ring.
        Stroke(points: [
            StrokePoint(0.42, 0.34, pressure: 0.6),
            StrokePoint(0.50, 0.35, pressure: 0.75),
            StrokePoint(0.58, 0.34, pressure: 0.6),
        ], width: 0.12, ink: 0.32, dryness: 0.25, pooling: 0.3, duration: 0.35),
        // Taproot tail.
        Stroke(points: [
            StrokePoint(0.50, 0.22, pressure: 0.4),
            StrokePoint(0.50, 0.09, pressure: 0.08),
        ], width: 0.02, ink: 0.55, dryness: 0.4, pooling: 0.1, duration: 0.2),
        // Leaf blades fanning up.
        Stroke(points: [
            StrokePoint(0.50, 0.46, pressure: 0.4),
            StrokePoint(0.40, 0.66, pressure: 0.5),
            StrokePoint(0.36, 0.82, pressure: 0.12),
        ], width: 0.05, ink: 0.6, dryness: 0.3, pooling: 0.2, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.50, 0.46, pressure: 0.4),
            StrokePoint(0.56, 0.68, pressure: 0.5),
            StrokePoint(0.60, 0.84, pressure: 0.12),
        ], width: 0.05, ink: 0.58, dryness: 0.3, pooling: 0.2, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.50, 0.46, pressure: 0.4),
            StrokePoint(0.50, 0.70, pressure: 0.4),
            StrokePoint(0.48, 0.86, pressure: 0.1),
        ], width: 0.045, ink: 0.55, dryness: 0.3, pooling: 0.2, duration: 0.3),
    ])

    /// Napa cabbage (배추): an upright oblong bundle of ribbed leaves.
    public static let cabbage = StrokeRecipe(strokes: [
        // Left outer leaf.
        Stroke(points: [
            StrokePoint(0.42, 0.12, pressure: 0.5),
            StrokePoint(0.34, 0.45, pressure: 0.7),
            StrokePoint(0.44, 0.78, pressure: 0.3),
        ], width: 0.10, ink: 0.5, dryness: 0.25, pooling: 0.3, duration: 0.4),
        // Right outer leaf.
        Stroke(points: [
            StrokePoint(0.58, 0.12, pressure: 0.5),
            StrokePoint(0.66, 0.45, pressure: 0.7),
            StrokePoint(0.56, 0.78, pressure: 0.3),
        ], width: 0.10, ink: 0.48, dryness: 0.25, pooling: 0.3, duration: 0.4),
        // Central rib — darker, last.
        Stroke(points: [
            StrokePoint(0.50, 0.14, pressure: 0.5),
            StrokePoint(0.50, 0.74, pressure: 0.3),
        ], width: 0.035, ink: 0.7, dryness: 0.15, pooling: 0.25, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.45, 0.16, pressure: 0.4),
            StrokePoint(0.46, 0.68, pressure: 0.25),
        ], width: 0.025, ink: 0.6, dryness: 0.2, pooling: 0.2, duration: 0.28),
        Stroke(points: [
            StrokePoint(0.55, 0.16, pressure: 0.4),
            StrokePoint(0.54, 0.68, pressure: 0.25),
        ], width: 0.025, ink: 0.6, dryness: 0.2, pooling: 0.2, duration: 0.28),
    ])

    // MARK: Trees (the forest the player grows)

    /// Plum tree (매화나무): a gnarled trunk and branches dotted with blossoms
    /// (the pooled dots, last).
    public static let plumTree = StrokeRecipe(strokes: [
        // Trunk.
        Stroke(points: [
            StrokePoint(0.48, 0.05, pressure: 0.7),
            StrokePoint(0.50, 0.38, pressure: 0.5),
            StrokePoint(0.46, 0.58, pressure: 0.3),
        ], width: 0.06, ink: 0.8, dryness: 0.3, pooling: 0.25, duration: 0.4),
        // Left branch.
        Stroke(points: [
            StrokePoint(0.49, 0.44, pressure: 0.4),
            StrokePoint(0.32, 0.58, pressure: 0.3),
            StrokePoint(0.24, 0.72, pressure: 0.12),
        ], width: 0.03, ink: 0.72, dryness: 0.4, pooling: 0.15, duration: 0.3),
        // Right branch.
        Stroke(points: [
            StrokePoint(0.50, 0.50, pressure: 0.4),
            StrokePoint(0.66, 0.62, pressure: 0.3),
            StrokePoint(0.76, 0.74, pressure: 0.12),
        ], width: 0.03, ink: 0.72, dryness: 0.4, pooling: 0.15, duration: 0.3),
        // Crown branch.
        Stroke(points: [
            StrokePoint(0.48, 0.55, pressure: 0.4),
            StrokePoint(0.52, 0.76, pressure: 0.2),
            StrokePoint(0.56, 0.88, pressure: 0.08),
        ], width: 0.025, ink: 0.7, dryness: 0.4, pooling: 0.15, duration: 0.3),
        // Blossoms — soft pooled dots at the tips, last.
        Stroke(points: [
            StrokePoint(0.23, 0.73, pressure: 0.7),
            StrokePoint(0.27, 0.75, pressure: 0.6),
        ], width: 0.05, ink: 0.55, dryness: 0.1, pooling: 0.7, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.77, 0.75, pressure: 0.7),
            StrokePoint(0.73, 0.77, pressure: 0.6),
        ], width: 0.05, ink: 0.55, dryness: 0.1, pooling: 0.7, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.57, 0.89, pressure: 0.6),
            StrokePoint(0.53, 0.87, pressure: 0.6),
        ], width: 0.045, ink: 0.52, dryness: 0.1, pooling: 0.7, duration: 0.2),
    ])

    /// Persimmon tree (감나무): trunk, a rounded canopy wash, and hanging
    /// fruit (the dark dots, last).
    public static let persimmonTree = StrokeRecipe(strokes: [
        // Trunk.
        Stroke(points: [
            StrokePoint(0.48, 0.05, pressure: 0.7),
            StrokePoint(0.50, 0.42, pressure: 0.45),
        ], width: 0.06, ink: 0.8, dryness: 0.3, pooling: 0.25, duration: 0.35),
        // Canopy wash, broad.
        Stroke(points: [
            StrokePoint(0.28, 0.60, pressure: 0.6),
            StrokePoint(0.50, 0.70, pressure: 1.0),
            StrokePoint(0.72, 0.60, pressure: 0.6),
        ], width: 0.22, ink: 0.34, dryness: 0.35, pooling: 0.3, duration: 0.45),
        // Canopy crown.
        Stroke(points: [
            StrokePoint(0.35, 0.68, pressure: 0.55),
            StrokePoint(0.50, 0.82, pressure: 0.85),
            StrokePoint(0.65, 0.68, pressure: 0.55),
        ], width: 0.18, ink: 0.32, dryness: 0.4, pooling: 0.25, duration: 0.4),
        // Branches into the canopy.
        Stroke(points: [
            StrokePoint(0.50, 0.42, pressure: 0.35),
            StrokePoint(0.40, 0.58, pressure: 0.15),
        ], width: 0.025, ink: 0.7, dryness: 0.35, pooling: 0.15, duration: 0.25),
        // Fruit — dark round dots hanging, last.
        Stroke(points: [
            StrokePoint(0.40, 0.56, pressure: 0.7),
            StrokePoint(0.42, 0.54, pressure: 0.6),
        ], width: 0.05, ink: 0.82, dryness: 0.1, pooling: 0.5, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.58, 0.58, pressure: 0.7),
            StrokePoint(0.56, 0.56, pressure: 0.6),
        ], width: 0.05, ink: 0.8, dryness: 0.1, pooling: 0.5, duration: 0.2),
        Stroke(points: [
            StrokePoint(0.50, 0.52, pressure: 0.7),
            StrokePoint(0.52, 0.50, pressure: 0.6),
        ], width: 0.045, ink: 0.82, dryness: 0.1, pooling: 0.5, duration: 0.2),
    ])

    /// Old ginkgo (은행나무): the centerpiece — a thick trunk under a broad
    /// spreading canopy.
    public static let ginkgo = StrokeRecipe(strokes: [
        // Thick trunk.
        Stroke(points: [
            StrokePoint(0.46, 0.05, pressure: 0.85),
            StrokePoint(0.50, 0.32, pressure: 0.7),
            StrokePoint(0.50, 0.48, pressure: 0.45),
        ], width: 0.09, ink: 0.82, dryness: 0.25, pooling: 0.3, duration: 0.45),
        // Spreading branches.
        Stroke(points: [
            StrokePoint(0.50, 0.44, pressure: 0.45),
            StrokePoint(0.32, 0.58, pressure: 0.2),
        ], width: 0.035, ink: 0.72, dryness: 0.35, pooling: 0.2, duration: 0.3),
        Stroke(points: [
            StrokePoint(0.50, 0.46, pressure: 0.45),
            StrokePoint(0.68, 0.60, pressure: 0.2),
        ], width: 0.035, ink: 0.72, dryness: 0.35, pooling: 0.2, duration: 0.3),
        // Broad canopy, fan-wide.
        Stroke(points: [
            StrokePoint(0.20, 0.62, pressure: 0.6),
            StrokePoint(0.50, 0.76, pressure: 1.0),
            StrokePoint(0.80, 0.62, pressure: 0.6),
        ], width: 0.26, ink: 0.4, dryness: 0.3, pooling: 0.3, duration: 0.5),
        // Canopy crown.
        Stroke(points: [
            StrokePoint(0.30, 0.74, pressure: 0.55),
            StrokePoint(0.50, 0.90, pressure: 0.9),
            StrokePoint(0.70, 0.74, pressure: 0.55),
        ], width: 0.20, ink: 0.37, dryness: 0.35, pooling: 0.25, duration: 0.45),
    ])
}
