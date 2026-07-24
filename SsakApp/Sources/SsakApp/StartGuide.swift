import SwiftUI
import SsakCore
import SsakArt

// The first-run start guide (round 2, mockup in `docs/design/`): an Apple-style welcome
// sheet, then three Duolingo-style spotlight coach marks over the live windowsill —
// the plant, the water drop, the Shelf tab. Replaces the round-1 full-screen onboarding.

/// Views under the guide tag their bounds with `.guideTarget(id)`; RootView resolves the
/// anchors and hands concrete rects to `StartGuide`.
public struct GuideTargetKey: PreferenceKey {
    public static var defaultValue: [String: Anchor<CGRect>] = [:]
    public static func reduce(value: inout [String: Anchor<CGRect>],
                              nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

public extension View {
    /// Marks this view as a start-guide spotlight target.
    func guideTarget(_ id: String) -> some View {
        anchorPreference(key: GuideTargetKey.self, value: .bounds) { [id: $0] }
    }
}

public struct StartGuide: View {
    let anchors: [String: CGRect]
    let speciesName: String
    let selectedID: String
    let onPick: (Species) -> Void
    let onDone: () -> Void

    /// `startAt` exists for the render harness (−1 = welcome sheet, 0… = spotlight step).
    /// `selectedID`/`onPick` drive the welcome sheet's seed picker; the model owns the
    /// selection, so defaults keep harness/preview call sites picker-less but compiling.
    public init(anchors: [String: CGRect], speciesName: String,
                selectedID: String = SpeciesCatalog.starter.id,
                onPick: @escaping (Species) -> Void = { _ in },
                startAt: Int = -1, onDone: @escaping () -> Void) {
        self.anchors = anchors; self.speciesName = speciesName
        self.selectedID = selectedID; self.onPick = onPick; self.onDone = onDone
        _step = State(initialValue: startAt)
    }

    @State private var step: Int
    @State private var bubbleHeight: CGFloat = 120
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // KO-first copy (round 3, spec D1 — VoiceOver stays EN this round).
    private var steps: [(id: String, title: String, body: String, pad: CGFloat)] {
        [("plant", "나의 \(speciesName)",
          "실제 시계를 따라 매일 조금씩 자라요. 톡톡 두드려도 빨리 자라지 않아요.", 6),
         ("water", "물 한 방울",
          "물방울을 눌러 물을 주세요. 조금만 — 흠뻑 주면 오히려 힘들어해요.", 10),
         ("shelf", "압화집에 눌러 두기",
          "꽃이 활짝 피면 여기에 눌러 간직해요. 여섯 송이를 모아 보세요.", 6)]
    }

    // Fixed warm-cream card colors (the mockup keeps the guide light on every band/scheme;
    // the dim layer guarantees contrast behind it).
    private let cardInk = Color(red: 0.29, green: 0.23, blue: 0.16)      // #4A3B2A
    private let cardSoft = Color(red: 0.49, green: 0.42, blue: 0.33)
    private let accent = Color(red: 0.37, green: 0.56, blue: 0.27)       // sprout green

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                if step >= 0, let rect = spotRect(step) {
                    spotlight(rect: rect, in: geo.size)
                    bubble(for: steps[step], near: rect, in: geo.size)
                } else {
                    Color(red: 0.08, green: 0.05, blue: 0.02).opacity(0.4)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {}                   // a bare Color leaks taps to the
                                                           // nav/share/water buttons beneath
                    // The picker makes the sheet tall; SE-class screens (667pt) can't fit
                    // it, so fall back to scrolling rather than clipping the title off.
                    ViewThatFits(in: .vertical) {
                        welcomeSheet
                        ScrollView(showsIndicators: false) { welcomeSheet }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom))
                }
                if step >= 0 {                             // no Skip on the seed-choice sheet —
                    skip                                   // its CTA is the only sensible exit
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, Design.pad)
                        .padding(.top, 8)                  // the dimmed nav's own slot — anything
                }                                          // lower collides with the streak seal
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: step)
        .accessibilityAddTraits(.isModal)
    }

    private func spotRect(_ n: Int) -> CGRect? {
        anchors[steps[n].id].map { $0.insetBy(dx: -steps[n].pad, dy: -steps[n].pad) }
    }

    private func advance() {
        if step < steps.count - 1 { step += 1 } else { onDone() }
    }

    // MARK: spotlight + bubble

    // NOTE: no .ignoresSafeArea() here — the cutout rect is measured in the safe-area
    // space the anchors resolve in, and ignoring it shifts the drawing origin to the
    // physical screen top, landing the ring a status-bar-height too high on device.
    // SpotlightDim already paints 200pt past its bounds, so the dim still covers the
    // bleed. contentShape + the empty tap keep taps from leaking through the cutout.
    private func spotlight(rect: CGRect, in size: CGSize) -> some View {
        SpotlightDim(cutout: rect)
            .fill(Color(red: 0.08, green: 0.05, blue: 0.02).opacity(0.55),
                  style: FillStyle(eoFill: true))
            .overlay(
                RoundedRectangle(cornerRadius: Design.rLG)
                    .stroke(.white.opacity(0.9), lineWidth: 3)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY))
            .contentShape(Rectangle())
            .onTapGesture {}
    }

    private func bubble(for s: (id: String, title: String, body: String, pad: CGFloat),
                        near rect: CGRect, in size: CGSize) -> some View {
        let below = rect.midY < size.height * 0.5
        let y = below ? rect.maxY + 14 : rect.minY - 14 - bubbleHeight
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                SsakMark(.light).frame(width: 26, height: 26)
                Text(s.title).font(.myeongjoDisplay(15, relativeTo: .subheadline))
            }
            Text(s.body).font(.subheadline).foregroundStyle(cardSoft)
            HStack {
                dots(current: step)
                Spacer()
                Button(action: advance) {
                    Text(step == steps.count - 1 ? "키우러 가기 🌱" : "다음")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: Design.rSM).fill(accent))
                }
                .buttonStyle(.pressable)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Design.rMD)
            .fill(Color(red: 1, green: 0.99, blue: 0.97))
            .overlay(RoundedRectangle(cornerRadius: Design.rMD).strokeBorder(.white.opacity(0.65)))
            .shadow(color: Design.shadow.opacity(0.5), radius: 14, y: 8))
        .foregroundStyle(cardInk)
        .background(GeometryReader { g in
            Color.clear.onAppear { bubbleHeight = g.size.height }
                .onChange(of: g.size.height) { bubbleHeight = $0 }
        })
        .padding(.horizontal, Design.pad)
        .offset(y: max(8, y))
        .accessibilityElement(children: .contain)
    }

    // MARK: welcome sheet

    private var welcomeSheet: some View {
        VStack(spacing: 0) {
            SsakMark(.light).frame(width: 52, height: 52).padding(.bottom, 12)
            Text("꽃 한 송이 키우기")
                .font(.myeongjoDisplay(24, relativeTo: .title2)).tracking(2)
                .padding(.bottom, 8)
            Text("씨앗에서 꽃이 필 때까지 — 실제 시간을 따라, 천천히.")
                .font(.subheadline).foregroundStyle(cardSoft)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
                .padding(.bottom, 18)
            Text("첫 씨앗을 골라 주세요")
                .font(.myeongjo(12, relativeTo: .footnote)).tracking(2)
                .foregroundStyle(cardSoft)
                .padding(.bottom, 10)
            speciesGrid
                .padding(.bottom, 20)
            Button(action: advance) {
                Text("씨앗 심기")
                    .font(.headline)                                   // the Toss 17/600 CTA slot
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)         // TDS BottomCTA: 52pt, r16
                    .background(RoundedRectangle(cornerRadius: Design.rMD).fill(accent))
            }
            .buttonStyle(.pressable)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: Design.rLG)
            .fill(LinearGradient(colors: [Color(red: 1, green: 0.99, blue: 0.97),
                                          Color(red: 0.98, green: 0.95, blue: 0.88)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: Design.rLG).strokeBorder(.white.opacity(0.65)))
            .shadow(color: Design.shadow.opacity(0.4), radius: 20, y: -4))
        .foregroundStyle(cardInk)
        .padding(.horizontal, Design.pad)
        .padding(.bottom, Design.pad)
        .accessibilityElement(children: .contain)
    }

    // The seed picker: all six species as bloom portraits (the promise, not the seed —
    // every seed cell would look identical). Selection lives in the model via onPick.
    private var speciesGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                  spacing: 12) {
            ForEach(SpeciesCatalog.all) { sp in
                let picked = sp.id == selectedID
                Button { onPick(sp) } label: {
                    VStack(spacing: 6) {
                        PlantView(species: sp, stage: .bloom, wall: false, board: false)
                            .frame(width: 76, height: 84)
                        Text(sp.nameKO)
                            .font(.myeongjo(13, relativeTo: .footnote)).tracking(1)
                            .fontWeight(picked ? .semibold : .regular)
                    }
                    .frame(maxWidth: .infinity, minHeight: 124)
                    .background(RoundedRectangle(cornerRadius: Design.rSM)
                        .fill(picked ? accent.opacity(0.14) : Color.black.opacity(0.03)))
                    .overlay(RoundedRectangle(cornerRadius: Design.rSM)
                        .strokeBorder(picked ? accent : .black.opacity(0.08),
                                      lineWidth: picked ? 2 : 1))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(sp.nameEN)
                .accessibilityAddTraits(picked ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    // One dot per coach mark — the welcome sheet is a choice, not a step.
    private func dots(current: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? accent : Color(red: 0.85, green: 0.80, blue: 0.70))
                    .frame(width: i == current ? 18 : 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(steps.count)")
    }

    private var skip: some View {
        Button(action: onDone) {
            Text("건너뛰기")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(cardInk)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)                                  // ≥44pt target
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .background(Capsule().fill(.white.opacity(0.5)).frame(height: 32))
        .accessibilityLabel("Skip the start guide")
    }
}

/// Full-screen dim with a rounded-rect cutout (even-odd fill).
struct SpotlightDim: Shape {
    let cutout: CGRect
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addRect(r.insetBy(dx: -200, dy: -200))     // covers the safe-area bleed
        p.addRoundedRect(in: cutout, cornerSize: CGSize(width: Design.rLG, height: Design.rLG))
        return p
    }
}
