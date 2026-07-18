import SpriteKit
import SwiftUI
import GameKernel
import SkyState

/// The focused sweeping ritual (spec §2: a ritual, not a skill). The real sky
/// litters the path; drag to clear it. The cleared sky is remembered, so only
/// a *new* kind of weather re-litters — never mere time passing.
struct SweepView: View {
    let conditions: WorldConditions
    let onClose: () -> Void

    @State private var scene = SweepScene()
    @State private var kind: Litter?
    @State private var cleared = false

    private let sweptKey = "meok-swept-litter"

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            chrome
        }
        .statusBarHidden(true)
        .onAppear(perform: begin)
    }

    private func begin() {
        let demo = ProcessInfo.processInfo.arguments.contains("-meok-sweep-demo")
        let litter = demo ? Litter.leaves : Sweeping.litter(for: conditions)
        kind = litter
        let swept = UserDefaults.standard.string(forKey: sweptKey)
        let alreadyClear = !demo && (litter == nil || litter?.rawValue == swept)
        guard let litter, !alreadyClear else {
            cleared = true
            return
        }
        scene.kind = litter
        scene.onCleared = {
            UserDefaults.standard.set(litter.rawValue, forKey: sweptKey)
            cleared = true
        }
        scene.spawnLitter()
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
            }
            Spacer()
            Text(prompt)
                .font(.callout)
                .foregroundStyle(cleared ? inkColor.opacity(0.7) : .secondary)
                .padding(.bottom, 56)
        }
    }

    private var prompt: LocalizedStringKey {
        if cleared { return "The path is clear." }
        return kind == .snow ? "Sweep the snow away" : "Sweep the leaves away"
    }

    private var inkColor: Color { Color(uiColor: .meokInk) }
}
