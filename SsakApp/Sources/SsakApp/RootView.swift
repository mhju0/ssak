import SwiftUI
import SsakCore
import SsakArt

/// The app root (round 2): the windowsill or the shelf under a single top glass pill nav
/// (the bottom `TabView` is retired), with the first-run start guide overlaid on the live
/// windowsill. Reconciles the plant against the real clock whenever the app becomes
/// active. The real `Date()` is read only here, at the interaction boundary.
public struct RootView: View {
    @StateObject private var model: GardenModel
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @State private var tab = 0

    public init(model: GardenModel) {
        _model = StateObject(wrappedValue: model)
        SsakFonts.register()
    }

    public var body: some View {
        // A minute tick keeps the "read the clock only here" boundary honest over time:
        // without it the sky band, night ink flip, and moist chip freeze at the last
        // interaction for as long as the app stays foreground.
        TimelineView(.periodic(from: .now, by: 60)) { ctx in
            main(now: ctx.date)
        }
        .overlayPreferenceValue(GuideTargetKey.self) { anchors in
            if !hasOnboarded {
                GeometryReader { proxy in
                    StartGuide(anchors: anchors.mapValues { proxy[$0] },
                               speciesName: model.species.nameEN) {
                        model.reconcileOnOpen(now: Date())
                        hasOnboarded = true
                    }
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { model.reconcileOnOpen(now: Date()) }
        }
    }

    /// Night flips nav + shelf chrome to dark ink even in system light mode — the
    /// windowsill room behind them is dark (same rule as WindowsillView's chrome).
    private func chromeScheme(now: Date) -> ColorScheme {
        TimeBand(now: now, calendar: model.calendar) == .night ? .dark : scheme
    }

    @ViewBuilder private func main(now: Date) -> some View {
        let chromeScheme = chromeScheme(now: now)
        ZStack(alignment: .top) {
            if tab == 0 {
                WindowsillView(model: model, now: now,
                               onWater: { model.water(now: Date()) },
                               onShare: { presentShare() })
            } else {
                ShelfView(model: model, onReplant: { model.pressAndReplant($0, now: Date()) })
                    .environment(\.colorScheme, chromeScheme)
            }
            InkNavTabs(tab: $tab)                          // round 3: ink text tabs, top-right
                .padding(.top, 8)
                .padding(.trailing, Design.pad)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.colorScheme, chromeScheme)
        }
    }

    private func presentShare() {
        #if canImport(UIKit)
        let now = Date()
        let card = BloomCard(species: model.species, stage: model.stage,
                             day: model.currentDay(now: now), streak: model.streak)
        guard let image = card.shareImage(),
              let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        root.present(vc, animated: true)
        #endif
    }
}
