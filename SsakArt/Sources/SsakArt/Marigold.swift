import SwiftUI

enum MarigoldArt {
    // Filled in Tasks 8–11. Until then each returns a labelled placeholder.
    @ViewBuilder static func sprout(_ p: SpeciesPalette) -> some View { Placeholder(text: "sprout") }
    @ViewBuilder static func leaves(_ p: SpeciesPalette) -> some View { Placeholder(text: "leaves") }
    @ViewBuilder static func bud(_ p: SpeciesPalette)    -> some View { Placeholder(text: "bud") }
    @ViewBuilder static func bloom(_ p: SpeciesPalette)  -> some View { Placeholder(text: "bloom") }
}

struct Placeholder: View {
    let text: String
    var body: some View {
        Text(text).font(.caption2).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.15))
    }
}
