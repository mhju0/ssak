import Foundation
import GameKernel
import Persistence
import SkyState
import StrokeEngine

extension Plantable {
    var displayName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? nameKO : nameEN
    }
}

/// The gardening loop: beds hold crops and trees; growth is real elapsed days
/// (spec §2). Plant a bed, water for a bonus, harvest a ripe crop. Trees stand
/// forever. Nothing withers — a garden left alone simply keeps growing.
@MainActor
final class GardenSession: ObservableObject {
    struct PlotRender: Identifiable {
        let index: Int
        let position: CGPoint    // unit fractions in the scene (x, y-up)
        let recipe: StrokeRecipe?  // nil = an empty bed
        let scale: CGFloat
        var id: Int { index }
    }

    /// What just happened, for the payoff line — the view maps it to text so
    /// the session stays UI-free.
    enum Event: Equatable {
        case planted(tree: Bool)
        case watered
        case alreadyWatered
        case harvested
    }

    @Published private(set) var plots: [PlotRender] = []
    @Published private(set) var level: Int
    @Published var selectedPlot: Int?
    @Published private(set) var lastReward: GrowthReward?
    @Published private(set) var lastEvent: Event?

    var conditions: WorldConditions
    weak var scene: GardenScene?
    let autopilot: Bool

    private let store: GameStore
    private var bedPlantings: [Int: Planting] = [:]

    private static let plotXs: [CGFloat] = [0.22, 0.42, 0.62, 0.82]
    private let plotY: CGFloat = 0.36

    init(
        conditions: WorldConditions, store: GameStore, autopilot: Bool = false
    ) {
        self.conditions = conditions
        self.store = store
        self.autopilot = autopilot
        level = XPCurve.level(forXP: store.progress(for: .gardening).xp)
    }

    private var castLevel: Int {
        let override = UserDefaults.standard.integer(forKey: "meok-garden-level")
        return override > 0 ? override : level
    }

    /// Real time, optionally fast-forwarded for the harness (`-meok-garden-days`).
    private var now: Date {
        let days = UserDefaults.standard.double(forKey: "meok-garden-days")
        return Date().addingTimeInterval(days * 86_400)
    }

    /// Beds unlock by level (spec §4: L1/L20/L40/L60).
    var bedCount: Int {
        1 + [20, 40, 60].filter { castLevel >= $0 }.count
    }

    var available: [Plantable] { Gardening.available(level: castLevel) }

    func begin() {
        if autopilot, store.plantings().isEmpty { seedDemo() }
        refresh()
    }

    func refresh() {
        bedPlantings = [:]
        for planting in store.plantings() where planting.bedIndex < bedCount {
            bedPlantings[planting.bedIndex] = planting
        }
        plots = (0..<bedCount).map { index in
            let render = bedPlantings[index].flatMap(render(for:))
            return PlotRender(
                index: index,
                position: CGPoint(x: Self.plotXs[index], y: plotY),
                recipe: render?.recipe, scale: render?.scale ?? 0)
        }
        scene?.layout(plots)
    }

    /// The growth stage picks the recipe and its scale — the seedling stands
    /// in for the early stages so growth never multiplies the art table.
    private func render(for planting: Planting) -> (recipe: StrokeRecipe, scale: CGFloat)? {
        guard let plantable = Gardening.plantable(id: planting.plantableID) else { return nil }
        let mature = Recipes.garden[plantable.id] ?? Recipes.gardenSeedling
        switch Garden.stage(plantedDays: planting.daysGrown(now: now), plantable) {
        case .seed: return (Recipes.gardenSeedling, 0.5)
        case .sprout: return (Recipes.gardenSeedling, 0.9)
        case .young: return (mature, 0.62)
        case .mature: return (mature, 1.0)
        case .ancient: return (mature, 1.2)
        }
    }

    // MARK: Selection

    func select(_ index: Int) {
        selectedPlot = index
        lastEvent = nil
        lastReward = nil
    }

    var selectedPlanting: Planting? { selectedPlot.flatMap { bedPlantings[$0] } }

    var selectedPlantable: Plantable? {
        selectedPlanting.flatMap { Gardening.plantable(id: $0.plantableID) }
    }

    var selectedIsRipe: Bool {
        guard let planting = selectedPlanting, let plantable = selectedPlantable else { return false }
        return Garden.isReady(plantedDays: planting.daysGrown(now: now), plantable)
    }

    // MARK: Actions

    func plant(_ plantable: Plantable) {
        guard let index = selectedPlot, bedPlantings[index] == nil else { return }
        apply(store.plant(plantable, at: index, now: now), event: .planted(tree: plantable.isTree))
        refresh()
    }

    func waterSelected() {
        guard let planting = selectedPlanting else { return }
        guard let reward = store.water(planting, now: now) else {
            lastEvent = .alreadyWatered
            lastReward = nil
            return
        }
        apply(reward, event: .watered)
        scene?.flourish(at: planting.bedIndex)
    }

    func harvestSelected() {
        guard let planting = selectedPlanting else { return }
        guard let reward = store.harvest(planting, now: now) else { return }
        apply(reward, event: .harvested)
        refresh()
    }

    private func apply(_ reward: GrowthReward, event: Event) {
        lastReward = reward
        lastEvent = event
        level = reward.level
    }

    /// The harness plays itself: a spread of ages so the beds show growth.
    private func seedDemo() {
        let base = now
        _ = store.plant(GardenTable.all[0], at: 0, now: base.addingTimeInterval(-4 * 86_400)) // radish, ripe
        if bedCount > 1 {
            _ = store.plant(GardenTable.all[1], at: 1, now: base.addingTimeInterval(-3.5 * 86_400)) // cabbage, young
        }
        if bedCount > 2 {
            _ = store.plant(GardenTable.all[2], at: 2, now: base.addingTimeInterval(-40 * 86_400)) // plum, mature
        }
    }
}
