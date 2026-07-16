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

struct ContentView: View {
    @StateObject private var host = WorldHost()
    @StateObject private var sky = SkyMonitor()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WorldView(host: host)
                .ignoresSafeArea()
            #if DEBUG
            SkyOverlay(conditions: sky.conditions)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            DevControls(host: host)
            #endif
        }
        .statusBarHidden(true)
        .task { await sky.refresh() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await sky.refresh() }
        }
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
}

struct WorldView: UIViewRepresentable {
    let host: WorldHost

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

    func updateUIView(_ uiView: SKView, context: Context) {}
}

#if DEBUG
struct DevControls: View {
    let host: WorldHost
    @State private var lastCapture: String?
    @State private var inkDensity: Float = 0.55

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
            Button("Capture PNG") {
                lastCapture = capturePNG()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .task {
            // CLI screenshot-review harness: launch args drive the same code
            // paths as the controls above, then PNGs are pulled from the app
            // container. `-meok-ink 0.9` seeds the density slider;
            // `-meok-capture` presses the capture button.
            if UserDefaults.standard.object(forKey: "meok-ink") != nil {
                inkDensity = UserDefaults.standard.float(forKey: "meok-ink")
                host.scene?.inkDensity = inkDensity
            }
            guard ProcessInfo.processInfo.arguments.contains("-meok-capture") else { return }
            try? await Task.sleep(for: .seconds(1))
            lastCapture = capturePNG()
        }
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
