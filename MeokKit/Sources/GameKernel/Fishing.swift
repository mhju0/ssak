import Foundation

/// One event in a species' bite signature. The bobber's on-screen tremble
/// and the audio tick both render this same envelope — one source, two
/// mirrors (spec §2 accessibility). `sharpness` shapes the audio's pitch and
/// the tremble's snap.
public struct BiteTap: Equatable, Sendable {
    /// Seconds from the start of the signature.
    public let offset: Double
    public let intensity: Double
    public let sharpness: Double
    public let duration: Double

    public init(offset: Double, intensity: Double, sharpness: Double, duration: Double) {
        self.offset = offset
        self.intensity = intensity
        self.sharpness = sharpness
        self.duration = duration
    }
}

/// A fishing species row from docs/design/unlock-tables.md §5. The
/// `weathers` set is also the species' weather-variant set (spec §2:
/// variants are the weather dimension only).
public struct FishSpecies: Identifiable, Equatable, Sendable, ConditionGated {
    public let id: String
    public let nameEN: String
    public let nameKO: String
    public let tier: Tier
    public let unlockLevel: Int
    public let seasons: Set<WorldConditions.Season>
    public let timesOfDay: Set<WorldConditions.TimeOfDay>
    public let weathers: Set<WorldConditions.Weather>
    public let xp: Int
    /// Relative spawn weight among currently eligible species.
    public let weight: Int
    public let bitePattern: [BiteTap]
    /// Shape-family archetype (the §3 art-budget grouping) — recipes are
    /// keyed by `id`, not this; it's design metadata.
    public let archetype: String

    /// Rare and apex tiers add the ~10 s tension dance.
    public var triggersFight: Bool { tier == .rare || tier == .apex }

    // Eligibility is the shared `ConditionGated` rule (see Conditions.swift).
}

/// Bite mechanics constants (docs/design/unlock-tables.md §7).
public enum FishingRules {
    /// Seconds the player has to strike after the signature completes.
    public static let strikeWindow = 1.2
    /// Length of the rare/apex tension dance, seconds.
    public static let fightDuration = 10.0
    /// Seconds from cast to bite.
    public static let biteDelay = 5.0...20.0
    /// A meal's bite-rate buff scales the bite delay (0.6 = 40 % faster).
    public static let buffedBiteScale = 0.6

    /// A crafted rod's tier raises rare/apex bite weight (spec §4: bamboo rod
    /// up, master's rod most). Tier 0–1 is the mended starter — no boost.
    public static func rareBoost(forRodTier tier: Int) -> Double {
        switch tier {
        case ..<2: return 1
        case 2: return 1.5
        case 3: return 1.8
        default: return 2.2
        }
    }

    /// A better rod also tolerates more strain in the fight (spec §4: the
    /// keeper's rod eases it). Tier 0–2 keeps the base three-strain limit.
    public static func strainLimit(forRodTier tier: Int) -> Int {
        3 + max(0, tier - 2)
    }
}

public struct Bite: Equatable, Sendable {
    public let species: FishSpecies
    /// Seconds from cast until the signature starts.
    public let delay: Double
}

/// The fishing half of the content engine (spec §4): pure functions from
/// (WorldConditions, level, seed) to what the pond offers. The eligible +
/// weighted-pick core is shared (`ConditionDraw`); fishing adds the bite delay.
public enum ConditionEngine {
    public static func eligibleSpecies(
        _ conditions: WorldConditions, level: Int
    ) -> [FishSpecies] {
        ConditionDraw.eligible(FishingTable.all, conditions, level: level)
    }

