import Foundation
import GameKernel
import Persistence
import SkyState
import StrokeEngine

extension Composition {
    var displayName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? nameKO : nameEN
    }
}

/// The Artistry loop: choose a frame, trace its guided strokes (the live sky
/// bakes in), and — at mastery — stamp the red seal. The finished work hangs
/// in the gallery. You cannot fail (spec §2: authorship without ruining).
@MainActor
final class PaintingSession: ObservableObject {
    enum Phase: Equatable { case choosing, tracing, sealing, finished }

    @Published private(set) var phase: Phase = .choosing
    @Published private(set) var level: Int
    @Published private(set) var chosen: Composition?
    @Published private(set) var traced = 0
    @Published private(set) var total = 0
    @Published private(set) var sealed = false
    @Published private(set) var reward: XPReward?

    var conditions: WorldConditions
    weak var scene: PaintingScene?
    let autopilot: Bool

    private let store: GameStore
    private var demoTask: Task<Void, Never>?

    init(conditions: WorldConditions, store: GameStore, autopilot: Bool = false) {
        self.conditions = conditions
        self.store = store
        self.autopilot = autopilot
        level = XPCurve.level(forXP: store.progress(for: .artistry).xp)
    }

    deinit { demoTask?.cancel() }

    private var castLevel: Int {
        let override = UserDefaults.standard.integer(forKey: "meok-art-level")
        return override > 0 ? override : level
    }

    var available: [Composition] { Artistry.available(level: castLevel) }
    var sealAvailable: Bool { Artistry.sealEarned(level: castLevel) }

    func choose(_ composition: Composition) {
        // A frame with no scene never enters tracing (unreachable — every
        // composition has a recipe — but no silent stuck state either).
        guard let recipe = Recipes.composition[composition.id] else { return }
        chosen = composition
        traced = 0
        phase = .tracing
        scene?.onProgress = { [weak self] done, total in
            self?.traced = done
            self?.total = total
        }
        scene?.onComplete = { [weak self] in self?.allTraced() }
        scene?.setComposition(recipe, wetness: CGFloat(conditions.rainIntensity))
    }

    private func allTraced() {
        if sealAvailable {
            phase = .sealing
        } else {
            complete()
        }
    }

    func stampSeal() {
        guard phase == .sealing else { return }
        sealed = true
        scene?.stampSeal()
        complete()
    }

    func skipSeal() {
        guard phase == .sealing else { return }
        complete()
    }

    private func complete() {
        guard let composition = chosen else { return }
        let earned = store.record(
            painting: composition, conditions: conditions, sealed: sealed, now: Date())
        reward = earned
        level = earned.level
        phase = .finished
    }

    /// The harness paints itself: choose a frame, trace every stroke, seal.
    func runDemo() {
        guard autopilot, let first = available.first else { return }
        choose(first)
        demoTask = Task { [weak self] in
            while let self, self.phase == .tracing {
                try? await Task.sleep(for: .seconds(0.5))
                self.scene?.autoTrace()
            }
            guard let self else { return }
            if self.phase == .sealing { self.stampSeal() }
        }
    }
}
