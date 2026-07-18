import SpriteKit
import SwiftUI
import GameKernel
import Persistence
import SkyState

/// The focused foraging view (spec §3: activities open focused views). Tap
/// the faint spots in the clearing to gather what today's sky has grown;
/// wander on for a fresh handful. All chrome is darkest-ink text on paper.
struct ForagingView: View {
    let conditions: WorldConditions
    let onClose: () -> Void

    @StateObject private var session: ForagingSession
    @State private var scene = ForagingScene()

    init(conditions: WorldConditions, store: GameStore, onClose: @escaping () -> Void) {
        self.conditions = conditions
        self.onClose = onClose
        _session = StateObject(wrappedValue: ForagingSession(
            conditions: conditions,
            store: store,
            autopilot: ProcessInfo.processInfo.arguments.contains("-meok-forage-demo")))
    }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            chrome
        }
        .statusBarHidden(true)
        .onAppear {
            session.scene = scene
            scene.wetness = CGFloat(session.conditions.rainIntensity)
            scene.onGather = { session.gather($0) }
            session.wander()
        }
        .onChange(of: conditions) { _, new in session.conditions = new }
    }

    private var chrome: some View {
        VStack {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundStyle(inkColor.opacity(0.55))
                        .padding(14)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("Foraging Lv \(session.level)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(14)
            }
            Spacer()
            footer
                .padding(.bottom, 56)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if session.allGathered {
            VStack(spacing: 10) {
                Text("The clearing is quiet now.")
                    .font(.callout)
                    .foregroundStyle(inkColor.opacity(0.85))
                Button {
                    session.wander()
                } label: {
                    Text("Wander on")
                        .font(.callout)
                        .foregroundStyle(inkColor.opacity(0.85))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 8)
                        .overlay(Capsule().stroke(inkColor.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        } else if let found = session.lastGathered, let outcome = session.lastOutcome {
            VStack(spacing: 6) {
                Text(found.displayName)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(inkColor)
                Text("+\(outcome.xpAwarded) XP · Foraging Lv \(outcome.level)")
                    .font(.callout)
                    .foregroundStyle(inkColor.opacity(0.8))
                if outcome.leveledUp { detail("Level up!") }
                if outcome.firstOfSpecies { detail("First find!") }
                if outcome.newWeatherVariant { detail("A new sky for this one.") }
            }
        } else {
            Text("Tap a spot to gather")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var inkColor: Color { Color(uiColor: .meokInk) }

    private func detail(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.footnote.weight(.medium))
            .foregroundStyle(inkColor.opacity(0.75))
    }
}
