import SwiftUI
import SsakCore
import SsakArt

/// The home screen (round 3, spec `2026-07-23-ssak-round3-hanji.md`): a page of the
/// pressed-flower album. Hanji paper follows the real clock (`HanjiBackdrop`); the plant
/// sits center-page over a soft ground shadow; chrome is ink — band clock and specimen
/// label up top with the streak seal, KO-first name block and hairline gauge below,
/// ink water drop bottom center. At night the paper darkens and the ink flips light via
/// `TimeBand` (never system dark mode alone).
public struct WindowsillView: View {
    @ObservedObject var model: GardenModel
    let now: Date
    var onWater: () -> Void
    var onShare: () -> Void

    public init(model: GardenModel, now: Date,
                onWater: @escaping () -> Void, onShare: @escaping () -> Void) {
        self.model = model; self.now = now; self.onWater = onWater; self.onShare = onShare
        SsakFonts.register()
    }

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bloomScale: CGFloat = 1   // bloom-open ceremony (spec §1.5, §2.2)
    @State private var sway = false              // ambient life; resting frame in renders
    @State private var pourDip = false           // brief dip on watering (the mockup "pour")

    /// The soil's care category, decided by the model and handed to the gauge and the
    /// VoiceOver label. Local alias so the view never reaches into `state.plant`.
    private var soil: SoilState { model.soil }

    /// Night flips the chrome to light ink even in system light mode — the paper is dark.
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
                HanjiBackdrop(now: now, calendar: model.calendar)
                    .ignoresSafeArea()

                // Anchored to the fixed-height bottom stack (name+gauge+actions ≈ 240pt),
                // not proportional — so pot and name block can't collide at any height.
                hero
                    .position(x: geo.size.width / 2, y: geo.size.height - 428)

                chrome
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
    private var chrome: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {                                   // top row: band clock (nav is RootView's)
                    BandClock(now: now, calendar: model.calendar)
                    Spacer()
                }
                .frame(height: 44)
                .padding(.top, 8)

                HStack(alignment: .top) {                  // album row: specimen label · seal
                    specimenLabel
                    Spacer()
                    SealBadge(count: model.streak, alive: model.isStreakAlive(now: now))
                }
                .padding(.top, 10)

                Spacer()
                // A2 "museum rules": two hairlines bracket the whole label — name,
                // gauge, and ONE status line (the nudge is folded into InkGauge).
                labelRule
                nameBlock.padding(.top, 24)
                InkGauge(fraction: model.moistureFraction, soil: soil,
                         watered: model.hasWateredToday(now: now))
                    .padding(.top, 22)
                labelRule.padding(.top, 20)
            }
            .padding(.horizontal, Design.pad)
            .padding(.bottom, 112)                         // clears the bottom action row

            InkWaterButton(action: water)
                .guideTarget("water")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 36)

            InkShareButton(label: model.stage == .bloom ? "Share your bloom" : "Share",
                           prominent: model.stage == .bloom) { onShare() }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, Design.pad)
                .padding(.bottom, 42)
        }
    }

    // The album's specimen framing: 제 N 호 (next open album slot) over the day count.
    private var specimenLabel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("제 \(model.collected.count + 1) 호 · 압화 예정")
                .font(.myeongjo(13, relativeTo: .footnote)).tracking(1.5)
            Rectangle().frame(width: 40, height: 1).opacity(0.5)
            Text("함께한 지 \(model.currentDay(now: now))일")
                .font(.myeongjo(13, relativeTo: .footnote)).tracking(1)
        }
        .inkText()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Album entry \(model.collected.count + 1), day \(model.currentDay(now: now))")
    }

    // The plant on the page — ground shadow behind, gentle sway, tap waters too.
    private var hero: some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [Design.shadow.opacity(0.22), .clear],
                                     center: .center, startRadius: 0, endRadius: 110))
                .frame(width: 216, height: 22)
                .offset(y: 136)                            // hugs the low 사발 bowl's base
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

    /// The A2 hairline — brackets the label like a museum wall caption.
    private var labelRule: some View {
        Rectangle().frame(height: 1).opacity(0.28)
            .padding(.horizontal, 40)
            .inkText()
    }

    // Name — KO-first (spec D1): 메리골드 in myeongjo display, MARIGOLD tracked beneath.
    private var nameBlock: some View {
        VStack(spacing: 12) {
            Text(model.species.nameKO)
                .font(.myeongjoDisplay(34, relativeTo: .largeTitle)).tracking(5)
            Text(model.species.nameEN.uppercased())
                .font(.system(size: 11, weight: .medium)).tracking(5)
                .opacity(0.6)
        }
        .inkText()
    }

    /// Combined VoiceOver label (spec §5) — omits "watered today" (the gauge carries it).
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
