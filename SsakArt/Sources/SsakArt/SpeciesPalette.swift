import SwiftUI

public struct SpeciesPalette {
    public let bloom: Color         // primary petal
    public let bloomDeep: Color     // shadowed petal / throat
    public let bloomHighlight: Color// petal tip / catch-light
    public let foliage: Color       // leaf/stem
    public let foliageDeep: Color   // leaf shadow
    public let seedTint: Color      // subtle tint on the shared seed-soil frame

    public static func palette(for speciesID: String) -> SpeciesPalette {
        switch speciesID {
        case "marigold":
            return .init(bloom: Color(red: 0.98, green: 0.60, blue: 0.10),
                         bloomDeep: Color(red: 0.80, green: 0.32, blue: 0.05),
                         bloomHighlight: Color(red: 1.00, green: 0.82, blue: 0.30),
                         foliage: Color(red: 0.30, green: 0.52, blue: 0.28),
                         foliageDeep: Color(red: 0.18, green: 0.36, blue: 0.20),
                         seedTint: Color(red: 0.86, green: 0.55, blue: 0.20))
        // Provisional until the remaining-species follow-up tunes each against its render.
        case "nasturtium":    return marigoldLike(hueBloom: Color(red: 0.96, green: 0.44, blue: 0.12))
        case "cosmos":        return marigoldLike(hueBloom: Color(red: 0.90, green: 0.45, blue: 0.66))
        case "zinnia":        return marigoldLike(hueBloom: Color(red: 0.86, green: 0.20, blue: 0.30))
        case "sunflower":     return marigoldLike(hueBloom: Color(red: 0.98, green: 0.78, blue: 0.12))
        case "morning_glory": return marigoldLike(hueBloom: Color(red: 0.42, green: 0.40, blue: 0.82))
        default:              return marigoldLike(hueBloom: Color(red: 0.98, green: 0.60, blue: 0.10))
        }
    }

    private static func marigoldLike(hueBloom: Color) -> SpeciesPalette {
        .init(bloom: hueBloom,
              bloomDeep: hueBloom.opacity(0.75),
              bloomHighlight: hueBloom.opacity(0.55),
              foliage: Color(red: 0.30, green: 0.52, blue: 0.28),
              foliageDeep: Color(red: 0.18, green: 0.36, blue: 0.20),
              seedTint: Color(red: 0.80, green: 0.62, blue: 0.34))
    }
}
