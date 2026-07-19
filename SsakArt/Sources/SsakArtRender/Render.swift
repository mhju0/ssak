import SwiftUI
import SsakArt
import SsakCore

@main
struct Render {
    @MainActor static func main() {
        let out = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("rendered", isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        func write(_ view: some View, _ size: CGSize, _ name: String) {
            guard let data = pngData(for: view, size: size) else { print("RENDER FAILED: \(name)"); exit(1) }
            try? data.write(to: out.appendingPathComponent(name))
            print("wrote \(name)")
        }

        let marigold = SpeciesCatalog.marigold
        let cell = CGSize(width: 180, height: 220)

        // Species with authored art so far (extended as each lands).
        let implemented = [SpeciesCatalog.marigold, SpeciesCatalog.cosmos, SpeciesCatalog.zinnia,
                           SpeciesCatalog.sunflower, SpeciesCatalog.nasturtium]

        for species in implemented {
            let row = HStack(spacing: 0) {
                ForEach(GrowthStage.allCases, id: \.self) { stage in
                    PlantView(species: species, stage: stage, droop: 0)
                        .frame(width: cell.width, height: cell.height)
                }
            }
            write(row, CGSize(width: cell.width * CGFloat(GrowthStage.allCases.count), height: cell.height),
                  "\(species.id)_row.png")
            for stage in GrowthStage.allCases {
                write(PlantView(species: species, stage: stage), cell, "\(species.id)_\(stage.rawValue).png")
            }
        }
        write(PlantView(species: marigold, stage: .bloom, droop: 0.8), cell, "marigold_bloom_droop.png")

        // Shareable portrait card (spec §7): the bloom, its name (EN + KO), a date/
        // streak line, no UI chrome. Preview of the ImageRenderer export the app ships.
        write(PortraitCard(species: marigold, day: 7, streak: 3),
              CGSize(width: 360, height: 460), "marigold_bloom_portrait.png")
    }
}

/// A clean framed portrait of a bloom — the share card the app will export.
struct PortraitCard: View {
    let species: Species
    let day: Int
    let streak: Int
    var body: some View {
        let accent = SpeciesPalette.palette(for: species.id).bloom
        VStack(spacing: 0) {
            PlantView(species: species, stage: .bloom)
                .frame(width: 300, height: 340)
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
