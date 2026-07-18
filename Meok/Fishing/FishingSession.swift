import Foundation
import GameKernel
import Persistence
import SkyState
import StrokeEngine

extension FishSpecies {
    var displayName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? nameKO : nameEN
    }
}

/// The fishing loop state machine: cast → wait → signature → strike window
/// → (fight) → landed/slipped. Kernel decides what bites; GameStore keeps
/// the ledgers; the scene and BiteFeedback mirror every beat.
@MainActor
final class FishingSession: ObservableObject {
    enum Phase: Equatable {
        case ready
        case waiting
        case signature
        case strikeWindow
        case fighting
        case landed(HaulOutcome)
        case slipped(wasNew: Bool)
    }

    @Published private(set) var phase = Phase.ready
    @Published private(set) var fightProgress: Double = 0
    @Published private(set) var lineSinging = false
    @Published private(set) var level: Int

    var conditions: WorldConditions
    private(set) var species: FishSpecies?
    weak var scene: FishingScene?

    /// The screenshot harness plays itself (`-meok-fish-demo`).
    let autopilot: Bool

    private let store: GameStore
    private let feedback = BiteFeedback()
    private var rng: SeededRandom
    private var bite: Bite?
    private var phaseTask: Task<Void, Never>?
    private var holding = false
    private var strain = 0

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
        level = XPCurve.level(forXP: store.progress(for: .fishing).xp)
    }

    deinit {
        // Tasks capture self weakly, so dismissal mid-phase reaches here;
        // cancel so no timer outlives the view.
        phaseTask?.cancel()
    }

    // MARK: Input (from the view's press gesture)

    func pressBegan() {
        switch phase {
        case .strikeWindow:
            hook()
        case .fighting:
            holding = true
        case .signature:
            // Yanking mid-pattern — reading the signature IS the skill.
            spook()
        default:
            break
        }
    }

    func pressEnded() {
        switch phase {
        case .fighting:
            holding = false
        case .ready:
            cast()
        case .landed, .slipped:
            reset()
        default:
            break
        }
    }

    // MARK: Phases

    func cast() {
        guard case .ready = phase else { return }
        // Dev override for reaching high-level species on a fresh install.
        let levelOverride = UserDefaults.standard.integer(forKey: "meok-fish-level")
        let castLevel = levelOverride > 0 ? levelOverride : level
        // A meal's bite-rate buff speeds the wait (spec §2); a better crafted
        // rod raises rare bites (spec §4).
        let scale = store.isActive(.biteRate, now: Date()) ? FishingRules.buffedBiteScale : 1
        let rodBoost = FishingRules.rareBoost(forRodTier: store.rodTier())
        guard let bite = ConditionEngine.nextBite(
            conditions, level: castLevel, biteDelayScale: scale, rareWeightBoost: rodBoost, using: &rng)
        else { return }  // unreachable: the coverage invariant is kernel-tested

        self.bite = bite
        species = bite.species
        phase = .waiting
        scene?.wetness = CGFloat(conditions.rainIntensity)
        scene?.showCast()

        let delay = autopilot ? min(bite.delay, 1.6) : bite.delay
        transition(after: delay) { $0.beginSignature() }
    }

    private func beginSignature() {
        guard let taps = bite?.species.bitePattern else { return }
        phase = .signature
        scene?.playTremble(taps)
        feedback.playSignature(taps)
        let length = (taps.last?.offset ?? 0) + (taps.last?.duration ?? 0)
        transition(after: length + 0.05) { $0.openStrikeWindow() }
    }

    private func openStrikeWindow() {
        phase = .strikeWindow
        if autopilot {
            transition(after: 0.3) { $0.hook() }
        } else {
            // The window closes and the fish drifts off with the moment.
            transition(after: FishingRules.strikeWindow) { $0.slip() }
        }
    }

    private func hook() {
        guard case .strikeWindow = phase, let species = bite?.species else { return }
        phaseTask?.cancel()
        scene?.strikeFlourish()
        if species.triggersFight {
            startFight()
        } else {
            land()
        }
    }

    private func startFight() {
        phase = .fighting
        fightProgress = 0
        strain = 0
        holding = autopilot
        phaseTask?.cancel()
        // A better crafted rod tolerates more strain (spec §4: keeper's rod).
        let strainLimit = FishingRules.strainLimit(forRodTier: store.rodTier())
        // Weak per-iteration so dismissing the view mid-fight deallocates
        // the session (deinit cancels) instead of spinning this loop forever.
        phaseTask = Task { [weak self] in
            var elapsed = 0.0
            var reeled = 0.0
            var singRemaining = 0.0
            var nextSing = 1.5
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard let self, !Task.isCancelled else { return }
                elapsed += 0.05

                // A fish never played simply tires of the game.
                if elapsed >= FishingRules.fightDuration * 3 { self.slip(); return }

                if singRemaining > 0 {
                    singRemaining -= 0.05
                    if singRemaining <= 0 {
                        self.lineSinging = false
                        if self.holding {
                            // Held through the song — the line strains.
                            self.strain += 1
                            if self.strain >= strainLimit { self.slip(); return }
                        }
                        if self.autopilot { self.holding = true }
                    }
                } else if elapsed >= nextSing, reeled < FishingRules.fightDuration - 1 {
                    lineSinging = true
                    singRemaining = 0.8
                    nextSing = elapsed + 2.2 + 1.2 * Double(self.rng.next() % 1000) / 1000
                    self.feedback.sing()
                    self.scene?.singShiver()
                    if self.autopilot { self.holding = false }
                } else if self.holding {
                    reeled += 0.05
                    self.fightProgress = min(1, reeled / FishingRules.fightDuration)
                    if reeled >= FishingRules.fightDuration { self.land(); return }
                }
            }
        }
    }

    private func land() {
        phaseTask?.cancel()
        guard let species = bite?.species else { return }
        let outcome = store.record(catch: species, weather: conditions.weather)
        level = outcome.level
        phase = .landed(outcome)
        lineSinging = false
        feedback.splash()
        if let recipe = Recipes.fish[species.id] {
            scene?.showCatch(recipe: recipe)
        }
    }

    private func spook() {
        phaseTask?.cancel()
        slip()
    }

    /// The fish slips away — no penalty beyond the moment, but the ledger
    /// remembers the shadow.
    private func slip() {
        phaseTask?.cancel()
        guard let species = bite?.species else { return }
        let wasNew = (store.record(for: species.id)?.timesCaught ?? 0) == 0
        store.recordEscape(of: species)
        phase = .slipped(wasNew: wasNew)
        lineSinging = false
        scene?.showSlip()
    }

    func reset() {
        phaseTask?.cancel()
        bite = nil
        species = nil
        fightProgress = 0
        strain = 0
        holding = false
        lineSinging = false
        phase = .ready
        scene?.clear()
        if autopilot { cast() }
    }

    /// Weak so a pending transition never keeps a dismissed session alive
    /// (or fires feedback after the view is gone).
    private func transition(
        after seconds: Double, _ body: @escaping @MainActor (FishingSession) -> Void
    ) {
        phaseTask?.cancel()
        phaseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1e9))
            guard let self, !Task.isCancelled else { return }
            body(self)
        }
    }
}
