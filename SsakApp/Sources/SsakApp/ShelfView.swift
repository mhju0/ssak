import SwiftUI
import SsakCore
import SsakArt

/// The collection (round 3): the 압화집's own pages — hanji paper (band-driven like the
/// windowsill), a myeongjo header, and a 2-column grid of 3:4 paper specimen cards with
/// hairline ink borders. Empty slots show the faint mono 싹 glyph; the current plant's
/// slot opens as a seal-red "지금 눌러 두기" target the moment it blooms; any collected
/// bloom is replantable.
public struct ShelfView: View {
    @ObservedObject var model: GardenModel
    let now: Date
    var onReplant: (Species) -> Void

    public init(model: GardenModel, now: Date, onReplant: @escaping (Species) -> Void) {
        self.model = model; self.now = now; self.onReplant = onReplant
    }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        // ScrollView on device (the third row bleeds past the fold — the scroll cue);
        // ImageRenderer can't lay out a ScrollView on the macOS render path, so the
        // harness gets the same content top-aligned and clipped — visually identical.
        ZStack {
            HanjiBackdrop(now: now, calendar: model.calendar).ignoresSafeArea()
            #if os(iOS)
            ScrollView { content }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            #else
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
            #endif
        }
    }

    private var subtitle: String {
        model.isGardenComplete ? "여섯 송이 모두 눌렀어요 · 어느 꽃이든 다시 심어요"
        : model.collected.isEmpty ? "아직 눌러 둔 꽃이 없어요 · 첫 꽃이 여기 담겨요"
        : "여섯 송이 중 \(model.collected.count)송이 눌렀어요"
    }

    private var content: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(model.isGardenComplete ? "압화집 · 완성 🌸" : "압화집")
                    .font(.myeongjoDisplay(20, relativeTo: .title3)).tracking(3)
                    .inkText()
                Text(subtitle)
                    .font(.myeongjo(12, relativeTo: .footnote)).tracking(1)
                    .inkText().opacity(0.65)
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
        // The current plant's slot opens up the moment it blooms — THE way the first
        // bloom (and every later one) gets pressed. Pressing plants the next species
        // still missing from the shelf; once none are left, the same species replants.
        let pressHere = !have && sp.id == model.species.id && model.stage == .bloom
        Button { onReplant(pressHere ? (model.nextUncollected ?? sp) : sp) }
            label: { card(sp, have: have, pressHere: pressHere) }
            .buttonStyle(.pressable)
            .disabled(!have && !pressHere)         // other empty slots aren't tappable
            .accessibilityLabel(pressHere ? "\(sp.nameEN), in bloom. Press to your shelf."
                                : have ? "\(sp.nameEN), collected. Replants this bloom." : "Empty slot")
    }

    private func card(_ sp: Species, have: Bool, pressHere: Bool) -> some View {
        let red = SealRed.color(scheme)
        return ZStack(alignment: .bottom) {
            if have || pressHere {
                PlantView(species: sp, stage: .bloom, wall: false, board: false)
                    .padding(.top, 8)
                    .padding(.bottom, 30)          // room for the caption strip below the pot
            } else {
                SsakMark(.mono).frame(width: 40, height: 40).opacity(0.5)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            Text(pressHere ? "지금 눌러 두기 🌸" : have ? sp.nameKO : "—")
                .font(.myeongjo(12, relativeTo: .footnote)).tracking(1)
                .foregroundStyle(pressHere ? red : .secondary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3 / 4, contentMode: .fit)
        .background(paperCard)
        .overlay {
            if pressHere {
                RoundedRectangle(cornerRadius: Design.rMD)
                    .strokeBorder(red, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            }
        }
        .accessibilityElement(children: .ignore)
    }

    /// A slightly raised page of paper: lighter fill + hairline ink border, no glass.
    private var paperCard: some View {
        RoundedRectangle(cornerRadius: Design.rMD)
            .fill(scheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.35))
            .overlay(RoundedRectangle(cornerRadius: Design.rMD)
                .strokeBorder((scheme == .dark ? Color.white : Design.shadow).opacity(0.22)))
            .shadow(color: Design.shadow.opacity(scheme == .dark ? 0 : 0.10), radius: 6, y: 3)
    }
}
