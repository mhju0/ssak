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

        write(RootPlaceholder(), CGSize(width: 200, height: 260), "_app_loop_check.png")

        // Task 3: gauge states + status chrome, on a soft card.
        let band = 0.154...0.77   // dryThreshold/moistureMax … tooWetThreshold/moistureMax
        func gaugeCard(_ f: Double, _ label: String) -> some View {
            VStack(spacing: 8) {
                DropGauge(fraction: f, band: band).frame(width: 70, height: 96)
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

        // Redesign Plan A Task 1: glass primitives + adaptive ink/ground (macOS = fallback path).
        let glassCard = VStack(spacing: 16) {
            Text("Water controls").font(.system(size: 13, weight: .medium)).inkText()
            WaterButton(isOverfull: false, action: {})
            WaterButton(isOverfull: true, action: {})
            HStack(spacing: 16) {
                GlassIconButton(systemImage: "square.and.arrow.up", label: "Share", action: {})
                GlassIconButton(systemImage: "square.and.arrow.up", label: "Share your bloom",
                                prominent: true, action: {})
            }
        }
        .padding(24)
        .frame(width: 320, height: 260)
        .ssakGround()
        write(glassCard, CGSize(width: 320, height: 260), "glass_primitives.png")
        write(glassCard.environment(\.colorScheme, .dark), CGSize(width: 320, height: 260),
              "glass_primitives_dark.png")

        // Redesign Plan A Task 2: real-time sky bands (pure now+calendar; UTC cal → reproducible).
        let skySize = CGSize(width: 300, height: 300)
        for (h, band) in [(6, "dawn"), (12, "day"), (18, "dusk"), (22, "night")] {
            let sky = SkyBackdrop(now: Self.day0h(h), calendar: Self.cal)
            write(sky, skySize, "sky_\(band).png")
            write(sky.environment(\.colorScheme, .dark), skySize, "sky_\(band)_dark.png")
        }

        // Task 4: windowsill in a few states.
        let d0 = Self.day0, d3 = Self.day3
        func windowsill(_ mutate: (inout PlantState) -> Void, now: Date) -> some View {
            var plant = GrowthEngine.plant(SpeciesCatalog.marigold, at: d0)
            mutate(&plant)
            let model = GardenModel(state: GameState(plant: plant, collected: []),
                                    store: PlantStore(url: URL(fileURLWithPath: "/dev/null")), calendar: Self.cal)
            return WindowsillView(model: model, now: now, onWater: {}, onShare: {})
        }
        let phone = CGSize(width: 300, height: 560)
        write(windowsill({ $0.progress = 1.0; $0.moisture = 0.7; $0.lastWateredAt = d0 }, now: Self.day0h(12)),
              phone, "windowsill_bloom.png")
        write(windowsill({ $0.progress = 0.6; $0.moisture = 0.05; $0.lastWateredAt = d0 }, now: d3),
              phone, "windowsill_dry.png")
        write(windowsill({ $0.progress = 0.4; $0.moisture = 0.0; $0.isNursing = true; $0.lastWateredAt = d0 }, now: d3),
              phone, "windowsill_nursing.png")
        write(windowsill({ $0.progress = 0.7; $0.moisture = 1.2; $0.lastWateredAt = Self.day0h(8) }, now: Self.day0h(14)),
              phone, "windowsill_overwater_warn.png")

        // Task 6: shelf states.
        func shelf(_ collected: [String]) -> some View {
            let plant = GrowthEngine.plant(SpeciesCatalog.marigold, at: d0)
            let model = GardenModel(state: GameState(plant: plant, collected: collected),
                                    store: PlantStore(url: URL(fileURLWithPath: "/dev/null")), calendar: Self.cal)
            return ShelfView(model: model, onReplant: { _ in })
        }
        write(shelf([]), phone, "shelf_empty.png")
        write(shelf(["marigold", "cosmos", "sunflower"]), phone, "shelf_partial.png")
        write(shelf(SpeciesCatalog.all.map(\.id)), phone, "shelf_complete.png")

        // Task 7: onboarding.
        write(OnboardingView(onDone: {}), phone, "onboarding.png")

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
