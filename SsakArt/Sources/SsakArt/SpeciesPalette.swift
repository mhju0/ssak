import SwiftUI

public struct SpeciesPalette {
    public let bloom: Color         // primary petal
    public let bloomDeep: Color     // shadowed petal / throat
    public let bloomHighlight: Color// petal tip / catch-light
    public let foliage: Color       // leaf/stem
    public let foliageDeep: Color   // leaf shadow
    public let seedTint: Color      // subtle tint on the shared seed-soil frame
    public let center: Color        // flower disk / eye / throat

    public init(bloom: Color, bloomDeep: Color, bloomHighlight: Color,
                foliage: Color, foliageDeep: Color, seedTint: Color, center: Color) {
        self.bloom = bloom; self.bloomDeep = bloomDeep; self.bloomHighlight = bloomHighlight
        self.foliage = foliage; self.foliageDeep = foliageDeep
        self.seedTint = seedTint; self.center = center
    }

    public static func palette(for speciesID: String) -> SpeciesPalette {
        switch speciesID {
        case "marigold":
            return .init(bloom: Color(red: 0.98, green: 0.60, blue: 0.10),
                         bloomDeep: Color(red: 0.80, green: 0.32, blue: 0.05),
                         bloomHighlight: Color(red: 1.00, green: 0.82, blue: 0.30),
                         foliage: Color(red: 0.30, green: 0.52, blue: 0.28),
                         foliageDeep: Color(red: 0.18, green: 0.36, blue: 0.20),
                         seedTint: Color(red: 0.86, green: 0.55, blue: 0.20),
                         center: Color(red: 0.80, green: 0.32, blue: 0.05))
        case "cosmos":
            return .init(bloom: Color(red: 0.92, green: 0.48, blue: 0.68),
                         bloomDeep: Color(red: 0.78, green: 0.28, blue: 0.52),
                         bloomHighlight: Color(red: 0.99, green: 0.80, blue: 0.88),
                         foliage: Color(red: 0.34, green: 0.55, blue: 0.32),
                         foliageDeep: Color(red: 0.22, green: 0.40, blue: 0.24),
                         seedTint: Color(red: 0.72, green: 0.52, blue: 0.44),
                         center: Color(red: 0.98, green: 0.80, blue: 0.22))
        case "zinnia":
            return .init(bloom: Color(red: 0.88, green: 0.22, blue: 0.32),
                         bloomDeep: Color(red: 0.66, green: 0.12, blue: 0.22),
                         bloomHighlight: Color(red: 0.98, green: 0.52, blue: 0.46),
                         foliage: Color(red: 0.28, green: 0.50, blue: 0.28),
                         foliageDeep: Color(red: 0.17, green: 0.34, blue: 0.19),
                         seedTint: Color(red: 0.74, green: 0.44, blue: 0.36),
                         center: Color(red: 0.98, green: 0.82, blue: 0.28))
        case "sunflower":
            return .init(bloom: Color(red: 0.98, green: 0.76, blue: 0.14),
                         bloomDeep: Color(red: 0.86, green: 0.54, blue: 0.06),
                         bloomHighlight: Color(red: 1.00, green: 0.90, blue: 0.45),
                         foliage: Color(red: 0.30, green: 0.50, blue: 0.24),
                         foliageDeep: Color(red: 0.19, green: 0.35, blue: 0.17),
                         seedTint: Color(red: 0.62, green: 0.46, blue: 0.28),
                         center: Color(red: 0.36, green: 0.22, blue: 0.12))
        case "nasturtium":
            return .init(bloom: Color(red: 0.96, green: 0.46, blue: 0.14),
                         bloomDeep: Color(red: 0.82, green: 0.24, blue: 0.10),
                         bloomHighlight: Color(red: 1.00, green: 0.78, blue: 0.26),
                         foliage: Color(red: 0.32, green: 0.52, blue: 0.40),   // blue-green
                         foliageDeep: Color(red: 0.20, green: 0.38, blue: 0.30),
                         seedTint: Color(red: 0.74, green: 0.50, blue: 0.34),
                         center: Color(red: 0.72, green: 0.16, blue: 0.06))
        case "morning_glory":
            return .init(bloom: Color(red: 0.46, green: 0.42, blue: 0.84),
                         bloomDeep: Color(red: 0.31, green: 0.26, blue: 0.66),
                         bloomHighlight: Color(red: 0.84, green: 0.82, blue: 0.96),
                         foliage: Color(red: 0.28, green: 0.50, blue: 0.30),
                         foliageDeep: Color(red: 0.17, green: 0.35, blue: 0.21),
                         seedTint: Color(red: 0.60, green: 0.56, blue: 0.52),
                         center: Color(red: 0.98, green: 0.98, blue: 0.92))
        default:
            return palette(for: "marigold")
        }
    }
}
