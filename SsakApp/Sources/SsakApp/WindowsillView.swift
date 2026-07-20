import SwiftUI
import SsakCore
import SsakArt

/// The home screen (spec §2.2): the current plant on a real-time sky, chrome-light and
/// screenshot-ready. A floating Liquid Glass Water control decoupled from the nav, a quiet
/// glass Share, a faint 싹 watermark, and a gauge-only status cluster (streak/tick live only
/// in the top bar). Tapping the plant waters it too.
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
    @State private var chromeVisible = true
    @State private var wake = 0
    @State private var bloomScale: CGFloat = 1   // bloom-open ceremony (spec §1.5, §2.2)

    /// The soil's care category — one classification, decided here from raw moisture and
    /// handed down to the status cluster and the VoiceOver label (spec §3.2).
    private var soil: SoilState {
        SoilState(moisture: model.state.plant.moisture, tuning: model.tuning)
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
        ZStack {
            SkyBackdrop(now: now, calendar: model.calendar)   // fills the frame; dark-mode aware
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                statusBar.opacity(chromeVisible ? 1 : 0)
                Spacer()
                hero
                nameBlock.padding(.top, 12)
                StatusCluster(fraction: model.moistureFraction, soil: soil).padding(.top, 14)
                if model.wouldOverwater(now: now) { overwaterNudge.padding(.top, 8) }
                Spacer()
                // Zone 6: floating Water control — lower third, in clear space above the tab bar.
                WaterButton(isOverfull: model.wouldOverwater(now: now)) { onWater(); poke() }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                    .opacity(chromeVisible ? 1 : 0)
            }
            .padding(.horizontal, 20)
        }
        .animation(.easeInOut(duration: 0.6), value: chromeVisible)
        .task(id: wake) {
            chromeVisible = true
            guard !reduceMotion else { return }          // Reduce Motion → chrome stays put
            try? await Task.sleep(for: .seconds(4))
            chromeVisible = false                          // idle "just looking" → plant + sky alone
        }
        .onChange(of: model.stage) { newStage in         // bloom-open ceremony (Simulator-verified)
            guard newStage == .bloom, !reduceMotion else { return }
            bloomScale = 0.7
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { bloomScale = 1 }
        }
    }

    private func poke() { wake += 1 }                      // re-show chrome on interaction

    // Zone 1: streak (left) · watered-tick + quiet glass Share (right). These signals live here only.
    private var statusBar: some View {
        HStack {
            StreakBadge(count: model.state.plant.streak, alive: model.isStreakAlive(now: now))
            Spacer()
            trailingChrome
        }
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

    private var chromeCluster: some View {
        HStack(spacing: 12) {
            if model.hasWateredToday(now: now) {
                WateredTodayTick().font(.system(size: 20)).accessibilityLabel("Watered today")
            }
            GlassIconButton(systemImage: "square.and.arrow.up",
                            label: model.stage == .bloom ? "Share your bloom" : "Share",
                            prominent: model.stage == .bloom) { onShare() }
        }
    }

    // Zone 2: sky hero — faint watermark behind, plant centered with generous negative space.
    private var hero: some View {
        ZStack {
            SpeciesWatermark(species: model.species).frame(width: 150, height: 150)
            PlantView(species: model.species, stage: model.stage, droop: droop, wall: false)
                .frame(width: 280, height: 340)
                .scaleEffect(bloomScale)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture { onWater(); poke() }                // tap-the-plant waters too
        .accessibilityElement()
        .accessibilityLabel(heroLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Water") { onWater() }
    }

    // Zone 3: name — serif EN + KO secondary, adaptive ink so it reads on every band + dark mode.
    private var nameBlock: some View {
        VStack(spacing: 2) {
            Text(model.species.nameEN)
                .font(.system(.title3, design: .serif).weight(.semibold))
            Text(model.species.nameKO)
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .inkText()
    }

    // Zone 5: gentle overwater nudge — deep amber-brown (light) / light amber (dark), 💧 non-color cue.
    private var overwaterNudge: some View {
        Text("Watered today — go easy on the water 💧")
            .font(.footnote.weight(.medium))
            .foregroundStyle(scheme == .dark
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
