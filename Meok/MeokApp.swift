import GameKernel
import Persistence
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
    @Published private(set) var city: City
    private let store = SkyStore()

    init() {
        city = store.city
        conditions = store.current()
    }

    func refresh() async {
        conditions = await store.refresh()
    }

    /// The scroll moves to another sky: persist the pick and refetch.
    func setCity(_ newCity: City) async {
        store.city = newCity
        city = newCity
        conditions = await store.refresh()
    }
}

/// Which scene the debug harness is showing; the world outside DEBUG.
enum DevSheet: String, CaseIterable {
    case world, strokes, carp, fish, keeper

    static var launchDefault: DevSheet {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-meok-strokes") { return .strokes }
        if arguments.contains("-meok-carp") { return .carp }
        if arguments.contains("-meok-fish") { return .fish }
        if arguments.contains("-meok-keeper") { return .keeper }
        return .world
    }

    /// Seconds the CLI capture harness waits for the reveal to finish.
    var captureSettle: Double {
        switch self {
        case .world: 11
        case .strokes: 3.5
        case .carp: 7
        case .fish: 9
        case .keeper: 5
        }
    }
}

struct ContentView: View {
    @StateObject private var host = WorldHost()
    @StateObject private var sky = SkyMonitor()
    @Environment(\.scenePhase) private var scenePhase
    @State private var devSheet = DevSheet.launchDefault
    @State private var showSettings = false
    @State private var gameStore: GameStore?
    @State private var showFishing = ProcessInfo.processInfo.arguments.contains("-meok-fish-demo")
    private let cleanChrome = ProcessInfo.processInfo.arguments.contains("-meok-clean")

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WorldView(host: host, sheet: devSheet)
                .ignoresSafeArea()
            // The pond invites fishing when the scroll rests there.
            if host.zone == .valleyPond, gameStore != nil, devSheet == .world {
                Button {
                    showFishing = true
                } label: {
                    Text("Fish")
                        .font(.callout)
                        .foregroundStyle(Color(red: 0.10, green: 0.095, blue: 0.09).opacity(0.8))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 8)
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.10, green: 0.095, blue: 0.09).opacity(0.5), lineWidth: 1))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 30)
            }
            if !cleanChrome {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
            #if DEBUG
            // -meok-clean hides the debug chrome so full-screen simctl
            // screenshots/recordings are presentation-ready. (The in-app
            // texture(from:) capture can render stale shader uniforms, so
            // gate materials go through simctl instead.)
            if !cleanChrome {
                SkyOverlay(conditions: sky.conditions, zoneName: host.zoneName)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                DevControls(host: host, devSheet: $devSheet)
            }
            #endif
        }
        .statusBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsView(sky: sky)
        }
        .fullScreenCover(isPresented: $showFishing) {
            if let gameStore {
                FishingView(conditions: sky.conditions, store: gameStore) {
                    showFishing = false
                }
            }
        }
        .task {
            gameStore = try? GameStore.live()
            harnessSeed()
            await sky.refresh()
            // Seed the initial sky even when refresh didn't change anything
            // (onChange only fires on actual changes).
            applySky()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await sky.refresh() }
        }
        .onChange(of: sky.conditions) { applySky() }
        .onChange(of: host.bleedOverride) { applySky() }
        .onChange(of: host.darkOverride) { applySky() }
    }

    /// The world follows the real rain and the real sun unless the debug
    /// overrides force them.
    private func applySky() {
        host.scene?.rainBleed = host.bleedOverride ?? Float(sky.conditions.rainIntensity)
        host.scene?.darkness = host.darkOverride ?? Float(sky.conditions.darkness)
    }

    /// Harness overrides, available in every configuration so device A/B
    /// tests work from a Release scheme: `-meok-ink 0.9` seeds wash density,
    /// `-meok-bleed 0.7` forces the bleed override, `-meok-cam 0.5` parks
    /// the camera at an altitude fraction (0 = pond, 1 = peak). Capture
    /// (`-meok-capture`, DEBUG-only) saves a scene PNG after the reveal
    /// settles.
    private func harnessSeed() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "meok-ink") != nil {
            host.scene?.inkDensity = defaults.float(forKey: "meok-ink")
        }
        if defaults.object(forKey: "meok-bleed") != nil {
            host.bleedOverride = defaults.float(forKey: "meok-bleed")
        }
        if defaults.object(forKey: "meok-dark") != nil {
            host.darkOverride = defaults.float(forKey: "meok-dark")
        }
        if defaults.object(forKey: "meok-cam") != nil {
            host.scene?.parkCamera(atFraction: CGFloat(defaults.float(forKey: "meok-cam")))
        }
        if defaults.object(forKey: "meok-walk") != nil {
            // Simulated tap for the harness (simctl can't touch the screen):
            // walk toward the given x fraction once the launch reveal has
            // painted the keeper in (~10s).
            let fraction = CGFloat(defaults.float(forKey: "meok-walk"))
            Task {
                try? await Task.sleep(for: .seconds(11))
                guard let scene = host.scene else { return }
                scene.walkKeeper(towardSceneX: fraction * scene.size.width)
            }
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-meok-capture") {
            Task {
                try? await Task.sleep(for: .seconds(devSheet.captureSettle))
                _ = capturePNG(from: host)
            }
        }
        #endif
    }
}

