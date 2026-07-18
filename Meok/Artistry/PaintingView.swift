import SpriteKit
import SwiftUI
import GameKernel
import Persistence
import SkyState

/// The focused Artistry view (spec §2, the signature skill). Choose a frame,
/// trace its guided strokes on the canvas — the live sky bakes in — and at
/// mastery stamp the red seal. The finished work hangs in the gallery.
struct PaintingView: View {
    let conditions: WorldConditions
    let onClose: () -> Void

    @StateObject private var session: PaintingSession
    @State private var scene = PaintingScene()

    init(conditions: WorldConditions, store: GameStore, onClose: @escaping () -> Void) {
        self.conditions = conditions
        self.onClose = onClose
        _session = StateObject(wrappedValue: PaintingSession(
            conditions: conditions,
            store: store,
            autopilot: ProcessInfo.processInfo.arguments.contains("-meok-paint-demo")))
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
            if session.autopilot { session.runDemo() }
        }
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
                Text("Artistry Lv \(session.level)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(14)
            }
            Spacer()
            phaseChrome
                .padding(.bottom, 48)
        }
    }

    @ViewBuilder
    private var phaseChrome: some View {
        switch session.phase {
        case .choosing:
            VStack(spacing: 10) {
                Text("Choose a frame")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(session.available) { composition in
                            Button {
                                session.choose(composition)
                            } label: {
                                Text(composition.displayName)
                                    .font(.callout)
                                    .foregroundStyle(inkColor.opacity(0.85))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .overlay(Capsule().stroke(inkColor.opacity(0.5), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        case .tracing:
            VStack(spacing: 4) {
                Text("Trace the strokes")
                    .font(.callout)
                    .foregroundStyle(inkColor.opacity(0.85))
                Text(verbatim: "\(session.traced) / \(session.total)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        case .sealing:
            VStack(spacing: 10) {
                Text("Stamp your seal?")
                    .font(.callout)
                    .foregroundStyle(inkColor.opacity(0.85))
                HStack(spacing: 12) {
                    Button { session.stampSeal() } label: {
                        Text("The red seal")
                            .font(.callout)
                            .foregroundStyle(Color(red: 0.72, green: 0.14, blue: 0.11))
                            .padding(.horizontal, 18).padding(.vertical, 8)
                            .overlay(Capsule().stroke(Color(red: 0.72, green: 0.14, blue: 0.11).opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    Button { session.skipSeal() } label: {
                        Text("Leave it")
                            .font(.callout)
                            .foregroundStyle(inkColor.opacity(0.7))
                            .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        case .finished:
            VStack(spacing: 6) {
                if let composition = session.chosen {
                    Text(composition.displayName)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(inkColor)
                }
                if let reward = session.reward {
                    Text("+\(reward.xpAwarded) XP · Artistry Lv \(reward.level)")
                        .font(.callout)
                        .foregroundStyle(inkColor.opacity(0.8))
                    if reward.leveledUp { detail("Level up!") }
                }
                if session.sealed { detail("Sealed in red.") }
                Button(action: onClose) {
                    Text("Hang it in the gallery")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
    }

    private func detail(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.footnote.weight(.medium))
            .foregroundStyle(inkColor.opacity(0.75))
    }

    private var inkColor: Color { Color(uiColor: .meokInk) }
}
