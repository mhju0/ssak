import SwiftUI
import SsakCore
import SsakArt

/// A faint, species-tinted ghost of the 싹 mark behind the hero plant (spec §2.2, §3.2).
/// Decorative — hidden from VoiceOver. Uses the shared `SsakMarkPath` silhouette, tinted with
/// the species' foliage color so it echoes the plant without competing with it.
public struct SpeciesWatermark: View {
    let species: Species
    let opacity: Double
    public init(species: Species, opacity: Double = 0.06) {
        self.species = species; self.opacity = opacity
    }
    public var body: some View {
        SsakMarkPath()
            .fill(SpeciesPalette.palette(for: species.id).foliage)
            .opacity(opacity)
            .accessibilityHidden(true)
    }
}
