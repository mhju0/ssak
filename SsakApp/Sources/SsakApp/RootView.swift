import SwiftUI
import SsakCore

/// The app root: gates first-run onboarding, swaps between the windowsill and the
/// shelf, and reconciles the plant against the real clock whenever the app becomes
/// active. The real `Date()` is read only here, at the interaction boundary.
public struct RootView: View {
    @StateObject private var model: GardenModel
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0

    public init(model: GardenModel) { _model = StateObject(wrappedValue: model) }

    public var body: some View {
        content
            .onChange(of: scenePhase) { phase in
                if phase == .active { model.reconcileOnOpen(now: Date()) }
            }
    }

    @ViewBuilder private var content: some View {
        if !hasOnboarded {
            OnboardingView {
                model.reconcileOnOpen(now: Date())
                hasOnboarded = true
            }
        } else {
            TabView(selection: $tab) {
                WindowsillView(model: model, now: Date(),
                               onWater: { model.water(now: Date()) },
                               onShare: { presentShare() })
                    .tag(0)
                    .tabItem { Label("Windowsill", systemImage: "sun.max.fill") }
                ShelfView(model: model, onReplant: { model.pressAndReplant($0, now: Date()) })
                    .tag(1)
                    .tabItem { Label("Shelf", systemImage: "square.grid.2x2.fill") }
            }
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
