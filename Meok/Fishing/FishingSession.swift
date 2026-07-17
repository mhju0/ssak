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
        case landed(CatchOutcome)
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
                ? UInt64(defaults.integer(forKey: "meok-seed"))
                : UInt64(Date().timeIntervalSince1970))
        rng = SeededRandom(seed: resolvedSeed)
        level = XPCurve.level(forXP: store.progress(for: .fishing).xp)
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
        guard let bite = ConditionEngine.nextBite(conditions, level: castLevel, using: &rng)
        else { return }  // unreachable: the coverage invariant is kernel-tested

        self.bite = bite
        species = bite.species
        phase = .waiting
        scene?.wetness = CGFloat(conditions.rainIntensity)
        scene?.showCast()

        let delay = autopilot ? min(bite.delay, 1.6) : bite.delay
        transition(after: delay) { self.beginSignature() }
    }

    private func beginSignature() {
        guard let taps = bite?.species.bitePattern else { return }
        phase = .signature
        scene?.playTremble(taps)
        feedback.playSignature(taps)
        let length = (taps.last?.offset ?? 0) + (taps.last?.duration ?? 0)
        transition(after: length + 0.05) { self.openStrikeWindow() }
    }

    private func openStrikeWindow() {
        phase = .strikeWindow
        if autopilot {
            transition(after: 0.3) { self.hook() }
        } else {
            // The window closes and the fish drifts off with the moment.
            transition(after: FishingRules.strikeWindow) { self.slip() }
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
        phaseTask = Task { [weak self] in
            guard let self else { return }
            var elapsed = 0.0
            var reeled = 0.0
            var singRemaining = 0.0
            var nextSing = 1.5 + 2.0 * Double(rng.next() % 1000) / 1000
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                if Task.isCancelled { return }
                elapsed += 0.05

                if singRemaining > 0 {
                    singRemaining -= 0.05
                    if singRemaining <= 0 {
                        lineSinging = false
                        if autopilot { holding = true }
                        if holding {
                            // Held through the song — the line strains.
                            strain += 1
                            if strain >= 3 { slip(); return }
                        }
                    }
                } else if elapsed >= nextSing, reeled < FishingRules.fightDuration - 1 {
                    lineSinging = true
                    singRemaining = 0.8
                    nextSing = elapsed + 2.2 + 1.2 * Double(rng.next() % 1000) / 1000
                    feedback.sing()
                    scene?.singShiver()
                    if autopilot { holding = false }
                } else if holding {
                    reeled += 0.05
                    fightProgress = min(1, reeled / FishingRules.fightDuration)
                    if reeled >= FishingRules.fightDuration { land(); return }
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

    private func transition(after seconds: Double, _ body: @escaping @MainActor () -> Void) {
        phaseTask?.cancel()
        phaseTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1e9))
            guard !Task.isCancelled else { return }
            body()
        }
    }
}
