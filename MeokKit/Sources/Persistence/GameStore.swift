import Foundation
import SwiftData
import GameKernel

/// Lifetime XP for one skill. XP is monotonic — rows only ever grow
/// (the invariant the v1.1 iCloud merge design leans on).
/// Note: `.unique` is incompatible with SwiftData's CloudKit mirroring —
/// fine at v1 (local-only by spec §4); the v1.1 sync design replaces this
/// model shape anyway (append-only events or per-device rows).
@Model
public final class SkillProgress {
    @Attribute(.unique) public var skillID: String
    public var xp: Int

    public init(skillID: String, xp: Int = 0) {
        self.skillID = skillID
        self.xp = xp
    }
}

/// Collection state for one species. Variant sets are the weather
/// dimension only (spec §2), stored as raw values for schema stability.
@Model
public final class SpeciesRecord {
    @Attribute(.unique) public var speciesID: String
    public var timesCaught: Int
    public var caughtWeathers: [String]
    public var paintedWeathers: [String]
    /// The shadow "one that got away" flag — collection intel, not failure.
    public var gotAway: Bool

    public init(speciesID: String) {
        self.speciesID = speciesID
        timesCaught = 0
        caughtWeathers = []
        paintedWeathers = []
        gotAway = false
    }
}

/// One thing growing in a garden bed. Growth is derived from `plantedAt` vs
/// now — never stored, so it can't drift or regress (spec §2, pillar 2).
/// Trees are planted forever; crops are removed when harvested.
@Model
public final class Planting {
    public var plantableID: String
    public var plantedAt: Date
    public var bedIndex: Int
    /// Last hand/rain watering — bounds the bonus tick to once per real day.
    public var lastWatered: Date?

    public init(plantableID: String, plantedAt: Date, bedIndex: Int) {
        self.plantableID = plantableID
        self.plantedAt = plantedAt
        self.bedIndex = bedIndex
        lastWatered = nil
    }

    public func daysGrown(now: Date) -> Double {
        max(0, now.timeIntervalSince(plantedAt)) / 86_400
    }

    /// Watered at most once per real day — a delight, never an obligation.
    public func canWater(now: Date) -> Bool {
        guard let lastWatered else { return true }
        return now.timeIntervalSince(lastWatered) >= 20 * 3_600
    }
}

/// On-hand stock of one collectible or material — the consumable inventory
/// (spec §4). Catches and gathers add to it; cooking, crafting, and
/// restoration consume from it. Distinct from `SpeciesRecord` (the lifetime
/// ledger), which never depletes.
@Model
public final class InventoryItem {
    @Attribute(.unique) public var itemID: String
    public var count: Int

    public init(itemID: String, count: Int = 0) {
        self.itemID = itemID
        self.count = count
    }
}

/// A meal buff running down (spec §2). Expiry is a wall-clock date, so a buff
/// simply lapses with real time — open app or closed, no ticking to persist.
@Model
public final class ActiveBuff {
    @Attribute(.unique) public var kind: String
    public var expiresAt: Date

    public init(kind: String, expiresAt: Date) {
        self.kind = kind
        self.expiresAt = expiresAt
    }
}

/// A hermitage room's restoration state (spec §4). Ruined until restored with
/// crafted goods; a restored room unlocks its function (kitchen → cooking).
@Model
public final class HermitageRoom {
    @Attribute(.unique) public var roomID: String
    public var restored: Bool

    public init(roomID: String, restored: Bool = false) {
        self.roomID = roomID
        self.restored = restored
    }
}

/// A finished painting (spec §4): its composition, a snapshot of the sky it
/// baked in, and whether the red seal was stamped. The scene re-renders from
/// this deterministically — no stored PNG at v1 (share-sheet export is M7/M8).
@Model
public final class Painting {
    public var compositionID: String
    public var weather: String
    public var season: String
    public var timeOfDay: String
    public var sealed: Bool
    public var createdAt: Date

    public init(
        compositionID: String, weather: String, season: String,
        timeOfDay: String, sealed: Bool, createdAt: Date
    ) {
        self.compositionID = compositionID
        self.weather = weather
        self.season = season
        self.timeOfDay = timeOfDay
        self.sealed = sealed
        self.createdAt = createdAt
    }
}

/// What one haul did to the ledgers — an activity view's payoff line. Shared
/// by fishing catches and foraging finds (spec §2: "haul feeds crafting").
public struct HaulOutcome: Equatable, Sendable {
    public let xpAwarded: Int
    public let totalXP: Int
    public let level: Int
    public let leveledUp: Bool
    public let firstOfSpecies: Bool
    public let newWeatherVariant: Bool
}

