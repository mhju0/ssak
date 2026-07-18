import Foundation

/// What crafting a thing gives the player.
public enum CraftEffect: Equatable, Sendable {
    /// A fishing rod at this tier — the best owned tier is what fishing reads.
    case rodTier(Int)
    /// An artistry brush at this tier (used from M5).
    case brushTier(Int)
    /// A stackable crafted good added to inventory by id — repair kits (which
    /// restoration consumes), baskets, furniture, lanterns.
    case good(String)
}

/// A craftable tool, good, or furnishing (docs/design/unlock-tables.md §4).
/// Crafting consumes materials from the haul and never gates access — a better
/// rod adjusts feel and bite weights, it is never a wall (spec §2).
public struct Craftable: Identifiable, Equatable, Sendable {
    public let id: String
    public let nameEN: String
    public let nameKO: String
    public let unlockLevel: Int
    public let materials: [Ingredient]
    public let xp: Int
    public let effect: CraftEffect
    /// Stroke-recipe archetype (design metadata; recipes keyed by `id`).
    public let archetype: String

    public init(
        id: String, nameEN: String, nameKO: String, unlockLevel: Int,
        materials: [Ingredient], xp: Int, effect: CraftEffect, archetype: String
    ) {
        self.id = id
        self.nameEN = nameEN
        self.nameKO = nameKO
        self.unlockLevel = unlockLevel
        self.materials = materials
        self.xp = xp
        self.effect = effect
        self.archetype = archetype
    }
}

/// The crafting skill: which craftables the level has unlocked (affordability
/// is an inventory question, answered by the store).
public enum Crafting {
    public static func available(level: Int) -> [Craftable] {
        CraftingTable.all.filter { level >= $0.unlockLevel }
    }

    public static func craftable(id: String) -> Craftable? {
        CraftingTable.all.first { $0.id == id }
    }
}

/// The 10 M4 craftables, from docs/design/unlock-tables.md §4. Material lists
/// are drafted data — the hermit repurposes what they gather; the horsehair
/// brush from a catfish's whiskers is the honest one, the rest are loose.
public enum CraftingTable {
    public static let all: [Craftable] = [
        Craftable(
            id: "mend-rod", nameEN: "Mend the old rod", nameKO: "낡은 낚싯대 수선",
            unlockLevel: 1, materials: [Ingredient("mugwort", 2)],
            xp: 60, effect: .rodTier(1), archetype: "tool"),
        Craftable(
            id: "bamboo-rod", nameEN: "Bamboo rod", nameKO: "대나무 낚싯대",
            unlockLevel: 10, materials: [Ingredient("shepherds-purse", 3)],
            xp: 90, effect: .rodTier(2), archetype: "tool"),
        Craftable(
            id: "forage-basket", nameEN: "Forage basket", nameKO: "채집 바구니",
            unlockLevel: 20, materials: [Ingredient("mugwort", 2), Ingredient("shepherds-purse", 2)],
            xp: 110, effect: .good("forage-basket"), archetype: "furniture"),
        Craftable(
            id: "repair-kit", nameEN: "Repair kit", nameKO: "수리 도구",
            unlockLevel: 30, materials: [Ingredient("oyster-mushroom", 1), Ingredient("mugwort", 3)],
            xp: 120, effect: .good("repair-kit"), archetype: "tool"),
        Craftable(
            id: "horsehair-brush", nameEN: "Horsehair brush", nameKO: "붓",
            unlockLevel: 40, materials: [Ingredient("catfish", 1)],
            xp: 140, effect: .brushTier(1), archetype: "tool"),
        Craftable(
            id: "keepers-rod", nameEN: "Keeper's rod", nameKO: "은자의 낚싯대",
            unlockLevel: 50, materials: [Ingredient("pine-nuts", 2)],
            xp: 150, effect: .rodTier(3), archetype: "tool"),
        Craftable(
            id: "furniture-set", nameEN: "Furniture set", nameKO: "가구 세트",
            unlockLevel: 60, materials: [Ingredient("pine-nuts", 3)],
            xp: 160, effect: .good("furniture"), archetype: "furniture"),
        Craftable(
            id: "fine-brush", nameEN: "Fine brush", nameKO: "세필",
            unlockLevel: 70, materials: [Ingredient("eel", 1)],
            xp: 180, effect: .brushTier(2), archetype: "tool"),
        Craftable(
            id: "stone-lantern", nameEN: "Stone lantern", nameKO: "석등",
            unlockLevel: 80, materials: [Ingredient("pine-nuts", 2), Ingredient("persimmon", 2)],
            xp: 200, effect: .good("stone-lantern"), archetype: "furniture"),
        Craftable(
            id: "masters-rod", nameEN: "Master's rod", nameKO: "명인의 낚싯대",
            unlockLevel: 90, materials: [Ingredient("ink-carp", 1), Ingredient("pine-nuts", 3)],
            xp: 260, effect: .rodTier(4), archetype: "tool"),
    ]
}
