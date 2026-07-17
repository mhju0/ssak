import SwiftUI
import GameKernel
import Persistence
import SkyState

/// The species ledger v0 — a list over SpeciesRecord (spec §2). Caught
/// species show their variant marks; escapes leave shadows; species the
/// player's sky can't produce carry the honest label and stay out of the
/// completion denominator (per-climate 100%).
struct LedgerView: View {
    let store: GameStore
    let city: City
    @Environment(\.dismiss) private var dismiss

    private struct Row: Identifiable {
        let species: FishSpecies
        let record: SpeciesRecord?
        let native: Bool
        var id: String { species.id }
    }

    @State private var rows: [Row] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(rows) { row in
                        rowView(row)
                    }
                } header: {
                    completionHeader
                }
            }
            .listStyle(.plain)
            .navigationTitle(Text("Ledger"))
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
        rows = FishingTable.all
            .sorted { ($0.unlockLevel, $0.id) < ($1.unlockLevel, $1.id) }
            .map { species in
                Row(
                    species: species,
                    record: store.record(for: species.id),
                    native: !species.weathers.isDisjoint(with: capability))
            }
    }

    private var completionHeader: some View {
        let capability = Climate.capability(of: city)
        let native = rows.filter(\.native)
        let caught = native.filter { ($0.record?.timesCaught ?? 0) > 0 }
        let variantTotal = native.reduce(0) { $0 + $1.species.weathers.intersection(capability).count }
        let variantCaught = native.reduce(0) { total, row in
            let caughtSet = Set((row.record?.caughtWeathers ?? []).compactMap(WorldConditions.Weather.init))
            return total + caughtSet.intersection(capability).count
        }
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(caught.count) of \(native.count) species under your sky")
            Text("\(variantCaught) of \(variantTotal) weather variants")
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
                    Text(row.species.displayName)
                } else {
                    Text(verbatim: "???")
                        .foregroundStyle(.secondary)
                }
                if caught {
                    variantMarks(row)
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
                Text("Lv \(row.species.unlockLevel)")
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

    /// One mark per weather in the species' variant set — filled once
    /// caught under that sky.
    private func variantMarks(_ row: Row) -> some View {
        let caughtSet = Set(row.record?.caughtWeathers ?? [])
        let weathers = row.species.weathers.sorted { $0.rawValue < $1.rawValue }
        return HStack(spacing: 6) {
            ForEach(weathers, id: \.rawValue) { weather in
                Image(systemName: symbol(for: weather))
                    .font(.caption2)
                    .foregroundStyle(
                        caughtSet.contains(weather.rawValue) ? .primary : .tertiary)
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
