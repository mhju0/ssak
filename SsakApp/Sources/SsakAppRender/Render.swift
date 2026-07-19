import SwiftUI
import SsakApp
import SsakArt

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
    }
}
