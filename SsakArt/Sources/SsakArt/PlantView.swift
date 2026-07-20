import SwiftUI
import SsakCore

public struct PlantView: View {
    let species: Species
    let stage: GrowthStage
    let droop: Double
    let wall: Bool

    /// `wall: true` (default) renders the static cream wall — byte-identical for every
    /// existing caller. Only `WindowsillView` passes `wall: false` and layers `SkyBackdrop`.
    public init(species: Species, stage: GrowthStage, droop: Double = 0, wall: Bool = true) {
        self.species = species; self.stage = stage; self.droop = droop; self.wall = wall
    }

    public var body: some View {
        let palette = SpeciesPalette.palette(for: species.id)
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let soilY = h * 0.66                       // the shared soil line
            let potW = w * 0.54, potH = h * 0.40
            ZStack {
                Sill(wall: wall)
                // Pot placed so its soil surface sits on the soil line.
                Pot()
                    .frame(width: potW, height: potH)
                    .position(x: w * 0.5, y: soilY + potH * (0.5 - Pot.soilFraction))
                // Plant region: top of cell down to the soil line; plants grow
                // from the bottom-center. Droop pivots at that rooted base.
                plant(palette)
                    .frame(width: w, height: soilY * 1.02)
                    .position(x: w * 0.5, y: soilY * 1.02 / 2)
                    .droop(droop)
            }
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
        case ("cosmos", .sprout): CosmosArt.sprout(palette)
        case ("cosmos", .leaves): CosmosArt.leaves(palette)
        case ("cosmos", .bud):    CosmosArt.bud(palette)
        case ("cosmos", .bloom):  CosmosArt.bloom(palette)
        case ("zinnia", .sprout): ZinniaArt.sprout(palette)
        case ("zinnia", .leaves): ZinniaArt.leaves(palette)
        case ("zinnia", .bud):    ZinniaArt.bud(palette)
        case ("zinnia", .bloom):  ZinniaArt.bloom(palette)
        case ("sunflower", .sprout): SunflowerArt.sprout(palette)
        case ("sunflower", .leaves): SunflowerArt.leaves(palette)
        case ("sunflower", .bud):    SunflowerArt.bud(palette)
        case ("sunflower", .bloom):  SunflowerArt.bloom(palette)
        case ("nasturtium", .sprout): NasturtiumArt.sprout(palette)
        case ("nasturtium", .leaves): NasturtiumArt.leaves(palette)
        case ("nasturtium", .bud):    NasturtiumArt.bud(palette)
        case ("nasturtium", .bloom):  NasturtiumArt.bloom(palette)
        case ("morning_glory", .sprout): MorningGloryArt.sprout(palette)
        case ("morning_glory", .leaves): MorningGloryArt.leaves(palette)
        case ("morning_glory", .bud):    MorningGloryArt.bud(palette)
        case ("morning_glory", .bloom):  MorningGloryArt.bloom(palette)
        default:
            Placeholder(text: "\(species.id)/\(stage.rawValue)")   // undrawn species (follow-up plan)
        }
    }
}
