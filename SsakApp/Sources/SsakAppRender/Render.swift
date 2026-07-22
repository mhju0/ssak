import SwiftUI
import SsakApp
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

        // Task 3: gauge states + status chrome, on a soft card.
        // Demo fractions → the SoilState the real UI would derive (fraction × moistureMax).
        func soilFor(_ f: Double) -> SoilState { SoilState(moisture: f * GrowthTuning.default.moistureMax) }
        func gaugeCard(_ f: Double, _ label: String) -> some View {
            VStack(spacing: 8) {
                DropGauge(fraction: f, soil: soilFor(f)).frame(width: 70, height: 96)
                Text(label).font(.system(size: 12)).foregroundStyle(.secondary)
            }.padding(16)
        }
        let statusRow = HStack(spacing: 12) {
            gaugeCard(0.10, "dry")
            gaugeCard(0.55, "healthy")
            gaugeCard(0.95, "over-full")
            VStack(spacing: 12) {
                WateredTodayTick().font(.system(size: 28))
                StreakBadge(count: 4, alive: true)
                StreakBadge(count: 2, alive: false)
            }
        }
        .padding(20)
        .background(Color(red: 0.99, green: 0.97, blue: 0.92))
        write(statusRow, CGSize(width: 420, height: 180), "status_chrome.png")

        // Round 2 T3: glass primitives — floating drop, top nav pill, chips (macOS = fallback path).
        let glassCard = VStack(spacing: 16) {
            TopNavPill(tab: .constant(0))
            HStack(spacing: 16) {
                WaterButton(action: {})
                GlassIconButton(systemImage: "square.and.arrow.up", label: "Share", action: {})
                GlassIconButton(systemImage: "square.and.arrow.up", label: "Share your bloom",
                                prominent: true, action: {})
            }
            HStack(spacing: 16) {
                StreakBadge(count: 4, alive: true)
                MoistChip(fraction: 0.08, soil: soilFor(0.08))
                MoistChip(fraction: 0.5, soil: soilFor(0.5))
                MoistChip(fraction: 1.05, soil: soilFor(1.05))
            }
        }
        .padding(24)
        .frame(width: 400, height: 280)
        .ssakGround()
        write(glassCard, CGSize(width: 400, height: 280), "glass_primitives.png")
        write(glassCard.environment(\.colorScheme, .dark), CGSize(width: 400, height: 280),
              "glass_primitives_dark.png")

        // Redesign Plan A Task 2: real-time sky bands (pure now+calendar; UTC cal → reproducible).
        let skySize = CGSize(width: 300, height: 300)
        for (h, band) in [(6, "dawn"), (12, "day"), (18, "dusk"), (22, "night")] {
            let sky = SkyBackdrop(now: Self.day0h(h), calendar: Self.cal)
            write(sky, skySize, "sky_\(band).png")
            write(sky.environment(\.colorScheme, .dark), skySize, "sky_\(band)_dark.png")
        }

        // Round 2 T2: the living room scene — bands × light/dark.
        let roomSize = CGSize(width: 320, height: 640)
        for (h, band) in [(12, "day"), (18, "dusk"), (22, "night")] {
            write(RoomScene(now: Self.day0h(h), calendar: Self.cal), roomSize, "room_\(band).png")
        }
        write(RoomScene(now: Self.day0h(12), calendar: Self.cal).environment(\.colorScheme, .dark),
              roomSize, "room_day_dark.png")

        // Redesign Plan A Task 4: SsakMark variants (rendered here to keep SsakArtRender pristine).
        let cream = Color(red: 0.99, green: 0.97, blue: 0.92)
        let darkbg = Color(red: 0.16, green: 0.14, blue: 0.11)
        func markCell(_ v: SsakMark.Variant, _ bg: Color, _ label: String) -> some View {
            VStack(spacing: 4) {
                SsakMark(v).frame(width: 84, height: 84).padding(8).background(bg)
                Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        let markRow = HStack(spacing: 10) {
            markCell(.light, cream, "light")
            markCell(.dark, darkbg, "dark")
            markCell(.tinted, Color(white: 0.18), "tinted")
            markCell(.mono, cream, "mono")
            markCell(.glass, Color(white: 0.45), "glass")
        }
        .padding(16).background(Color(white: 0.9))
        write(markRow, CGSize(width: 540, height: 130), "ssakmark_variants.png")

        // Redesign Plan A Task 5: species watermark (over a band) + gauge-only status cluster.
        func watermarkCell(_ op: Double, _ label: String) -> some View {
            VStack(spacing: 4) {
                ZStack {
                    SkyBackdrop(now: Self.day0h(12), calendar: Self.cal)
                    SpeciesWatermark(species: SpeciesCatalog.marigold, opacity: op)
                }
                .frame(width: 140, height: 140)
                Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        let watermarkRow = HStack(spacing: 12) {
            watermarkCell(0.06, "0.06 (real)")
            watermarkCell(0.18, "0.18 (shape)")
        }
        .padding(16).background(Color(white: 0.9))
        write(watermarkRow, CGSize(width: 340, height: 180), "watermark_marigold.png")

        // Round 2: windowsill in a few states × bands × light/dark.
        let d0 = Self.day0, d3 = Self.day3
        func windowsill(_ mutate: (inout PlantState) -> Void, now: Date) -> some View {
            var plant = GrowthEngine.plant(SpeciesCatalog.marigold, at: d0)
            mutate(&plant)
            let model = GardenModel(state: GameState(plant: plant, collected: []),
                                    store: PlantStore(url: URL(fileURLWithPath: "/dev/null")), calendar: Self.cal)
            // Composed like RootView: the top nav pill overlays the windowsill.
            return ZStack(alignment: .top) {
                WindowsillView(model: model, now: now, onWater: {}, onShare: {})
                TopNavPill(tab: .constant(0)).padding(.top, 8)
            }
        }
        let phone = CGSize(width: 320, height: 640)
        let bloom: (inout PlantState) -> Void = { $0.progress = 1.0; $0.moisture = 0.7; $0.lastWateredAt = d0 }
        write(windowsill(bloom, now: Self.day0h(12)), phone, "windowsill_bloom_day.png")
        write(windowsill(bloom, now: Self.day0h(22)), phone, "windowsill_bloom_night.png")
        write(windowsill(bloom, now: Self.day0h(12)).environment(\.colorScheme, .dark),
              phone, "windowsill_bloom_dark.png")
        write(windowsill({ $0.progress = 0.6; $0.moisture = 0.05; $0.lastWateredAt = d0 }, now: d3),
              phone, "windowsill_dry.png")
        write(windowsill({ $0.progress = 0.4; $0.moisture = 0.0; $0.isNursing = true; $0.lastWateredAt = d0 }, now: d3),
              phone, "windowsill_nursing.png")
        write(windowsill({ $0.progress = 0.7; $0.moisture = 1.2; $0.lastWateredAt = Self.day0h(8) }, now: Self.day0h(14)),
              phone, "windowsill_overwater.png")
        // Task 10 a11y note: Reduce Transparency (read-only env key), Dynamic Type (ImageRenderer
        // ignores \.dynamicTypeSize), and VoiceOver are all Simulator-verified — not headless-injectable.

        // Task 6: shelf states.
        func shelf(_ collected: [String]) -> some View {
            let plant = GrowthEngine.plant(SpeciesCatalog.marigold, at: d0)
            let model = GardenModel(state: GameState(plant: plant, collected: collected),
                                    store: PlantStore(url: URL(fileURLWithPath: "/dev/null")), calendar: Self.cal)
            return ZStack(alignment: .top) {
                ShelfView(model: model, onReplant: { _ in })
                TopNavPill(tab: .constant(1)).padding(.top, 8)
            }
        }
        write(shelf([]), phone, "shelf_empty.png")
        write(shelf(["marigold", "cosmos", "sunflower"]), phone, "shelf_partial.png")
        write(shelf(SpeciesCatalog.all.map(\.id)), phone, "shelf_complete.png")
        write(shelf(["marigold", "cosmos", "sunflower"]).environment(\.colorScheme, .dark),
              phone, "shelf_partial_dark.png")

        // Round 2 T4: start guide over the live windowsill — welcome sheet + a spotlight step.
        let guideBase = windowsill(bloom, now: Self.day0h(12))
        write(ZStack { guideBase; StartGuide(anchors: [:], speciesName: "Marigold", onDone: {}) },
              phone, "guide_welcome.png")
        let waterRect = CGRect(x: 238, y: 479, width: 62, height: 62)   // where the drop floats at 320×640
        write(ZStack { guideBase
                       StartGuide(anchors: ["water": waterRect], speciesName: "Marigold",
                                  startAt: 1, onDone: {}) },
              phone, "guide_step_water.png")

        // Task 8: shareable bloom card (any species).
        write(BloomCard(species: SpeciesCatalog.morningGlory, day: 13, streak: 5),
              CGSize(width: 360, height: 460), "share_card.png")
    }

    // fixed dates (Date.now is unavailable / non-deterministic for renders)
    static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }()
    static var day0: Date { cal.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 9))! }
    static func day0h(_ h: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: h))! }
    static var day3: Date { cal.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 9))! }
}
