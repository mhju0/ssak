import SwiftUI
import SsakCore
import SsakArt

/// The collection (spec §2.3): six slots that fill with pressed blooms as species complete.
/// Empty slots show a faint mono 싹 glyph; a quiet "garden complete" state at six; any bloom
/// is replantable. Light restyle only — the grid + replant flow are unchanged.
public struct ShelfView: View {
    @ObservedObject var model: GardenModel
    var onReplant: (Species) -> Void

    public init(model: GardenModel, onReplant: @escaping (Species) -> Void) {
        self.model = model; self.onReplant = onReplant
    }

    @Environment(\.colorScheme) private var scheme
    private var cardFill: Color { scheme == .dark ? Color(white: 0.17) : Color(white: 0.965) }

    private let cols = [GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)]

    public var body: some View {
        VStack(spacing: 16) {
            Text(model.isGardenComplete ? "Garden complete 🌸" : "Your shelf")
                .font(.system(.title3, design: .serif).weight(.semibold))
                .inkText()
                .padding(.top, 20)
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(SpeciesCatalog.all) { slot($0) }
            }
            .padding(.horizontal, 16)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ssakGround()
    }

    @ViewBuilder private func slot(_ sp: Species) -> some View {
        let have = model.collected.contains(sp.id)
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(cardFill)
                if have {
                    PlantView(species: sp, stage: .bloom)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    SsakMark(.mono).frame(width: 40, height: 40).opacity(0.5)
                }
            }
            .frame(height: 116)
            Text(have ? sp.nameEN : "—")
                .font(.caption2).fontWeight(have ? .medium : .regular)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(have ? "\(sp.nameEN), collected" : "Empty slot")
        .accessibilityAddTraits(have ? .isButton : [])
        .onTapGesture { if have { onReplant(sp) } }
    }
}
