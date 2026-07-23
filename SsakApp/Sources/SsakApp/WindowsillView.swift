import SwiftUI
import SsakCore
import SsakArt

/// The home screen (round 2, mockup in `docs/design/`): the plant gets the whole window.
/// A living RoomScene fills the frame; the plant sits on the sill, gently swaying; the
/// species name + a quiet moist chip rest near the bottom; Water is a small floating glass
/// drop bottom-right. Streak / tick / Share stay as corner glass chips. At night the room
/// goes dark and the chrome flips to dark ink via `TimeBand`, independent of system dark mode.
public struct WindowsillView: View {
    @ObservedObject var model: GardenModel
    let now: Date
    var onWater: () -> Void
    var onShare: () -> Void

    public init(model: GardenModel, now: Date,
                onWater: @escaping () -> Void, onShare: @escaping () -> Void) {
        self.model = model; self.now = now; self.onWater = onWater; self.onShare = onShare
    }

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bloomScale: CGFloat = 1   // bloom-open ceremony (spec §1.5, §2.2)
    @State private var sway = false              // ambient life; resting frame in renders
    @State private var pourDip = false           // brief dip on watering (the mockup "pour")

    /// The soil's care category, decided by the model and handed to the moist chip and the
    /// VoiceOver label (spec §3.2). Local alias so the view never reaches into `state.plant`.
    private var soil: SoilState { model.soil }

    /// Night flips the chrome to dark ink even in system light mode — the room is dark.
    private var chromeScheme: ColorScheme {
        TimeBand(now: now, calendar: model.calendar) == .night ? .dark : scheme
    }

    /// How much the plant sags: strong while nursing, else scaled by how far below the dry
    /// line. Sag is a *degree* (not a category), so it stays numeric — the normalized dry
    /// line is `dryThreshold/moistureMax`, exactly the old `band.lowerBound`.
    private var droop: Double {
        if model.isNursing { return 0.65 }
        let lower = model.tuning.dryThreshold / model.tuning.moistureMax
        let f = model.moistureFraction
        return f < lower ? min(1, (lower - f) / max(lower, 0.001)) * 0.8 : 0
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                RoomScene(now: now, calendar: model.calendar)
                    .ignoresSafeArea()

                hero
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.80 - 170)

                chrome(height: geo.size.height)
                    .environment(\.colorScheme, chromeScheme)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { sway = true }
        }
        .onChange(of: model.stage) { newStage in         // bloom-open ceremony (Simulator-verified)
            guard newStage == .bloom, !reduceMotion else { return }
            bloomScale = 0.7
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { bloomScale = 1 }
        }
    }


    private func water() {
        onWater()
        guard !reduceMotion else { return }                // the mockup "pour" dip
        pourDip = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { pourDip = false }
    }

    // All chrome in one layer so the night ink flip applies uniformly.
    private func chrome(height: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 0) {
                statusBar
                Spacer()
                nameBlock
                MoistChip(fraction: model.moistureFraction, soil: soil,
                          watered: model.hasWateredToday(now: now))
                    .padding(.top, 14)
                if model.wouldOverwater(now: now) { overwaterNudge.padding(.top, 8) }
            }
            .padding(.horizontal, Design.pad)
            .padding(.bottom, 32)

            WaterButton(action: water)
                .guideTarget("water")
                .padding(.trailing, Design.pad)
                .padding(.bottom, height * 0.155)          // floats clear of the name block
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    // Corner chips: streak (left) · watered-tick + quiet glass Share (right). The centered
    // nav pill lives in RootView on the same 44pt top row.
    private var statusBar: some View {
        HStack {
            StreakBadge(count: model.streak, alive: model.isStreakAlive(now: now))
            Spacer()
            trailingChrome
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    @ViewBuilder private var trailingChrome: some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            GlassEffectContainer { chromeCluster }
        } else {
            chromeCluster
        }
        #else
        chromeCluster                                      // macOS render path → structural fallback
        #endif
    }

    // Just the quiet Share — the watered-today seal lives in the MoistChip (the shared
    // top row has no free width next to the centered nav pill).
    private var chromeCluster: some View {
        GlassIconButton(systemImage: "square.and.arrow.up",
                        label: model.stage == .bloom ? "Share your bloom" : "Share",
                        prominent: model.stage == .bloom) { onShare() }
    }

    // The plant on the sill — watermark behind, gentle sway, tap waters too.
    private var hero: some View {
        ZStack {
            SpeciesWatermark(species: model.species).frame(width: 150, height: 150)
            PlantView(species: model.species, stage: model.stage, droop: droop,
                      wall: false, board: false)
                .frame(width: 280, height: 340)
                .scaleEffect(bloomScale * (pourDip ? 0.975 : 1), anchor: .bottom)
                .rotationEffect(.degrees(sway ? 1.1 : -1.1), anchor: .bottom)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .guideTarget("plant")
        .onTapGesture { water() }                          // tap-the-plant waters too
        .accessibilityElement()
        .accessibilityLabel(heroLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Water") { onWater() }
    }

    // Name — serif EN display (.title, the Toss 28pt slot) + KO secondary at the 13pt floor.
    private var nameBlock: some View {
        VStack(spacing: 6) {
            Text(model.species.nameEN)
                .font(.system(.title, design: .serif).weight(.semibold))
                .tracking(-0.3)
            Text(model.species.nameKO)
                .font(.footnote.weight(.medium)).foregroundStyle(.secondary)
        }
        .inkText()
    }

    // Gentle overwater nudge — deep amber-brown (light) / light amber (dark), 💧 non-color cue.
    private var overwaterNudge: some View {
        Text("Watered today — go easy on the water 💧")
            .font(.footnote.weight(.medium))
            .foregroundStyle(chromeScheme == .dark
                ? Color(red: 0.941, green: 0.753, blue: 0.467)     // light amber for dark ground
                : Color(red: 0.478, green: 0.306, blue: 0.031))    // #7A4E08, ≥4.5:1 on cream
    }

    /// Combined VoiceOver label (spec §5) — omits "watered today" (the top-bar tick carries it).
    private var heroLabel: String {
        let soilWord: String
        switch soil {
        case .dry:      soilWord = "soil dry"
        case .overfull: soilWord = "soil over-full"
        case .moist:    soilWord = "soil moist"
        }
        let stageWord: String
        switch model.stage {
        case .seed:   stageWord = "a seed"
        case .sprout: stageWord = "sprouting"
        case .leaves: stageWord = "leafing out"
        case .bud:    stageWord = "budding"
        case .bloom:  stageWord = "blooming"
        }
        return "\(model.species.nameEN), \(stageWord), \(soilWord)"
    }
}