    /// Weighted draw over the eligible pool plus a bite delay. Baseline
    /// tier draws the delay twice and keeps the shorter — beginners' fish
    /// come easier without touching the weights. `biteDelayScale` < 1 is a
    /// meal buff (a faster bite); the caller supplies it from active buffs.
    public static func nextBite<R: RandomNumberGenerator>(
        _ conditions: WorldConditions, level: Int,
        biteDelayScale: Double = 1, rareWeightBoost: Double = 1, using rng: inout R
    ) -> Bite? {
        let pool = eligibleSpecies(conditions, level: level)
        // A better rod raises rare/apex bite weight (spec §4). boost 1 leaves
        // every weight unchanged, so the default draw is byte-identical.
        guard let species = ConditionDraw.weightedPick(from: pool, weight: { fish in
            fish.triggersFight
                ? max(1, Int((Double(fish.weight) * rareWeightBoost).rounded()))
                : fish.weight
        }, using: &rng) else { return nil }

        var delay = Double.random(in: FishingRules.biteDelay, using: &rng)
        if species.tier == .baseline {
            delay = min(delay, Double.random(in: FishingRules.biteDelay, using: &rng))
        }
        return Bite(species: species, delay: delay * biteDelayScale)
    }
}

/// The 11 M2 rows, verbatim from docs/design/unlock-tables.md §5.
public enum FishingTable {
    private static let allSeasons = Set(WorldConditions.Season.allCases)
    private static let allTimes = Set(WorldConditions.TimeOfDay.allCases)
    private static let allWeathers = Set(WorldConditions.Weather.allCases)

