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

    public init(model: GardenModel) { _model = StateObject(wrappedValue: model) }

    public var body: some View {
        content
            .onChange(of: scenePhase) { phase in
                if phase == .active { model.reconcileOnOpen(now: Date()) }
            }
    }

    /// Night flips nav + shelf chrome to dark ink even in system light mode — the
    /// windowsill room behind them is dark (same rule as WindowsillView's chrome).
    private var chromeScheme: ColorScheme {
        TimeBand(now: Date(), calendar: model.calendar) == .night ? .dark : scheme
    }

    @ViewBuilder private var content: some View {
        if !hasOnboarded {
            // ponytail: interim gate — T4 replaces this screen with the coach-mark StartGuide
            OnboardingView {
                model.reconcileOnOpen(now: Date())
                hasOnboarded = true
            }
        } else {
            main
        }
    }

    @ViewBuilder private var main: some View {
        ZStack(alignment: .top) {
            if tab == 0 {
                WindowsillView(model: model, now: Date(),
                               onWater: { model.water(now: Date()) },
                               onShare: { presentShare() })
            } else {
                ShelfView(model: model, onReplant: { model.pressAndReplant($0, now: Date()) })
                    .environment(\.colorScheme, chromeScheme)
            }
            TopNavPill(tab: $tab)
                .padding(.top, 8)
                .environment(\.colorScheme, chromeScheme)
        }
    }

    private func presentShare() {
        #if canImport(UIKit)
        let now = Date()
        let card = BloomCard(species: model.species, day: model.currentDay(now: now), streak: model.streak)
        guard let image = card.shareImage(),
              let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        root.present(vc, animated: true)
        #endif
    }
}
