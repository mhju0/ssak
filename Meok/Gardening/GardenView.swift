import SpriteKit
import SwiftUI
import GameKernel
import Persistence
import SkyState

/// The focused gardening view (spec §3). Tap a bed to select it: plant a seed
/// in an empty bed, water what's growing (a bonus, never a chore), or harvest
/// a ripe crop. Trees, once planted, stand for years. All chrome is ink on paper.
struct GardenView: View {
    let conditions: WorldConditions
    let onClose: () -> Void

    @StateObject private var session: GardenSession
    @State private var scene = GardenScene()

    init(conditions: WorldConditions, store: GameStore, onClose: @escaping () -> Void) {
        self.conditions = conditions
        self.onClose = onClose
        _session = StateObject(wrappedValue: GardenSession(
            conditions: conditions,
            store: store,
            autopilot: ProcessInfo.processInfo.arguments.contains("-meok-garden-demo")))
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
            scene.onSelectPlot = { session.select($0) }
            session.begin()
        }
        .onChange(of: session.selectedPlot) { _, plot in scene.highlight(plot) }
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
                Text("Gardening Lv \(session.level)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(14)
            }
            Spacer()
            VStack(spacing: 12) {
                if let event = session.lastEvent {
                    payoff(event)
                }
                actionPanel
            }
            .padding(.bottom, 44)
        }
    }

    @ViewBuilder
    private var actionPanel: some View {
        if session.selectedPlot == nil {
            Text("Tap a bed")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else if session.selectedPlanting == nil {
            VStack(spacing: 8) {
                Text("Plant a bed")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(session.available) { plantable in
                            capsuleButton(Text(plantable.displayName)) {
                                session.plant(plantable)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        } else {
            HStack(spacing: 12) {
                if let plantable = session.selectedPlantable {
                    Text(plantable.displayName)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(inkColor)
                }
                capsuleButton(Text("Water")) { session.waterSelected() }
                if session.selectedIsRipe {
                    capsuleButton(Text("Harvest")) { session.harvestSelected() }
                }
            }
        }
    }

    private func payoff(_ event: GardenSession.Event) -> some View {
        VStack(spacing: 4) {
            Text(message(for: event))
                .font(.callout)
                .foregroundStyle(inkColor.opacity(0.85))
            if let reward = session.lastReward, reward.xpAwarded > 0 {
                Text("+\(reward.xpAwarded) XP · Gardening Lv \(reward.level)")
                    .font(.footnote)
                    .foregroundStyle(inkColor.opacity(0.7))
            }
            if session.lastReward?.leveledUp == true {
                Text("Level up!")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(inkColor.opacity(0.75))
            }
        }
    }

    private func message(for event: GardenSession.Event) -> LocalizedStringKey {
        switch event {
        case .planted(let tree): tree ? "Planted — it will stand for years." : "A seed goes in."
        case .watered: "Watered — the dew beads."
        case .alreadyWatered: "Already watered today."
        case .harvested: "Harvested."
        }
    }

    private func capsuleButton(_ label: Text, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label
                .font(.callout)
                .foregroundStyle(inkColor.opacity(0.85))
                .padding(.horizontal, 18)
                .padding(.vertical, 7)
                .overlay(Capsule().stroke(inkColor.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var inkColor: Color { Color(uiColor: .meokInk) }
}
