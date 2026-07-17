import SpriteKit
import SwiftUI
import GameKernel
import Persistence
import SkyState

/// The focused full-screen fishing view (spec §3: activities open focused
/// views). One press gesture drives every phase; all chrome is darkest-ink
/// text on the paper.
struct FishingView: View {
    let conditions: WorldConditions
    let onClose: () -> Void

    @StateObject private var session: FishingSession
    @State private var scene = FishingScene()
    @State private var pressing = false

    init(conditions: WorldConditions, store: GameStore, onClose: @escaping () -> Void) {
        self.conditions = conditions
        self.onClose = onClose
        _session = StateObject(wrappedValue: FishingSession(
            conditions: conditions,
            store: store,
            autopilot: ProcessInfo.processInfo.arguments.contains("-meok-fish-demo")))
    }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .gesture(press)
            chrome
        }
        .statusBarHidden(true)
        .onAppear {
            session.scene = scene
            scene.wetness = CGFloat(session.conditions.rainIntensity)
            if session.autopilot { session.cast() }
        }
        .onChange(of: conditions) { _, new in session.conditions = new }
    }

    private var press: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !pressing else { return }
                pressing = true
                session.pressBegan()
            }
            .onEnded { _ in
                pressing = false
                session.pressEnded()
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
                Text("Fishing Lv \(session.level)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(14)
            }
            Spacer()
            phaseChrome
                .padding(.bottom, 56)
        }
    }

    @ViewBuilder
    private var phaseChrome: some View {
        switch session.phase {
        case .ready:
            prompt("Tap to cast")
        case .waiting:
            prompt("Watch the bobber…")
        case .signature:
            // The pattern speaks for itself — bobber, palm, and ear.
            EmptyView()
        case .strikeWindow:
            Text("Now!")
                .font(.title3.weight(.semibold))
                .foregroundStyle(inkColor)
        case .fighting:
            VStack(spacing: 10) {
                if session.lineSinging {
                    Text("— the line sings —")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(inkColor)
                } else {
                    prompt("Hold to reel — ease off when the line sings")
                }
                GeometryReader { proxy in
                    Rectangle()
                        .fill(inkColor.opacity(0.7))
                        .frame(width: proxy.size.width * session.fightProgress, height: 2)
                }
                .frame(width: 180, height: 2)
                .background(inkColor.opacity(0.15))
            }
        case .landed(let outcome):
            VStack(spacing: 6) {
                if let species = session.species {
                    Text(species.displayName)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(inkColor)
                }
                Text("+\(outcome.xpAwarded) XP · Fishing Lv \(outcome.level)")
                    .font(.callout)
                    .foregroundStyle(inkColor.opacity(0.8))
                if outcome.leveledUp { detail("Level up!") }
                if outcome.firstCatchOfSpecies { detail("First catch!") }
                if outcome.newWeatherVariant { detail("A new sky for this one.") }
                prompt("Tap to continue")
                    .padding(.top, 8)
            }
        case .slipped(let wasNew):
            VStack(spacing: 6) {
                Text("It slipped away…")
                    .font(.callout)
                    .foregroundStyle(inkColor.opacity(0.85))
                if wasNew { detail("A shadow joins the ledger.") }
                prompt("Tap to continue")
                    .padding(.top, 8)
            }
        }
    }

    private var inkColor: Color {
        Color(red: 0.10, green: 0.095, blue: 0.09)
    }

    private func prompt(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private func detail(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.footnote.weight(.medium))
            .foregroundStyle(inkColor.opacity(0.75))
    }
}
