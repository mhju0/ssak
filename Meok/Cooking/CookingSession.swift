import Foundation
import GameKernel
import Persistence
import SkyState

extension Dish {
    var displayName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? nameKO : nameEN
    }
}

/// The kitchen loop: the dishes your level has unlocked, each showing whether
/// the pantry can afford it. Cook one → it's consumed for cooking XP and (for
/// a buff dish) a faster bite. No timers — cooking is instant (spec §2).
@MainActor
final class CookingSession: ObservableObject {
    struct IngredientStatus: Identifiable {
        let name: String
        let have: Int
        let need: Int
        var enough: Bool { have >= need }
        var id: String { name }
    }

    struct DishRow: Identifiable {
        let dish: Dish
        let affordable: Bool
        let ingredients: [IngredientStatus]
        var id: String { dish.id }
    }

    @Published private(set) var rows: [DishRow] = []
    @Published private(set) var level: Int
    @Published private(set) var lastCooked: Dish?
    @Published private(set) var lastReward: XPReward?

    weak var scene: CookScene?
    let autopilot: Bool
    private let store: GameStore

    init(store: GameStore, autopilot: Bool = false) {
        self.store = store
        self.autopilot = autopilot
        level = XPCurve.level(forXP: store.progress(for: .cooking).xp)
    }

    private var castLevel: Int {
        let override = UserDefaults.standard.integer(forKey: "meok-cook-level")
        return override > 0 ? override : level
    }

    func begin() {
        if autopilot { stockDemoPantry() }
        refresh()
    }

    func refresh() {
        rows = Cooking.available(level: castLevel).map { dish in
            let ingredients = dish.ingredients.map { ingredient in
                IngredientStatus(
                    name: Self.name(for: ingredient.item),
                    have: store.count(of: ingredient.item),
                    need: ingredient.count)
            }
            return DishRow(dish: dish, affordable: store.has(dish.ingredients), ingredients: ingredients)
        }
    }

    func cook(_ dish: Dish) {
        guard let reward = store.cook(dish, now: Date()) else { return }
        lastCooked = dish
        lastReward = reward
        level = reward.level
        scene?.showDish(archetype: dish.archetype)
        refresh()
    }

    /// A localized name for an ingredient id, resolved across the collectible
    /// tables (fish / forage / crop).
    private static func name(for id: String) -> String {
        let ko = Locale.current.language.languageCode?.identifier == "ko"
        if let fish = FishingTable.all.first(where: { $0.id == id }) { return ko ? fish.nameKO : fish.nameEN }
        if let forage = ForagingTable.all.first(where: { $0.id == id }) { return ko ? forage.nameKO : forage.nameEN }
        if let plant = GardenTable.all.first(where: { $0.id == id }) { return ko ? plant.nameKO : plant.nameEN }
        return id
    }

    // MARK: Harness

    private func stockDemoPantry() {
        for (item, n) in [
            ("crucian-carp", 2), ("catfish", 1), ("mugwort", 3),
            ("oyster-mushroom", 2), ("cabbage", 2),
        ] {
            store.add(item, count: n)
        }
    }

    func runDemoCook() {
        guard autopilot,
              let stew = rows.first(where: { $0.dish.id == "spicy-fish-stew" && $0.affordable })?.dish
        else { return }
        cook(stew)
    }
}