    public static let all: [FishSpecies] = [
        FishSpecies(
            id: "crucian-carp", nameEN: "Crucian carp", nameKO: "붕어",
            tier: .baseline, unlockLevel: 1,
            seasons: allSeasons, timesOfDay: allTimes, weathers: allWeathers,
            xp: 60, weight: 100,
            bitePattern: [
                BiteTap(offset: 0, intensity: 0.35, sharpness: 0.7, duration: 0.05),
                BiteTap(offset: 0.3, intensity: 0.35, sharpness: 0.7, duration: 0.05),
                BiteTap(offset: 1.0, intensity: 1.0, sharpness: 0.9, duration: 0.18),
            ],
            archetype: "carp-shape"),
        FishSpecies(
            id: "common-carp", nameEN: "Common carp", nameKO: "잉어",
            tier: .uncommon, unlockLevel: 1,
            seasons: allSeasons, timesOfDay: allTimes, weathers: allWeathers,
            xp: 90, weight: 45,
            bitePattern: [
                BiteTap(offset: 0, intensity: 0.25, sharpness: 0.2, duration: 0.4),
                BiteTap(offset: 0.5, intensity: 0.55, sharpness: 0.25, duration: 0.5),
                BiteTap(offset: 1.1, intensity: 0.9, sharpness: 0.35, duration: 0.7),
            ],
            archetype: "carp-shape"),
        FishSpecies(
            id: "pale-chub", nameEN: "Pale chub", nameKO: "피라미",
            tier: .baseline, unlockLevel: 1,
            seasons: allSeasons, timesOfDay: [.day], weathers: [.clear, .cloudy],
            xp: 45, weight: 80,
            bitePattern: [
                BiteTap(offset: 0, intensity: 0.3, sharpness: 0.9, duration: 0.03),
                BiteTap(offset: 0.12, intensity: 0.3, sharpness: 0.9, duration: 0.03),
                BiteTap(offset: 0.24, intensity: 0.3, sharpness: 0.9, duration: 0.03),
                BiteTap(offset: 0.5, intensity: 0.8, sharpness: 0.95, duration: 0.08),
            ],
            archetype: "small-fry"),
        FishSpecies(
            id: "catfish", nameEN: "Catfish", nameKO: "메기",
            tier: .uncommon, unlockLevel: 10,
            seasons: allSeasons, timesOfDay: [.night], weathers: allWeathers,
            xp: 100, weight: 40,
            bitePattern: [
                BiteTap(offset: 0, intensity: 0.9, sharpness: 0.15, duration: 0.25),
                BiteTap(offset: 0.7, intensity: 1.0, sharpness: 0.15, duration: 0.3),
            ],
            archetype: "whisker-shape"),
        FishSpecies(
            id: "eel", nameEN: "Eel", nameKO: "뱀장어",
            tier: .uncommon, unlockLevel: 20,
            seasons: [.spring, .summer, .autumn], timesOfDay: [.night],
            weathers: [.rain, .storm],
            xp: 120, weight: 35,
            bitePattern: [
                BiteTap(offset: 0, intensity: 0.4, sharpness: 0.5, duration: 1.2),
                BiteTap(offset: 1.4, intensity: 0.85, sharpness: 0.6, duration: 0.4),
            ],
            archetype: "slender-shape"),
        FishSpecies(
            id: "mandarin-fish", nameEN: "Mandarin fish", nameKO: "쏘가리",
            tier: .uncommon, unlockLevel: 30,
            seasons: [.summer], timesOfDay: [.day, .dusk], weathers: [.clear, .cloudy],
            xp: 120, weight: 35,
            bitePattern: [
                BiteTap(offset: 0, intensity: 1.0, sharpness: 0.95, duration: 0.08),
                BiteTap(offset: 0.35, intensity: 1.0, sharpness: 0.95, duration: 0.08),
            ],
            archetype: "carp-shape"),
        FishSpecies(
            id: "snakehead", nameEN: "Snakehead", nameKO: "가물치",
            tier: .rare, unlockLevel: 40,
            seasons: [.summer], timesOfDay: allTimes, weathers: allWeathers,
            xp: 150, weight: 18,
            bitePattern: [
                BiteTap(offset: 0, intensity: 0.6, sharpness: 0.8, duration: 0.1),
                BiteTap(offset: 0.2, intensity: 1.0, sharpness: 0.9, duration: 0.6),
            ],
            archetype: "slender-shape"),
        FishSpecies(
            id: "icefish", nameEN: "Icefish", nameKO: "빙어",
            tier: .uncommon, unlockLevel: 50,
            seasons: [.winter], timesOfDay: [.day], weathers: allWeathers,
            xp: 110, weight: 40,
            bitePattern: [
                BiteTap(offset: 0, intensity: 0.2, sharpness: 1.0, duration: 0.02),
                BiteTap(offset: 0.6, intensity: 0.5, sharpness: 1.0, duration: 0.04),
            ],
            archetype: "small-fry"),
        FishSpecies(
            id: "cherry-trout", nameEN: "Cherry trout", nameKO: "산천어",
            tier: .rare, unlockLevel: 60,
            seasons: [.spring], timesOfDay: [.dawn], weathers: [.clear, .fog],
            xp: 160, weight: 16,
            bitePattern: [
                BiteTap(offset: 0, intensity: 0.3, sharpness: 0.8, duration: 0.05),
                BiteTap(offset: 0.4, intensity: 0.55, sharpness: 0.8, duration: 0.05),
                BiteTap(offset: 0.8, intensity: 0.9, sharpness: 0.85, duration: 0.08),
            ],
            archetype: "slender-shape"),
        FishSpecies(
            id: "pale-carp", nameEN: "Pale carp", nameKO: "흰잉어",
            tier: .rare, unlockLevel: 70,
            seasons: allSeasons, timesOfDay: [.dawn, .dusk], weathers: [.fog],
            xp: 180, weight: 12,
            bitePattern: [
                BiteTap(offset: 0, intensity: 0.8, sharpness: 0.3, duration: 0.4),
                BiteTap(offset: 0.6, intensity: 0.5, sharpness: 0.3, duration: 0.4),
                BiteTap(offset: 1.3, intensity: 0.25, sharpness: 0.3, duration: 0.5),
            ],
            archetype: "carp-shape"),
        FishSpecies(
            id: "ink-carp", nameEN: "Ink carp", nameKO: "먹잉어",
            tier: .apex, unlockLevel: 90,
            seasons: allSeasons, timesOfDay: [.night], weathers: [.storm],
            xp: 250, weight: 8,
            bitePattern: [
                // The long silence, then everything.
                BiteTap(offset: 1.8, intensity: 1.0, sharpness: 1.0, duration: 0.5),
            ],
            archetype: "carp-shape"),
    ]
}
