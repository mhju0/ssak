import SpriteKit
import SwiftUI
import GameKernel
import Persistence

/// The focused kitchen (spec §3). The dishes your level has unlocked, each
/// showing whether the pantry can afford it; cook one and it paints in above,
/// consumed for XP and a buff. Reached once the kitchen is restored (#44).
struct CookingView: View {
    let onClose: () -> Void

    @StateObject private var session: CookingSession
    @State private var scene = CookScene()

    init(store: GameStore, onClose: @escaping () -> Void) {
        self.onClose = onClose
        _session = StateObject(wrappedValue: CookingSession(
            store: store,
            autopilot: ProcessInfo.processInfo.arguments.contains("-meok-cook-demo")))
    }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Spacer()
                if let dish = session.lastCooked, let reward = session.lastReward {
                    payoff(dish, reward)
                        .padding(.bottom, 8)
                }
                menu
            }
        }
        .statusBarHidden(true)
        .onAppear {
            session.scene = scene
            session.begin()
            if session.autopilot {
                Task { try? await Task.sleep(for: .seconds(1)); session.runDemoCook() }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.body)
                    .foregroundStyle(inkColor.opacity(0.55))
                    .padding(14)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Cooking Lv \(session.level)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(14)
        }
    }

    private var menu: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(session.rows) { row in
                    dishRow(row)
                    Divider().overlay(inkColor.opacity(0.12))
                }
            }
        }
        .frame(maxHeight: 320)
        .padding(.bottom, 24)
    }

    private func dishRow(_ row: CookingSession.DishRow) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(row.dish.displayName)
                    .font(.callout)
                    .foregroundStyle(inkColor)
                HStack(spacing: 10) {
                    ForEach(row.ingredients) { ingredient in
                        Text(verbatim: "\(ingredient.name) \(ingredient.have)/\(ingredient.need)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(ingredient.enough ? inkColor.opacity(0.7) : .secondary)
                    }
                }
                if row.dish.buff != nil {
                    Text("a faster bite · \(Int(row.dish.buffMinutes)) min")
                        .font(.caption2)
                        .foregroundStyle(inkColor.opacity(0.55))
                }
            }
            Spacer()
            Button {
                session.cook(row.dish)
            } label: {
                Text("Cook")
                    .font(.callout)
                    .foregroundStyle(row.affordable ? inkColor.opacity(0.85) : Color.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .overlay(Capsule().stroke(
                        (row.affordable ? inkColor : Color.gray).opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!row.affordable)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 20)
    }

    private func payoff(_ dish: Dish, _ reward: XPReward) -> some View {
        VStack(spacing: 4) {
            Text("Cooked \(dish.displayName)")
                .font(.callout.weight(.medium))
                .foregroundStyle(inkColor)
            Text("+\(reward.xpAwarded) XP · Cooking Lv \(reward.level)")
                .font(.footnote)
                .foregroundStyle(inkColor.opacity(0.75))
            if reward.leveledUp {
                Text("Level up!").font(.footnote.weight(.medium)).foregroundStyle(inkColor.opacity(0.75))
            }
            if dish.buff != nil {
                Text("The line will bite sooner for a while.")
                    .font(.footnote)
                    .foregroundStyle(inkColor.opacity(0.7))
            }
        }
    }

    private var inkColor: Color { Color(uiColor: .meokInk) }
}
