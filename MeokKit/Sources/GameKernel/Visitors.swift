import Foundation

/// The three v1 visitors (spec §2). Roster grows post-launch.
public enum VisitorID: String, Sendable, CaseIterable {
    case oldFisherman, dokkaebi, peddler
}

public struct Visitor: Identifiable, Equatable, Sendable {
    public let id: VisitorID
    public let nameEN: String
    public let nameKO: String
}

/// What a barter gives back (no currency — spec §2). A species enters the
/// ledger (the peddler's climate valve); a good goes to inventory.
public enum TradeReward: Equatable, Sendable {
    case species(String)
    case good(String)
}

/// One barter: hand over `give`, receive `get`.
public struct TradeOffer: Identifiable, Equatable, Sendable {
    public let id: String
    public let give: Ingredient
    public let get: TradeReward

    public init(id: String, give: Ingredient, get: TradeReward) {
        self.id = id
        self.give = give
        self.get = get
    }
}

public enum Visitors {
    public static let all: [Visitor] = [
        Visitor(id: .oldFisherman, nameEN: "The old fisherman", nameKO: "늙은 어부"),
        Visitor(id: .dokkaebi, nameEN: "The dokkaebi", nameKO: "도깨비"),
        Visitor(id: .peddler, nameEN: "The traveling peddler", nameKO: "방물장수"),
    ]

    public static func visitor(_ id: VisitorID) -> Visitor {
        all.first { $0.id == id }!
    }

    /// Who's visiting under this sky. The old fisherman comes on morning rain,
    /// the dokkaebi on storm nights; those weather cues outrank the peddler,
    /// who arrives on a seasonal roll the app decides (`peddlerToday`).
    public static func present(_ conditions: WorldConditions, peddlerToday: Bool) -> Visitor? {
        if conditions.timeOfDay == .dawn, conditions.weather == .rain { return visitor(.oldFisherman) }
        if conditions.timeOfDay == .night, conditions.weather == .storm { return visitor(.dokkaebi) }
        if peddlerToday { return visitor(.peddler) }
        return nil
    }

    /// A visitor's barters. The peddler's are the **climate valve** — species
    /// the player's sky can't produce, carried in for materials (spec §2), so
    /// completionists everywhere have a slow path to the full ledger.
    public static func offers(
        for visitor: VisitorID, climate: Set<WorldConditions.Weather>
    ) -> [TradeOffer] {
        switch visitor {
        case .oldFisherman:
            return [TradeOffer(id: "fisherman-eel", give: Ingredient("crucian-carp", 2), get: .species("eel"))]
        case .dokkaebi:
            return [TradeOffer(id: "dokkaebi-ink-carp", give: Ingredient("persimmon", 3), get: .species("ink-carp"))]
        case .peddler:
            let collectibles = FishingTable.all.map { ($0.id, $0.weathers) }
                + ForagingTable.all.map { ($0.id, $0.weathers) }
            return collectibles
                .filter { $0.1.isDisjoint(with: climate) }   // climate-locked here
                .map { id, _ in
                    TradeOffer(id: "peddler-\(id)", give: Ingredient("pine-nuts", 2), get: .species(id))
                }
        }
    }
}
