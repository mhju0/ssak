import SwiftUI
import SsakCore
import SsakArt

/// The collection (spec §6): six slots that fill with pressed blooms as species
/// complete. A quiet "garden complete" state at six; any bloom is replantable.
public struct ShelfView: View {
    @ObservedObject var model: GardenModel
    var onReplant: (Species) -> Void

    public init(model: GardenModel, onReplant: @escaping (Species) -> Void) {
        self.model = model; self.onReplant = onReplant
    }

    private let cols = [GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)]

    public var body: some View {
        VStack(spacing: 14) {
            Text(model.isGardenComplete ? "Garden complete 🌸" : "Your shelf")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 0.28, green: 0.22, blue: 0.16))
                .padding(.top, 18)
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(SpeciesCatalog.all) { slot($0) }
            }
            .padding(.horizontal, 16)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.99, green: 0.97, blue: 0.92))
    }

    @ViewBuilder private func slot(_ sp: Species) -> some View {
        let have = model.collected.contains(sp.id)
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.965))
                if have {
                    PlantView(species: sp, stage: .bloom)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Circle()
                        .strokeBorder(Color(white: 0.80), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        .frame(width: 34, height: 34)
                }
            }
            .frame(height: 116)
            Text(have ? sp.nameEN : "—")
                .font(.system(size: 11, weight: have ? .medium : .regular))
                .foregroundStyle(.secondary)
        }
        .onTapGesture { if have { onReplant(sp) } }
    }
}
