import SwiftUI
import SsakCore
import SsakArt

/// The collection (round 2): a left-aligned serif header and a 2-column grid of 3:4
/// pressed-bloom cards — sized so the third row bleeds past the fold, the scroll
/// affordance itself. Empty slots show the faint mono 싹 glyph; any bloom is replantable.
public struct ShelfView: View {
    @ObservedObject var model: GardenModel
    var onReplant: (Species) -> Void

    public init(model: GardenModel, onReplant: @escaping (Species) -> Void) {
        self.model = model; self.onReplant = onReplant
    }

    private static let counts = ["None", "One", "Two", "Three", "Four", "Five", "Six"]

    public var body: some View {
        // ScrollView on device (the third row bleeds past the fold — the scroll cue);
        // ImageRenderer can't lay out a ScrollView on the macOS render path, so the
        // harness gets the same content top-aligned and clipped — visually identical.
        #if os(iOS)
        ScrollView { content }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ssakGround()
        #else
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .ssakGround()
        #endif
    }

    private var content: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.isGardenComplete ? "Garden complete 🌸" : "Your shelf")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .inkText()
                Text(model.isGardenComplete
                     ? "All six pressed. Replant any bloom."
                     : model.collected.isEmpty
                     ? "Nothing pressed yet — your first bloom will live here."
                     : "\(Self.counts[model.collected.count]) of six pressed. Keep growing.")
                    .font(.footnote).foregroundStyle(.secondary)
                // Six fixed slots — a plain grid, not LazyVGrid (lazy children never
                // materialize under ImageRenderer, so the reference renders came out empty).
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { r in
                        HStack(spacing: 16) {
                            slot(SpeciesCatalog.all[r * 2])
                            slot(SpeciesCatalog.all[r * 2 + 1])
                        }
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, Design.pad)
            .padding(.top, 64)                     // clears the 44pt top-nav row
    }                                              // no bottom padding — the fold cut is the cue

    @ViewBuilder private func slot(_ sp: Species) -> some View {
        let have = model.collected.contains(sp.id)
        Button { onReplant(sp) } label: { card(sp, have: have) }
            .buttonStyle(.pressable)
            .disabled(!have)                       // empty slots aren't tappable
            .accessibilityLabel(have ? "\(sp.nameEN), collected. Replants this bloom." : "Empty slot")
    }

    private func card(_ sp: Species, have: Bool) -> some View {
        ZStack(alignment: .bottom) {
            if have {
                PlantView(species: sp, stage: .bloom, wall: false, board: false)
                    .padding(.top, 8)
                    .padding(.bottom, 30)          // room for the caption strip below the pot
            } else {
                SsakMark(.mono).frame(width: 40, height: 40).opacity(0.5)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            Text(have ? sp.nameEN : "—")
                .font(.system(.footnote, design: .serif))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3 / 4, contentMode: .fit)
        .ssakGlass(RoundedRectangle(cornerRadius: Design.rMD))
        .accessibilityElement(children: .ignore)
    }
}
