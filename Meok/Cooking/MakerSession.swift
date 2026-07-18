import Foundation
import GameKernel
import Persistence
import StrokeEngine

/// A one-line effect note the view localizes (kept UI-free here).
enum MakerNote: Equatable {
    case buff(minutes: Int)
    case betterRod
    case finerBrush
}

/// Something made from ingredients — a dish or a craftable. The kitchen and
/// the workbench are the same menu shape, so they share one session/view.
protocol Makeable {
    var id: String { get }
    var displayName: String { get }
    var unlockLevel: Int { get }
    var ingredients: [Ingredient] { get }
    var archetype: String { get }
    var note: MakerNote? { get }
}

extension Dish: Makeable {
    var displayName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? nameKO : nameEN
    }
    var note: MakerNote? { buff != nil ? .buff(minutes: Int(buffMinutes)) : nil }
}

extension Craftable: Makeable {
    var displayName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? nameKO : nameEN
    }
    var ingredients: [Ingredient] { materials }
    var note: MakerNote? {
        switch effect {
        case .rodTier: .betterRod
        case .brushTier: .finerBrush
        case .good: nil
        }
    }
}

/// The kitchen / workbench loop: the recipes your level has unlocked, each with
/// live have/need counts; make one and it's consumed for XP (and an effect).
/// Instant — no timers (spec §2). `Kind` drives everything skill-specific.
@MainActor
final class MakerSession: ObservableObject {
    enum Kind {
        case cooking, crafting

        var skill: Skill { self == .cooking ? .cooking : .crafting }
        var levelKey: String { self == .cooking ? "meok-cook-level" : "meok-craft-level" }
        var demoArg: String { self == .cooking ? "-meok-cook-demo" : "-meok-craft-demo" }
        var art: [String: StrokeRecipe] { self == .cooking ? Recipes.dishArt : Recipes.craftArt }

        func available(level: Int) -> [any Makeable] {
            self == .cooking ? Cooking.available(level: level) : Crafting.available(level: level)
        }

        var demoStock: [(String, Int)] {
            self == .cooking
                ? [("crucian-carp", 2), ("catfish", 1), ("mugwort", 3), ("oyster-mushroom", 2), ("cabbage", 2)]
                : [("mugwort", 3), ("shepherds-purse", 3), ("pine-nuts", 2), ("catfish", 1)]
        }
        var demoItemID: String { self == .cooking ? "spicy-fish-stew" : "bamboo-rod" }
    }

    struct IngredientStatus: Identifiable {
        let name: String
        let have: Int
        let need: Int
        var enough: Bool { have >= need }
        var id: String { name }
    }

    struct Row: Identifiable {
        let item: any Makeable
        let affordable: Bool
        let ingredients: [IngredientStatus]
        var id: String { item.id }
    }

    @Published private(set) var rows: [Row] = []
    @Published private(set) var level: Int
    @Published private(set) var lastMade: (any Makeable)?
    @Published private(set) var lastReward: XPReward?

    let kind: Kind
    weak var scene: MakerScene?
    let autopilot: Bool
    private let store: GameStore

    init(store: GameStore, kind: Kind) {
        self.store = store
        self.kind = kind
        autopilot = ProcessInfo.processInfo.arguments.contains(kind.demoArg)
        level = XPCurve.level(forXP: store.progress(for: kind.skill).xp)
    }

    private var castLevel: Int {
        let override = UserDefaults.standard.integer(forKey: kind.levelKey)
        return override > 0 ? override : level
    }

    func begin() {
        if autopilot {
            for (item, count) in kind.demoStock { store.add(item, count: count) }
        }
        refresh()
    }

    func refresh() {
        rows = kind.available(level: castLevel).map { item in
            let statuses = item.ingredients.map { ingredient in
                IngredientStatus(
                    name: Self.name(for: ingredient.item),
                    have: store.count(of: ingredient.item),
                    need: ingredient.count)
            }
            return Row(item: item, affordable: store.has(item.ingredients), ingredients: statuses)
        }
    }

    func make(_ item: any Makeable) {
        let reward: XPReward?
        switch kind {
        case .cooking: reward = (item as? Dish).flatMap { store.cook($0, now: Date()) }
        case .crafting: reward = (item as? Craftable).flatMap { store.craft($0) }
        }
        guard let reward else { return }
        lastMade = item
        lastReward = reward
        level = reward.level
        scene?.showItem(archetype: item.archetype)
        refresh()
    }

    func runDemo() {
        guard autopilot else { return }
        // The showcase item if it's reachable, else just the first affordable
        // row — so the demo paints something even without a level override.
        let item = rows.first { $0.item.id == kind.demoItemID && $0.affordable }?.item
            ?? rows.first { $0.affordable }?.item
        if let item { make(item) }
    }

    private static func name(for id: String) -> String {
        let ko = Locale.current.language.languageCode?.identifier == "ko"
        if let fish = FishingTable.all.first(where: { $0.id == id }) { return ko ? fish.nameKO : fish.nameEN }
        if let forage = ForagingTable.all.first(where: { $0.id == id }) { return ko ? forage.nameKO : forage.nameEN }
        if let plant = GardenTable.all.first(where: { $0.id == id }) { return ko ? plant.nameKO : plant.nameEN }
        return id
    }
}
