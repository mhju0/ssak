import SkyState
import SpriteKit
import SwiftUI

@main
struct MeokApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Publishes the real sky to the app. Refreshes on foreground; between
/// refreshes the store's cached/default ladder guarantees a value.
@MainActor
final class SkyMonitor: ObservableObject {
    @Published private(set) var conditions: WorldConditions
    private let store = SkyStore()

    init() {
        conditions = store.current()
    }

    func refresh() async {
        conditions = await store.refresh()
    }
}

/// Which scene the debug harness is showing; the world outside DEBUG.
enum DevSheet: String, CaseIterable {
    case world, strokes, carp

    static var launchDefault: DevSheet {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-meok-strokes") { return .strokes }
        if arguments.contains("-meok-carp") { return .carp }
        return .world
    }

    /// Seconds the CLI capture harness waits for the reveal to finish.
    var captureSettle: Double {
        switch self {
        case .world: 1
        case .strokes: 3.5
        case .carp: 7
        }
    }
}

struct ContentView: View {
    @StateObject private var host = WorldHost()
    @StateObject private var sky = SkyMonitor()
    @Environment(\.scenePhase) private var scenePhase
    @State private var devSheet = DevSheet.launchDefault

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WorldView(host: host, sheet: devSheet)
                .ignoresSafeArea()
            #if DEBUG
            SkyOverlay(conditions: sky.conditions)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            DevControls(host: host, devSheet: $devSheet)
            #endif
        }
        .statusBarHidden(true)
        .task {
            await sky.refresh()
            // Seed the initial bleed even when refresh didn't change anything
            // (onChange only fires on actual changes).
            applyBleed()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await sky.refresh() }
        }
        .onChange(of: sky.conditions) { applyBleed() }
        .onChange(of: host.bleedOverride) { applyBleed() }
    }

    /// The world bleeds with the real rain unless the debug override forces it.
    private func applyBleed() {
        host.scene?.rainBleed = host.bleedOverride ?? Float(sky.conditions.rainIntensity)
    }
}

#if DEBUG
struct SkyOverlay: View {
    let conditions: WorldConditions

    var body: some View {
        Text(verbatim: """
        \(conditions.weather.rawValue) · \(conditions.precipitation, format: "%.1f")mm/h
        wind \(conditions.windSpeed, format: "%.1f")m/s
        \(conditions.timeOfDay.rawValue) · \(conditions.season.rawValue)
        """)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .padding(8)
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: Double, format: String) {
        appendLiteral(String(format: format, value))
    }
}
#endif

/// Holds references to the live SKView/scene so SwiftUI debug controls can reach them.
final class WorldHost: ObservableObject {
    weak var skView: SKView?
    var scene: WorldScene?
    /// DEBUG-only: forces rain-bleed intensity; nil follows the real sky.
    @Published var bleedOverride: Float?
}

struct WorldView: UIViewRepresentable {
    let host: WorldHost
    var sheet = DevSheet.world

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.preferredFramesPerSecond = 60
        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        #endif
        let scene = WorldScene()
        view.presentScene(scene)
        host.skView = view
        host.scene = scene
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        #if DEBUG
        switch sheet {
        case .strokes:
            if !(uiView.scene is StrokeSheetScene) { uiView.presentScene(StrokeSheetScene()) }
        case .carp:
            if !(uiView.scene is CarpSheetScene) { uiView.presentScene(CarpSheetScene()) }
        case .world:
            if let world = host.scene, uiView.scene !== world { uiView.presentScene(world) }
        }
        #endif
    }
}

#if DEBUG
struct DevControls: View {
    let host: WorldHost
    @Binding var devSheet: DevSheet
    @State private var lastCapture: String?
    @State private var inkDensity: Float = 0.55
    @State private var overrideBleed = false
    @State private var bleedValue: Float = 0

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let lastCapture {
                Text(lastCapture)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Ink \(inkDensity, specifier: "%.2f")")
                    .font(.caption.monospaced())
                Slider(value: $inkDensity, in: 0...1)
                    .frame(width: 160)
                    .onChange(of: inkDensity) { _, value in
                        host.scene?.inkDensity = value
                    }
            }
            HStack {
                Toggle(isOn: $overrideBleed) {
                    Text("Bleed \(bleedValue, specifier: "%.2f")")
                        .font(.caption.monospaced())
                }
                .fixedSize()
                Slider(value: $bleedValue, in: 0...1)
                    .frame(width: 160)
                    .disabled(!overrideBleed)
            }
            .onChange(of: overrideBleed) { syncBleedOverride() }
            .onChange(of: bleedValue) { syncBleedOverride() }
            HStack {
                Picker("Scene", selection: $devSheet) {
                    ForEach(DevSheet.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                Button("Capture PNG") {
                    lastCapture = capturePNG()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .task {
            // CLI screenshot-review harness: launch args drive the same code
            // paths as the controls above, then PNGs are pulled from the app
            // container. `-meok-ink 0.9` seeds the density slider;
            // `-meok-bleed 0.7` turns on the bleed override;
            // `-meok-capture` presses the capture button.
            if UserDefaults.standard.object(forKey: "meok-ink") != nil {
                inkDensity = UserDefaults.standard.float(forKey: "meok-ink")
                host.scene?.inkDensity = inkDensity
            }
            if UserDefaults.standard.object(forKey: "meok-bleed") != nil {
                bleedValue = UserDefaults.standard.float(forKey: "meok-bleed")
                overrideBleed = true
                syncBleedOverride()
            }
            guard ProcessInfo.processInfo.arguments.contains("-meok-capture") else { return }
            // Sheets need their reveal to finish before capturing.
            try? await Task.sleep(for: .seconds(devSheet.captureSettle))
            lastCapture = capturePNG()
        }
    }

    private func syncBleedOverride() {
        host.bleedOverride = overrideBleed ? bleedValue : nil
    }

    /// Renders the current scene to a PNG in Documents; returns the file name.
    private func capturePNG() -> String? {
        guard let view = host.skView,
              let scene = view.scene,
              let texture = view.texture(from: scene)
        else { return nil }
        let image = UIImage(cgImage: texture.cgImage())
        guard let data = image.pngData() else { return nil }
        let name = "meok-\(Int(Date().timeIntervalSince1970)).png"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
        do {
            try data.write(to: url)
            print("Captured scene → \(url.path)")
            return name
        } catch {
            print("Capture failed: \(error)")
            return nil
        }
    }
}
#endif