/// What a skill act (plant, water, harvest, cook, craft…) awarded — the XP,
/// the resulting level, and whether it leveled up.
public struct XPReward: Equatable, Sendable {
    public let xpAwarded: Int
    public let level: Int
    public let leveledUp: Bool
}

/// The one door to the save file. All game writes go through here so the
/// XP-monotonic and variant-set rules live in exactly one place.
@MainActor
public final class GameStore {
    public let context: ModelContext

    public init(container: ModelContainer) {
        context = ModelContext(container)
    }

    /// The app's on-disk store.
    public static func live() throws -> GameStore {
        try GameStore(container: ModelContainer(
            for: SkillProgress.self, SpeciesRecord.self, Planting.self, InventoryItem.self, ActiveBuff.self, HermitageRoom.self, Painting.self))
    }

    /// Throwaway store for tests and previews.
    public static func inMemory() throws -> GameStore {
        try GameStore(container: ModelContainer(
            for: SkillProgress.self, SpeciesRecord.self, Planting.self, InventoryItem.self, ActiveBuff.self, HermitageRoom.self, Painting.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    }

    public func progress(for skill: Skill) -> SkillProgress {
        let id = skill.rawValue
        var descriptor = FetchDescriptor<SkillProgress>(
            predicate: #Predicate { $0.skillID == id })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first { return existing }
        let fresh = SkillProgress(skillID: id)
        context.insert(fresh)
        return fresh
    }

    public func record(for speciesID: String) -> SpeciesRecord? {
        var descriptor = FetchDescriptor<SpeciesRecord>(
            predicate: #Predicate { $0.speciesID == speciesID })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func recordCreatingIfNeeded(for speciesID: String) -> SpeciesRecord {
        if let existing = record(for: speciesID) { return existing }
        let fresh = SpeciesRecord(speciesID: speciesID)
        context.insert(fresh)
        return fresh
    }

    /// A landed fish: XP ticks, the ledger fills, variants accrue.
    public func record(
        catch species: FishSpecies, weather: WorldConditions.Weather
    ) -> HaulOutcome {
        award(.fishing, collectibleID: species.id, xp: species.xp, weather: weather)
    }

    /// A gathered forageable: the same ledger machinery, foraging XP.
    public func record(
        gather forageable: Forageable, weather: WorldConditions.Weather
    ) -> HaulOutcome {
        award(.foraging, collectibleID: forageable.id, xp: forageable.xp, weather: weather)
    }

    /// The one place XP ticks and a SpeciesRecord fills — shared by every
    /// gathering skill so the monotonic-XP and variant-set rules live once.
    private func award(
        _ skill: Skill, collectibleID: String, xp: Int, weather: WorldConditions.Weather
    ) -> HaulOutcome {
        let progress = progress(for: skill)
        let levelBefore = XPCurve.level(forXP: progress.xp)
        progress.xp += xp
        let levelAfter = XPCurve.level(forXP: progress.xp)

        let record = recordCreatingIfNeeded(for: collectibleID)
        let firstEver = record.timesCaught == 0
        record.timesCaught += 1
        let newVariant = !record.caughtWeathers.contains(weather.rawValue)
        if newVariant { record.caughtWeathers.append(weather.rawValue) }

        stock(collectibleID, 1)   // the haul also becomes a cooking/crafting ingredient
        save()
        return HaulOutcome(
            xpAwarded: xp,
            totalXP: progress.xp,
            level: levelAfter,
            leveledUp: levelAfter > levelBefore,
            firstOfSpecies: firstEver,
            newWeatherVariant: newVariant)
    }

    /// A lost fish costs only the moment — and logs the silhouette.
    public func recordEscape(of species: FishSpecies) {
        recordCreatingIfNeeded(for: species.id).gotAway = true
        save()
    }

    // MARK: Gardening — growth is real days; watering is a bonus (spec §2)

    public func plantings() -> [Planting] {
        (try? context.fetch(FetchDescriptor<Planting>(
            sortBy: [SortDescriptor(\.bedIndex)]))) ?? []
    }

    /// Plant a crop or tree in a bed. A tree's yield is the planting itself
    /// (it stands forever); a crop yields later, at harvest. Returns the XP
    /// reward, like water/harvest (the row is reachable via `plantings()`).
    @discardableResult
    public func plant(_ plantable: Plantable, at bedIndex: Int, now: Date) -> XPReward {
        context.insert(Planting(plantableID: plantable.id, plantedAt: now, bedIndex: bedIndex))
        let reward = addXP(.gardening, plantable.isTree ? plantable.xp : Self.plantXP)
        save()
        return reward
    }

    /// Harvest a ripe crop: its yield in XP, and the bed clears. Trees and
    /// unripe crops harvest nothing.
    public func harvest(_ planting: Planting, now: Date) -> XPReward? {
        guard let plantable = Gardening.plantable(id: planting.plantableID),
              Garden.isReady(plantedDays: planting.daysGrown(now: now), plantable)
        else { return nil }
        let reward = addXP(.gardening, plantable.xp)
        stock(plantable.id, 1)   // the harvest goes to the pantry (an ingredient)
        context.delete(planting)
        save()
        return reward
    }

    /// Water a plant by hand — a small XP tick, at most once per real day
    /// (real rain waters for free). Returns nil if already watered today.
    @discardableResult
    public func water(_ planting: Planting, now: Date) -> XPReward? {
        guard planting.canWater(now: now) else { return nil }
        planting.lastWatered = now
        let reward = addXP(.gardening, Self.waterXP)
        save()
        return reward
    }

    private static let plantXP = 15
    private static let waterXP = 10

    /// Tick a skill's XP and report the reward — shared by gardening, cooking,
    /// and crafting. Does not save; callers batch their save.
    private func addXP(_ skill: Skill, _ xp: Int) -> XPReward {
        let progress = progress(for: skill)
        let before = XPCurve.level(forXP: progress.xp)
        progress.xp += xp
        let after = XPCurve.level(forXP: progress.xp)
        return XPReward(xpAwarded: xp, level: after, leveledUp: after > before)
    }

    // MARK: Cooking — a meal from the haul (spec §2)

    /// Cook a dish if its ingredients are on hand: consume them, tick cooking
    /// XP, and (for a buff dish) start its buff. nil when the pantry is short.
    public func cook(_ dish: Dish, now: Date) -> XPReward? {
        guard take(dish.ingredients) else { return nil }
        let reward = addXP(.cooking, dish.xp)
        if let buff = dish.buff { extendBuff(buff, minutes: dish.buffMinutes, now: now) }
        save()
        return reward
    }

    /// Is a meal buff still running? (Fishing reads this to speed the bite.)
    public func isActive(_ buff: MealBuff, now: Date) -> Bool {
        (buffRow(buff)?.expiresAt).map { $0 > now } ?? false
    }

    /// Extend a buff to at least now + minutes — a longer meal never shortens
    /// an active buff. No save; the caller (cook) saves.
    private func extendBuff(_ buff: MealBuff, minutes: Double, now: Date) {
        let expiry = now.addingTimeInterval(minutes * 60)
        if let existing = buffRow(buff) {
            existing.expiresAt = max(existing.expiresAt, expiry)
        } else {
            context.insert(ActiveBuff(kind: buff.rawValue, expiresAt: expiry))
        }
    }

    private func buffRow(_ buff: MealBuff) -> ActiveBuff? {
        let kind = buff.rawValue
        var descriptor = FetchDescriptor<ActiveBuff>(predicate: #Predicate { $0.kind == kind })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    // MARK: Crafting — tools and goods from the haul (spec §2)

    /// Craft a thing if its materials are on hand: consume them, tick crafting
    /// XP, and apply the effect (raise a tool tier, or stock a good). nil when
    /// materials are short.
    public func craft(_ craftable: Craftable) -> XPReward? {
        guard take(craftable.materials) else { return nil }
        let reward = addXP(.crafting, craftable.xp)
        switch craftable.effect {
        case .rodTier(let tier): raiseTool(Self.rodKey, to: tier)
        case .brushTier(let tier): raiseTool(Self.brushKey, to: tier)
        case .good(let id): stock(id, 1)
        }
        save()
        return reward
    }

    /// The best rod owned (0 = none); fishing reads it. Brush is for M5.
    public func rodTier() -> Int { count(of: Self.rodKey) }
    public func brushTier() -> Int { count(of: Self.brushKey) }

    private static let rodKey = "tool.rod"
    private static let brushKey = "tool.brush"

    /// A crafted tool only ever upgrades — a lesser one never downgrades it.
    private func raiseTool(_ key: String, to tier: Int) {
        if let existing = item(key) {
            existing.count = max(existing.count, tier)
        } else {
            context.insert(InventoryItem(itemID: key, count: tier))
        }
    }

    // MARK: Restoration — the hermitage, room by room (spec §2)

    public func restoredRooms() -> Set<String> {
        let rows = (try? context.fetch(FetchDescriptor<HermitageRoom>(
            predicate: #Predicate { $0.restored }))) ?? []
        return Set(rows.map(\.roomID))
    }

    public func isRestored(_ roomID: String) -> Bool {
        roomRow(roomID)?.restored ?? false
    }

    /// Restore a room by spending its crafted-goods cost. false if already
    /// restored or the goods aren't on hand (then nothing is consumed).
    @discardableResult
    public func restore(_ room: Room) -> Bool {
        guard !isRestored(room.id), take(room.cost) else { return false }
        if let existing = roomRow(room.id) {
            existing.restored = true
        } else {
            context.insert(HermitageRoom(roomID: room.id, restored: true))
        }
        save()
        return true
    }

    private func roomRow(_ roomID: String) -> HermitageRoom? {
        var descriptor = FetchDescriptor<HermitageRoom>(predicate: #Predicate { $0.roomID == roomID })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    // MARK: Artistry — paint the live scene (spec §2)

    /// Every painting, newest first — the gallery walls.
    public func paintings() -> [Painting] {
        (try? context.fetch(FetchDescriptor<Painting>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
    }

    /// The weather variants painted for a composition — gallery completion.
    public func paintedVariants(of compositionID: String) -> Set<String> {
        Set(paintings().filter { $0.compositionID == compositionID }.map(\.weather))
    }

    /// Finish a painting: hang the work (composition + the sky it baked in +
    /// seal state) and tick artistry XP.
    @discardableResult
    public func record(
        painting composition: Composition, conditions: WorldConditions,
        sealed: Bool, now: Date
    ) -> XPReward {
        context.insert(Painting(
            compositionID: composition.id,
            weather: conditions.weather.rawValue,
            season: conditions.season.rawValue,
            timeOfDay: conditions.timeOfDay.rawValue,
            sealed: sealed,
            createdAt: now))
        let reward = addXP(.artistry, composition.xp)
        save()
        return reward
    }

    // MARK: Inventory — the consumable stock (spec §4)

    public func count(of itemID: String) -> Int {
        item(itemID)?.count ?? 0
    }

    /// True only if every ingredient is on hand in the required amount. A
    /// recipe may list the same id twice, so needs are summed first.
    public func has(_ ingredients: [Ingredient]) -> Bool {
        aggregate(ingredients).allSatisfy { count(of: $0.key) >= $0.value }
    }

    public func add(_ itemID: String, count: Int = 1) {
        stock(itemID, count)
        save()
    }

    /// Consume a stack if enough is on hand; a shortfall changes nothing.
    @discardableResult
    public func consume(_ itemID: String, count: Int) -> Bool {
        guard let existing = item(itemID), existing.count >= count else { return false }
        existing.count -= count
        save()
        return true
    }

    /// Consume a whole ingredient list atomically — all or nothing.
    @discardableResult
    public func consume(_ ingredients: [Ingredient]) -> Bool {
        guard take(ingredients) else { return false }
        save()
        return true
    }

    /// Deduct an ingredient list without saving — for actions (cook/craft/
    /// restore) that then tick XP and save once. Atomic: all or nothing, and
    /// duplicate ids are summed so stock can never over-consume into negatives.
    private func take(_ ingredients: [Ingredient]) -> Bool {
        let needed = aggregate(ingredients)
        guard needed.allSatisfy({ count(of: $0.key) >= $0.value }) else { return false }
        for (id, amount) in needed { item(id)?.count -= amount }
        return true
    }

    /// Sum an ingredient list by id.
    private func aggregate(_ ingredients: [Ingredient]) -> [String: Int] {
        ingredients.reduce(into: [:]) { $0[$1.item, default: 0] += $1.count }
    }

    private func item(_ itemID: String) -> InventoryItem? {
        var descriptor = FetchDescriptor<InventoryItem>(
            predicate: #Predicate { $0.itemID == itemID })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Add stock without saving — callers that already save (award) use this.
    private func stock(_ itemID: String, _ count: Int) {
        if let existing = item(itemID) {
            existing.count += count
        } else {
            context.insert(InventoryItem(itemID: itemID, count: count))
        }
    }

    /// A local-only save failing (disk full) is exceptional; the in-memory
    /// context stays authoritative for the session either way, but never
    /// swallow it silently — XP is supposed to be monotonic on disk too.
    private func save() {
        do {
            try context.save()
        } catch {
            assertionFailure("GameStore save failed: \(error)")
            print("GameStore save failed: \(error)")
        }
    }
}
