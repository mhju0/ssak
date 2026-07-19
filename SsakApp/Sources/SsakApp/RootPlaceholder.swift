import SwiftUI
import SsakCore
import SsakArt

/// Temporary app root — replaced by RootView in Task 9. Proves SsakApp composes
/// SsakArt + SsakCore.
public struct RootPlaceholder: View {
    public init() {}
    public var body: some View {
        PlantView(species: SpeciesCatalog.starter, stage: .bloom)
    }
}
