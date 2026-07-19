import SwiftUI
import SsakCore

public struct PlantView: View {
    let species: Species
    let stage: GrowthStage
    let droop: Double

    public init(species: Species, stage: GrowthStage, droop: Double = 0) {
        self.species = species; self.stage = stage; self.droop = droop
    }

    public var body: some View {
        let palette = SpeciesPalette.palette(for: species.id)
        ZStack {
            Sill()
            plant(palette)
                .droop(droop)
            Pot()
                .frame(width: 92, height: 72)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private func plant(_ palette: SpeciesPalette) -> some View {
        switch (species.id, stage) {
        case (_, .seed):
            SeedSoil(tint: palette.seedTint)
        case ("marigold", .sprout): MarigoldArt.sprout(palette)
        case ("marigold", .leaves): MarigoldArt.leaves(palette)
        case ("marigold", .bud):    MarigoldArt.bud(palette)
        case ("marigold", .bloom):  MarigoldArt.bloom(palette)
        default:
            Placeholder(text: "\(species.id)/\(stage.rawValue)")   // undrawn species (follow-up plan)
        }
    }
}
