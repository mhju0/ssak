import SwiftUI
import GameKernel
import Persistence
import SkyState

/// A collectible with a gallery row — fish and forageables both qualify. The
/// members already exist on each; conformance just names the shared shape.
protocol LedgerItem: Identifiable {
    var id: String { get }
    var displayName: String { get }
    var weathers: Set<WorldConditions.Weather> { get }
    var unlockLevel: Int { get }
}

extension FishSpecies: LedgerItem {}
extension Forageable: LedgerItem {}

/// The Gallery (spec §2, the collection endgame): caught species, gathered
/// finds, and the player's own paintings, each with per-climate completion.
/// Specimens the sky can't produce carry the honest label and stay out of the
/// denominator (per-climate 100%); a painting can bake any sky the climate makes.
struct GalleryView: View {
    let store: GameStore
    let city: City
    @Environment(\.dismiss) private var dismiss

    private struct Row: Identifiable {
        let item: any LedgerItem
        let record: SpeciesRecord?
        let native: Bool
        var id: String { item.id }
    }

    private struct Group: Identifiable {
        let title: LocalizedStringKey
        let key: String
        let rows: [Row]
        var id: String { key }
    }

    private struct PaintingRow: Identifiable {
        let composition: Composition
        let paintedWeathers: Set<String>
        let works: Int
        let anySealed: Bool
        var id: String { composition.id }
    }

    @State private var groups: [Group] = []
    @State private var paintings: [PaintingRow] = []

    private let sealRed = Color(red: 0.72, green: 0.14, blue: 0.11)

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.rows) { rowView($0) }
                    } header: {
                        completionHeader(group)
                    }
                }
                Section {
                    ForEach(paintings) { paintingRowView($0) }
                } header: {
                    paintingsHeader
                }
            }
            .listStyle(.plain)
            .navigationTitle(Text("Gallery"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) { Text("Done") }
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        let capability = Climate.capability(of: city)
        func rows(_ items: [any LedgerItem]) -> [Row] {
            items
                .sorted { ($0.unlockLevel, $0.id) < ($1.unlockLevel, $1.id) }
                .map { item in
                    Row(
                        item: item,
                        record: store.record(for: item.id),
                        native: !item.weathers.isDisjoint(with: capability))
                }
        }
        groups = [
            Group(title: "Fishing", key: "fishing", rows: rows(FishingTable.all)),
            Group(title: "Foraging", key: "foraging", rows: rows(ForagingTable.all)),
        ]

        let allWorks = store.paintings()
        paintings = Artistry.compositions
            .sorted { $0.unlockLevel < $1.unlockLevel }
            .map { composition in
                let works = allWorks.filter { $0.compositionID == composition.id }
                return PaintingRow(
                    composition: composition,
                    paintedWeathers: Set(works.map(\.weather)),
                    works: works.count,
                    anySealed: works.contains(where: \.sealed))
            }
    }

    // MARK: Specimens

    private func completionHeader(_ group: Group) -> some View {
        let capability = Climate.capability(of: city)
        let native = group.rows.filter(\.native)
        let caught = native.filter { ($0.record?.timesCaught ?? 0) > 0 }
        let variantTotal = native.reduce(0) { $0 + $1.item.weathers.intersection(capability).count }
        let variantCaught = native.reduce(0) { total, row in
            let caughtSet = Set((row.record?.caughtWeathers ?? []).compactMap(WorldConditions.Weather.init))
            return total + caughtSet.intersection(capability).count
        }
        return VStack(alignment: .leading, spacing: 2) {
            Text(group.title)
                .font(.caption.weight(.semibold))
            Text("\(caught.count) of \(native.count) under your sky · \(variantCaught)/\(variantTotal) variants")
        }
        .font(.caption)
        .textCase(nil)
    }

    @ViewBuilder
    private func rowView(_ row: Row) -> some View {
        let caught = (row.record?.timesCaught ?? 0) > 0
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                if caught {
                    Text(row.item.displayName)
                } else {
                    Text(verbatim: "???")
                        .foregroundStyle(.secondary)
                }
                if caught {
                    variantMarks(
                        weathers: row.item.weathers.sorted { $0.rawValue < $1.rawValue },
                        filled: Set(row.record?.caughtWeathers ?? []))
                }
                if !caught, row.record?.gotAway == true {
                    Text("One that got away…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !row.native {
                    Text("Not native to your sky.")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Lv \(row.item.unlockLevel)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                if let count = row.record?.timesCaught, count > 0 {
                    Text(verbatim: "×\(count)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .opacity(row.native ? 1 : 0.55)
    }

    // MARK: Paintings

    private var paintingsHeader: some View {
        let capability = Climate.capability(of: city)
        let started = paintings.filter { $0.works > 0 }.count
        let skiesTotal = paintings.count * capability.count
        let skiesPainted = paintings.reduce(0) { total, row in
            total + row.paintedWeathers.compactMap(WorldConditions.Weather.init).filter(capability.contains).count
        }
        return VStack(alignment: .leading, spacing: 2) {
            Text("Paintings")
                .font(.caption.weight(.semibold))
            Text("\(started) of \(paintings.count) frames · \(skiesPainted)/\(skiesTotal) skies")
        }
        .font(.caption)
        .textCase(nil)
    }

    @ViewBuilder
    private func paintingRowView(_ row: PaintingRow) -> some View {
        let painted = row.works > 0
        let capability = Climate.capability(of: city)
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                if painted {
                    HStack(spacing: 6) {
                        Text(row.composition.displayName)
                        if row.anySealed {
                            Image(systemName: "seal.fill")
                                .font(.caption2)
                                .foregroundStyle(sealRed)
                        }
                    }
                    variantMarks(
                        weathers: capability.sorted { $0.rawValue < $1.rawValue },
                        filled: row.paintedWeathers)
                } else {
                    Text(verbatim: "???")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Lv \(row.composition.unlockLevel)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                if painted {
                    Text(verbatim: "×\(row.works)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Shared

    /// One mark per weather — filled once collected/painted under that sky.
    private func variantMarks(
        weathers: [WorldConditions.Weather], filled: Set<String>
    ) -> some View {
        HStack(spacing: 6) {
            ForEach(weathers, id: \.rawValue) { weather in
                Image(systemName: symbol(for: weather))
                    .font(.caption2)
                    .foregroundStyle(filled.contains(weather.rawValue) ? .primary : .tertiary)
            }
        }
    }

    private func symbol(for weather: WorldConditions.Weather) -> String {
        switch weather {
        case .clear: "sun.max"
        case .cloudy: "cloud"
        case .fog: "cloud.fog"
        case .rain: "cloud.rain"
        case .snow: "snowflake"
        case .storm: "cloud.bolt"
        }
    }
}
