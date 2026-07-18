import SwiftUI
import GameKernel
import Persistence
import SkyState

/// A visitor encounter (spec §2): a greeting, a line of lore, and their
/// barters — hand over what they ask, receive what your sky can't give you.
/// The peddler's offers are the climate valve.
struct EncounterView: View {
    let visitor: Visitor
    let city: City
    let store: GameStore
    let onClose: () -> Void

    @State private var offers: [TradeOffer] = []
    @State private var traded: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(VisitorDialogue.lines(for: visitor.id).enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.callout)
                            .italic()
                            .foregroundStyle(.primary)
                    }
                } header: {
                    Text(verbatim: VisitorDialogue.displayName(for: visitor))
                }

                if offers.isEmpty {
                    Section {
                        Text("Nothing to trade under this sky today.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(offers) { offer in
                            offerRow(offer)
                        }
                    } header: {
                        Text("Barter")
                    } footer: {
                        Text("No coin changes hands — only what you've caught, grown, cooked, or made.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text(verbatim: VisitorDialogue.displayName(for: visitor)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onClose) { Text("Farewell") }
                }
            }
        }
        .onAppear {
            offers = Visitors.offers(for: visitor.id, climate: Climate.capability(of: city))
        }
    }

    private func offerRow(_ offer: TradeOffer) -> some View {
        let done = traded.contains(offer.id)
        let affordable = store.has([offer.give])
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rewardName(offer.get))
                    .font(.callout)
                Text(verbatim: "\(giveName(offer.give)) ×\(offer.give.count)")
                    .font(.caption.monospaced())
                    .foregroundStyle(store.count(of: offer.give.item) >= offer.give.count ? .secondary : Color.red.opacity(0.7))
            }
            Spacer()
            if done {
                Image(systemName: "checkmark.seal").foregroundStyle(.secondary)
            } else {
                Button {
                    if store.trade(offer, with: visitor.id) { traded.insert(offer.id) }
                } label: {
                    Text("Trade")
                }
                .buttonStyle(.bordered)
                .disabled(!affordable)
            }
        }
    }

    // MARK: Names

    private func rewardName(_ reward: TradeReward) -> String {
        switch reward {
        case .species(let id): collectibleName(id)
        case .good(let id): goodName(id)
        }
    }

    private func giveName(_ give: Ingredient) -> String {
        collectibleName(give.item)
    }

    private func collectibleName(_ id: String) -> String {
        let ko = Locale.current.language.languageCode?.identifier == "ko"
        if let fish = FishingTable.all.first(where: { $0.id == id }) { return ko ? fish.nameKO : fish.nameEN }
        if let forage = ForagingTable.all.first(where: { $0.id == id }) { return ko ? forage.nameKO : forage.nameEN }
        if let plant = GardenTable.all.first(where: { $0.id == id }) { return ko ? plant.nameKO : plant.nameEN }
        return goodName(id)
    }

    private func goodName(_ id: String) -> String {
        let ko = Locale.current.language.languageCode?.identifier == "ko"
        if let maker = CraftingTable.all.first(where: {
            if case .good(let g) = $0.effect { return g == id }
            return false
        }) {
            return ko ? maker.nameKO : maker.nameEN
        }
        return id
    }
}