#if DEBUG
struct SkyOverlay: View {
    let conditions: WorldConditions
    var zoneName = ""

    var body: some View {
        Text(verbatim: """
        \(conditions.weather.rawValue) · \(conditions.precipitation, format: "%.1f")mm/h
        wind \(conditions.windSpeed, format: "%.1f")m/s
        \(conditions.timeOfDay.rawValue) · \(conditions.season.rawValue) · dark \(conditions.darkness, format: "%.2f")
        \(zoneName)
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
    /// Harness override (works in all configurations): forces rain-bleed
    /// intensity; nil follows the real sky.
    @Published var bleedOverride: Float?
    /// Harness override (works in all configurations): forces darkness;
    /// nil follows the real sun.
    @Published var darkOverride: Float?
    /// Zone + altitude under the camera, for the debug overlay.
    @Published var zoneName = ""
    /// Zone under the camera — gates zone activities (fishing at the pond).
    @Published var zone: Zone?
}

struct WorldView: UIViewRepresentable {
    let host: WorldHost
    var sheet = DevSheet.world

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.preferredFramesPerSecond = 60
        #if DEBUG
        if !ProcessInfo.processInfo.arguments.contains("-meok-clean") {
            view.showsFPS = true
            view.showsNodeCount = true
        }
        #endif
        let scene = WorldScene()
        scene.onAltitudeChange = { [weak host] zone, fraction in
            host?.zoneName = String(format: "%@ · alt %.2f", zone.name, fraction)
            host?.zone = zone
        }
        view.presentScene(scene)
        host.skView = view
        host.scene = scene

        context.coordinator.scene = scene
        let pan = UIPanGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.pan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.tap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    /// Bridges the thumb-drag to the scene: drag down pulls the scroll down
    /// (camera climbs toward the peak), like unrolling a hanging scroll.
    final class Coordinator: NSObject {
        weak var scene: WorldScene?

        @objc func pan(_ gesture: UIPanGestureRecognizer) {
            guard let scene, let view = gesture.view else { return }
            switch gesture.state {
            case .changed:
                let deltaY = gesture.translation(in: view).y
                gesture.setTranslation(.zero, in: view)
                scene.scrollBy(deltaY)
            case .ended, .cancelled:
                scene.endScroll(velocity: gesture.velocity(in: view).y)
            default:
                break
            }
        }

        /// Drag scrolls the mountain; tap walks the keeper (spec §3).
        @objc func tap(_ gesture: UITapGestureRecognizer) {
            guard let scene, let view = gesture.view as? SKView,
                  view.scene === scene else { return }
            let point = scene.convertPoint(fromView: gesture.location(in: view))
            scene.walkKeeper(towardSceneX: point.x)
        }
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        #if DEBUG
        switch sheet {
        case .strokes:
            if !(uiView.scene is StrokeSheetScene) { uiView.presentScene(StrokeSheetScene()) }
        case .carp:
            if !(uiView.scene is CarpSheetScene) { uiView.presentScene(CarpSheetScene()) }
        case .fish:
            if !(uiView.scene is FishSheetScene) { uiView.presentScene(FishSheetScene()) }
        case .keeper:
            if !(uiView.scene is KeeperSheetScene) { uiView.presentScene(KeeperSheetScene()) }
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
    @State private var overrideDark = false
    @State private var darkValue: Float = 0

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let lastCapture {
                Text(lastCapture)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(verbatim: String(format: "Ink %.2f", inkDensity))
                    .font(.caption.monospaced())
                Slider(value: $inkDensity, in: 0...1)
                    .frame(width: 160)
                    .onChange(of: inkDensity) { _, value in
                        host.scene?.inkDensity = value
                    }
            }
            HStack {
                Toggle(isOn: $overrideBleed) {
                    Text(verbatim: String(format: "Bleed %.2f", bleedValue))
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
                Toggle(isOn: $overrideDark) {
                    Text(verbatim: String(format: "Dark %.2f", darkValue))
                        .font(.caption.monospaced())
                }
                .fixedSize()
                Slider(value: $darkValue, in: 0...1)
                    .frame(width: 160)
                    .disabled(!overrideDark)
            }
            .onChange(of: overrideDark) { syncDarkOverride() }
            .onChange(of: darkValue) { syncDarkOverride() }
            HStack {
                Picker("Scene", selection: $devSheet) {
                    ForEach(DevSheet.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                Button {
                    lastCapture = capturePNG(from: host)
                } label: {
                    Text(verbatim: "Capture PNG")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func syncBleedOverride() {
        host.bleedOverride = overrideBleed ? bleedValue : nil
    }

    private func syncDarkOverride() {
        host.darkOverride = overrideDark ? darkValue : nil
    }
}

/// Renders the current scene to a PNG in Documents; returns the file name.
/// Note: texture(from:) can render stale shader-uniform values — fine for
/// the recipe sheets; use `simctl io screenshot` + `-meok-clean` for the
/// live world.
@MainActor
func capturePNG(from host: WorldHost) -> String? {
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
#endif
