import GameKernel
import SpriteKit
import StrokeEngine

/// Hand-composed dressing per zone — composition is data (recipe + position
/// + scale), not node soup. Positions are fractions: x across the screen,
/// y within the zone. Scale is a fraction of screen width.
enum ZoneDressing {
    struct Prop {
        let recipe: StrokeRecipe
        let x: CGFloat
        let y: CGFloat
        let scale: CGFloat
    }

    static func props(for zone: Zone) -> [Prop] {
        switch zone {
        case .peak:
            // The mountain composition dominates; a wind-bent pine and a
            // rock mark the trailhead.
            [
                Prop(recipe: Recipes.pine, x: 0.76, y: 0.10, scale: 0.22),
                Prop(recipe: Recipes.rock, x: 0.10, y: 0.08, scale: 0.17),
            ]
        case .forest:
            [
                Prop(recipe: Recipes.pine, x: 0.20, y: 0.42, scale: 0.30),
                Prop(recipe: Recipes.pine, x: 0.56, y: 0.18, scale: 0.26),
                Prop(recipe: Recipes.pine, x: 0.76, y: 0.55, scale: 0.21),
                Prop(recipe: Recipes.rock, x: 0.40, y: 0.06, scale: 0.16),
            ]
        case .hermitage:
            [
                Prop(recipe: Recipes.hut, x: 0.22, y: 0.38, scale: 0.34),
                Prop(recipe: Recipes.pine, x: 0.72, y: 0.52, scale: 0.22),
                Prop(recipe: Recipes.rock, x: 0.06, y: 0.22, scale: 0.14),
            ]
        case .gardenTerrace:
            [
                Prop(recipe: Recipes.gardenBeds, x: 0.22, y: 0.30, scale: 0.56),
                Prop(recipe: Recipes.rock, x: 0.82, y: 0.58, scale: 0.15),
            ]
        case .valleyPond:
            // Bank starts to the carp's right so the sweep doesn't cut
            // through the fish.
            [
                Prop(recipe: Recipes.pondBank, x: 0.44, y: 0.12, scale: 0.52),
                Prop(recipe: Recipes.rock, x: 0.86, y: 0.24, scale: 0.14),
            ]
        }
    }
}
