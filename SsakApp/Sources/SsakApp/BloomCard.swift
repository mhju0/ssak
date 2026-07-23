import SwiftUI
import SsakCore
import SsakArt

/// The shared portrait (round 3): a hanji specimen card — the potted plant at its
/// current stage over paper, KO-first name, a day/streak line, and a small dojang
/// seal carrying the streak. No UI chrome; always the light album paper (a share
/// image is a keepsake, not a screen).
public struct BloomCard: View {
    let species: Species
    let stage: GrowthStage
    let day: Int
    let streak: Int
    public init(species: Species, stage: GrowthStage, day: Int, streak: Int) {
        self.species = species; self.stage = stage; self.day = day; self.streak = streak
        SsakFonts.register()
    }

    private let paper = Color(red: 0.961, green: 0.933, blue: 0.871)   // day-band hanji
    private let ink = Color(red: 0.278, green: 0.220, blue: 0.157)

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                SpeciesWatermark(species: species, opacity: 0.07)   // faint 싹 (spec §2.5); timeless, no sky
                    .frame(width: 200, height: 200)
                PlantView(species: species, stage: stage, wall: false)   // wall:false so the watermark shows
                    .frame(width: 300, height: 340)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                SealBadge(count: streak, alive: true)
                    .environment(\.colorScheme, .light)
                    .scaleEffect(0.8)
                    .padding(.top, 18)
                    .padding(.trailing, 10)
            }
            VStack(spacing: 4) {
                Text(species.nameKO)
                    .font(.myeongjoDisplay(28, relativeTo: .title))
                    .tracking(3)
                    .foregroundStyle(ink)
                Text(species.nameEN.uppercased())
                    .font(.system(size: 11, weight: .medium)).tracking(4)
                    .foregroundStyle(ink.opacity(0.55))
                Text("함께한 지 \(day)일 · \(streak)일 연속")
                    .font(.myeongjo(12, relativeTo: .footnote)).tracking(1)
                    .foregroundStyle(SealRed.color(.light))
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(LinearGradient(colors: [paper, Color(red: 0.922, green: 0.878, blue: 0.784)],
                                   startPoint: .top, endPoint: .bottom))
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
