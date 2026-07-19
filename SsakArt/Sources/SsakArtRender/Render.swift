import SwiftUI
import SsakArt
import SsakCore

@main
struct Render {
    @MainActor static func main() {
        let out = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("rendered", isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let placeholder = ZStack {
            Color(red: 0.98, green: 0.95, blue: 0.88)
            Circle().fill(.orange).frame(width: 80, height: 80)
        }
        if let data = pngData(for: placeholder, size: CGSize(width: 120, height: 140)) {
            try? data.write(to: out.appendingPathComponent("_loop_check.png"))
            print("wrote \(out.appendingPathComponent("_loop_check.png").path)")
        } else {
            print("RENDER FAILED"); exit(1)
        }

        let backdrop = ZStack {
            Sill()
            Pot().frame(width: 90, height: 70).offset(y: 40)
        }
        if let data = pngData(for: backdrop, size: CGSize(width: 160, height: 200)) {
            try? data.write(to: out.appendingPathComponent("_backdrop.png"))
            print("wrote \(out.appendingPathComponent("_backdrop.png").path)")
        } else {
            print("RENDER FAILED"); exit(1)
        }

        let seedMarigold = ZStack {
            Sill()
            Pot().frame(width: 90, height: 70).offset(y: 40)
            SeedSoil(tint: SpeciesPalette.palette(for: "marigold").seedTint)
                .frame(width: 90, height: 70)
                .offset(y: 40)
        }
        if let data = pngData(for: seedMarigold, size: CGSize(width: 140, height: 180)) {
            try? data.write(to: out.appendingPathComponent("_seed_marigold.png"))
            print("wrote \(out.appendingPathComponent("_seed_marigold.png").path)")
        } else {
            print("RENDER FAILED"); exit(1)
        }

        let cellSize = CGSize(width: 180, height: 220)
        let marigoldRow = HStack(spacing: 0) {
            ForEach(GrowthStage.allCases, id: \.self) { stage in
                PlantView(species: SpeciesCatalog.marigold, stage: stage, droop: 0)
                    .frame(width: cellSize.width, height: cellSize.height)
            }
        }
        let rowSize = CGSize(width: cellSize.width * CGFloat(GrowthStage.allCases.count), height: cellSize.height)
        if let data = pngData(for: marigoldRow, size: rowSize) {
            try? data.write(to: out.appendingPathComponent("marigold_row.png"))
            print("wrote \(out.appendingPathComponent("marigold_row.png").path)")
        } else {
            print("RENDER FAILED"); exit(1)
        }

        for stage in GrowthStage.allCases {
            let view = PlantView(species: SpeciesCatalog.marigold, stage: stage, droop: 0)
            let name = "marigold_\(stage.rawValue).png"
            if let data = pngData(for: view, size: cellSize) {
                try? data.write(to: out.appendingPathComponent(name))
                print("wrote \(out.appendingPathComponent(name).path)")
            } else {
                print("RENDER FAILED"); exit(1)
            }
        }

        let bloomDroop = PlantView(species: SpeciesCatalog.marigold, stage: .bloom, droop: 0.8)
        if let data = pngData(for: bloomDroop, size: cellSize) {
            try? data.write(to: out.appendingPathComponent("marigold_bloom_droop.png"))
            print("wrote \(out.appendingPathComponent("marigold_bloom_droop.png").path)")
        } else {
            print("RENDER FAILED"); exit(1)
        }
    }
}
