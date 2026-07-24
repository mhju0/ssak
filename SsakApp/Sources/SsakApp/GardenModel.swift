import Foundation
import SsakCore

/// The whole game's logic: a time-injected reducer over `GameState`, the growth
/// engine, and persistence. Every transition takes `now` so it is testable
/// without the wall clock; views read the real clock only at the boundary.
@MainActor
public final class GardenModel: ObservableObject {
    @Published public private(set) var state: GameState
    public let store: PlantStore
    public var tuning: GrowthTuning
    let calendar: Calendar

    /// Production: load the saved game, or plant a fresh starter at `now`.
    public convenience init(store: PlantStore = PlantStore(), now: Date,
                            tuning: GrowthTuning = .default, calendar: Calendar = .current) {
        let loaded = store.load()
        let initial = loaded ?? GameState(
            plant: GrowthEngine.plant(SpeciesCatalog.starter, at: now), collected: [])
        self.init(state: initial, store: store, tuning: tuning, calendar: calendar)
        if loaded == nil { try? store.save(state) }
    }

    /// Construct from a known state — used by SwiftUI previews and render harnesses.
    public init(state: GameState, store: PlantStore,
                tuning: GrowthTuning = .default, calendar: Calendar = .current) {
        self.state = state; self.store = store; self.tuning = tuning; self.calendar = calendar
    }

    // MARK: - Transitions (time-injected, persisted)

    public func reconcileOnOpen(now: Date) {
        state.plant = GrowthEngine.reconcile(state.plant, to: now, species: species, tuning: tuning)
        try? store.save(state)
    }

    public func water(now: Date) {
        state.plant = GrowthEngine.water(state.plant, at: now, species: species,
                                         tuning: tuning, calendar: calendar)
        try? store.save(state)
    }

    /// Onboarding pick: swap the starter seed for `species`. Only while the game is
    /// untouched (fresh seed, empty shelf) — the picker exists only on the start screen,
    /// and this guard keeps a replayed guide from ever eating a real plant.
    public func choosePlant(_ species: Species, now: Date) {
        guard state.plant.progress == 0, state.collected.isEmpty else { return }
        state.plant = GrowthEngine.plant(species, at: now)
        try? store.save(state)
    }

    /// When the current plant has bloomed, press it to the shelf (once) and plant `next`.
    public func pressAndReplant(_ next: Species, now: Date) {
        guard stage == .bloom else { return }
        if !state.collected.contains(state.plant.speciesID) {
            state.collected.append(state.plant.speciesID)
        }
        state.plant = GrowthEngine.plant(next, at: now)
        try? store.save(state)
    }

    // MARK: - Derived (no mutation)

    public var species: Species { SpeciesCatalog.species(id: state.plant.speciesID) ?? SpeciesCatalog.starter }
    public var stage: GrowthStage { GrowthEngine.stage(forProgress: state.plant.progress) }
    public var moistureFraction: Double { min(1, max(0, state.plant.moisture / tuning.moistureMax)) }
    public var soil: SoilState { SoilState(moisture: state.plant.moisture, tuning: tuning) }
    public var streak: Int { state.plant.streak }
    public var isNursing: Bool { state.plant.isNursing }
    public var collected: [String] { state.collected }

    /// The plant's age in *calendar* days, 1-based (planting day is Day 1) — the same
    /// day semantics as the streak's `dayGap`, so "Day" rolls over at midnight, not 24h
    /// after planting. Time-injected so views don't reach into `state.plant` themselves.
    public func currentDay(now: Date) -> Int {
        (calendar.dayGap(from: state.plant.plantedAt, to: now) ?? 0) + 1
    }
    /// The species to plant after pressing the current bloom: catalog order, skipping the
    /// shelf and the plant being pressed. Nil once every other species is collected.
    public var nextUncollected: Species? {
        SpeciesCatalog.all.first { !state.collected.contains($0.id) && $0.id != state.plant.speciesID }
    }

    public var isGardenComplete: Bool {
        Set(state.collected).isSuperset(of: SpeciesCatalog.all.map(\.id))
    }

    public func hasWateredToday(now: Date) -> Bool {
        GrowthEngine.hasWateredToday(state.plant, now: now, calendar: calendar)
    }

    /// Streak is alive unless a full calendar day has passed with no watering
    /// (spec §3.2, derived at the UI rather than in the engine).
    public func isStreakAlive(now: Date) -> Bool {
        guard let last = state.plant.lastWateredAt else { return false }
        return (calendar.dayGap(from: last, to: now) ?? 99) <= 1
    }
}
