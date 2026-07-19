import SwiftUI
import SsakApp
import SsakCore

/// The iOS app entry point — a thin shell hosting `RootView`. All logic and art
/// live in the SsakApp/SsakArt/SsakCore packages.
@main
struct SsakGameApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(model: GardenModel(store: PlantStore(), now: Date()))
        }
    }
}
