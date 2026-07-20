import SwiftUI
import SsakCore
import SsakArt

/// The clean framed portrait shared from the windowsill (spec §7): the potted
/// bloom, its name (EN + KO), and a day/streak line — no UI chrome.
public struct BloomCard: View {
    let species: Species
    let day: Int
    let streak: Int
    public init(species: Species, day: Int, streak: Int) {
        self.species = species; self.day = day; self.streak = streak
    }
    public var body: some View {
        let accent = SpeciesPalette.palette(for: species.id).bloom
        VStack(spacing: 0) {
            ZStack {
                SpeciesWatermark(species: species, opacity: 0.07)   // faint 싹 (spec §2.5); timeless, no sky
                    .frame(width: 200, height: 200)
                PlantView(species: species, stage: .bloom, wall: false)   // wall:false so the watermark shows
                    .frame(width: 300, height: 340)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 3) {
                Text(species.nameEN)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(red: 0.28, green: 0.22, blue: 0.16))
                Text(species.nameKO)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Day \(day)  ·  \(streak)-day streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(accent)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.99, green: 0.97, blue: 0.92))
        }
        .background(Color(red: 0.99, green: 0.97, blue: 0.92))
    }
}

#if canImport(UIKit)
import UIKit
public extension BloomCard {
    /// Render this card to a UIImage for the iOS share sheet.
    @MainActor func shareImage(scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: self.frame(width: 360, height: 460))
        renderer.scale = scale
        return renderer.uiImage
    }
}
#endif
