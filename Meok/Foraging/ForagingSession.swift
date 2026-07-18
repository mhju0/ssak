import Foundation
import GameKernel
import Persistence
import SkyState

extension Forageable {
    var displayName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? nameKO : nameEN
    }
}

/// The foraging loop: a clearing holds a few condition-gated finds; tap each
/// to gather it (XP + ledger). No timing, no failure — foraging is gentle
/// (spec §2). Wander on to re-scatter the clearing with a fresh handful.
@MainActor
final class ForagingSession: ObservableObject {
    struct Spot: Identifiable {
        let id = UUID()
        let forageable: Forageable
        /// Unit fractions within the scene (x, y-up).
        let position: CGPoint
        var gathered = false
    }

    @Published private(set) var spots: [Spot] = []
    @Published private(set) var level: Int
    @Published private(set) var lastGathered: Forageable?
    @Published private(set) var lastOutcome: HaulOutcome?

    var conditions: WorldConditions
    weak var scene: ForagingScene?
    let autopilot: Bool

    private let store: GameStore
    private var rng: SeededRandom

    /// Where finds can appear in the clearing (spread across the lower field).
    private static let plots: [CGPoint] = [
        CGPoint(x: 0.28, y: 0.34),
        CGPoint(x: 0.54, y: 0.46),
        CGPoint(x: 0.74, y: 0.32),
        CGPoint(x: 0.40, y: 0.60),
        CGPoint(x: 0.66, y: 0.62),
    ]

    init(
        conditions: WorldConditions, store: GameStore,
        seed: UInt64? = nil, autopilot: Bool = false
    ) {
        self.conditions = conditions
        self.store = store
        self.autopilot = autopilot
        let defaults = UserDefaults.standard
        let resolvedSeed = seed
            ?? (defaults.object(forKey: "meok-seed") != nil
                ? UInt64(bitPattern: Int64(defaults.integer(forKey: "meok-seed")))
                : UInt64(Date().timeIntervalSince1970))
        rng = SeededRandom(seed: resolvedSeed)
        level = XPCurve.level(forXP: store.progress(for: .foraging).xp)
    }

    private var castLevel: Int {
        let override = UserDefaults.standard.integer(forKey: "meok-forage-level")
        return override > 0 ? override : level
    }

    /// Scatter the clearing with a fresh handful of condition-gated finds.
    func wander() {
        var fresh: [Spot] = []
        for plot in Self.plots {
            guard let find = Foraging.spot(conditions, level: castLevel, using: &rng) else { continue }
            fresh.append(Spot(forageable: find, position: plot))
        }
        spots = fresh
        lastGathered = nil
        lastOutcome = nil
        scene?.layoutSpots(fresh)
        if autopilot { runDemo() }
    }

    func gather(_ id: UUID) {
        guard let index = spots.firstIndex(where: { $0.id == id }), !spots[index].gathered
        else { return }
        let find = spots[index].forageable
        let outcome = store.record(gather: find, weather: conditions.weather)
        spots[index].gathered = true
        level = outcome.level
        lastGathered = find
        lastOutcome = outcome
        scene?.revealForageable(find, at: id)
    }

    var allGathered: Bool { !spots.isEmpty && spots.allSatisfy(\.gathered) }

    /// The harness plays itself: gather each find in turn for a screenshot.
    private func runDemo() {
        Task { [weak self] in
            for spot in self?.spots ?? [] {
                try? await Task.sleep(for: .seconds(1.1))
                guard let self else { return }
                self.gather(spot.id)
            }
        }
    }
}
