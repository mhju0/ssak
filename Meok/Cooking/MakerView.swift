import SpriteKit
import SwiftUI
import GameKernel
import Persistence

/// The focused kitchen / workbench (spec §3). One menu shape for both: the
/// recipes your level has unlocked with live have/need counts; make an
/// affordable one and it paints in above, consumed for XP and its effect.
/// Reached once the room is restored (#44); a demo arg opens it meanwhile.
struct MakerView: View {
    let onClose: () -> Void

    @StateObject private var session: MakerSession
    @State private var scene: MakerScene

    init(store: GameStore, kind: MakerSession.Kind, onClose: @escaping () -> Void) {
        self.onClose = onClose
        _session = StateObject(wrappedValue: MakerSession(store: store, kind: kind))
        _scene = State(initialValue: MakerScene(art: kind.art))
    }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Spacer()
                if let item = session.lastMade, let reward = session.lastReward {
                    payoff(item, reward)
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
                Task { try? await Task.sleep(for: .seconds(1)); session.runDemo() }
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
            Text(levelTitle)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(14)
        }
    }

    private var menu: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(session.rows) { row in
                    itemRow(row)
                    Divider().overlay(inkColor.opacity(0.12))
                }
            }
        }
        .frame(maxHeight: 320)
        .padding(.bottom, 24)
    }

    private func itemRow(_ row: MakerSession.Row) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(row.item.displayName)
                    .font(.callout)
                    .foregroundStyle(inkColor)
                HStack(spacing: 10) {
                    ForEach(row.ingredients) { ingredient in
                        Text(verbatim: "\(ingredient.name) \(ingredient.have)/\(ingredient.need)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(ingredient.enough ? inkColor.opacity(0.7) : .secondary)
                    }
                }
                if let note = row.item.note {
                    Text(rowNote(note))
                        .font(.caption2)
                        .foregroundStyle(inkColor.opacity(0.55))
                }
            }
            Spacer()
            Button {
                session.make(row.item)
            } label: {
                Text(actionLabel)
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

    private func payoff(_ item: any Makeable, _ reward: XPReward) -> some View {
        VStack(spacing: 4) {
            Text(madeTitle(item))
                .font(.callout.weight(.medium))
                .foregroundStyle(inkColor)
            Text(xpLine(reward))
                .font(.footnote)
                .foregroundStyle(inkColor.opacity(0.75))
            if reward.leveledUp {
                Text("Level up!").font(.footnote.weight(.medium)).foregroundStyle(inkColor.opacity(0.75))
            }
            if let note = item.note {
                Text(payoffNote(note))
                    .font(.footnote)
                    .foregroundStyle(inkColor.opacity(0.7))
            }
        }
    }

    // MARK: Kind-specific text

    private var levelTitle: LocalizedStringKey {
        session.kind == .cooking ? "Cooking Lv \(session.level)" : "Crafting Lv \(session.level)"
    }
    private var actionLabel: LocalizedStringKey { session.kind == .cooking ? "Cook" : "Craft" }

    private func madeTitle(_ item: any Makeable) -> LocalizedStringKey {
        session.kind == .cooking ? "Cooked \(item.displayName)" : "Crafted \(item.displayName)"
    }
    private func xpLine(_ reward: XPReward) -> LocalizedStringKey {
        session.kind == .cooking
            ? "+\(reward.xpAwarded) XP · Cooking Lv \(reward.level)"
            : "+\(reward.xpAwarded) XP · Crafting Lv \(reward.level)"
    }
    private func rowNote(_ note: MakerNote) -> LocalizedStringKey {
        switch note {
        case .buff(let minutes): "a faster bite · \(minutes) min"
        case .betterRod: "a better rod"
        case .finerBrush: "a finer brush"
        }
    }
    private func payoffNote(_ note: MakerNote) -> LocalizedStringKey {
        switch note {
        case .buff: "The line will bite sooner for a while."
        case .betterRod: "More rare fish will bite now."
        case .finerBrush: "A finer brush, ready for painting."
        }
    }

    private var inkColor: Color { Color(uiColor: .meokInk) }
}
