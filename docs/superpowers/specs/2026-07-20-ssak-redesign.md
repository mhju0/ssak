# Ssak (싹) — UI Redesign & App Icon Spec

**Date:** 2026-07-20
**Status:** Drafted in brainstorming session with Michael Ju; hardened against a 4-way adversarial red-team (2026-07-20). Pending user review before writing-plans.
**Extends:** `2026-07-19-ssak-design.md` (concept, growth model, six species — all unchanged). This spec covers **only the visual/UI layer**. No gameplay, logic, persistence, or species-art changes.

**Two plans will come out of this spec:** **Plan A — UI redesign** (screens, glass, sky, a11y) and **Plan B — app-icon pipeline** (asset delivery). Keeping the icon separate because its work (asset catalog, Icon Composer, build-setting wiring) is orthogonal to the SwiftUI screens.

---

## 0. Goal & guardrails

Elevate Ssak's UI to "clean, calm, Apple-Design-Award" quality while staying inside the project's soul and scope.

**In scope (Plan A):** re-spaced onboarding; windowsill with a floating **Liquid Glass** Water control detached from the nav, a quiet top-right glass share, a **real-time sky**, a faint **싹 watermark**, and a gauge-only status cluster; a light Shelf restyle; **Liquid Glass** on tab bar / controls / sheets; **accessibility** to production bar.

**In scope (Plan B):** the **Bloom-Point** app icon delivered as an iOS 26 layered asset + fallback.

**Guardrails (hard lines)**
- `SsakCore` (gameplay/logic/persistence) **untouched**; its tests pass unchanged.
- `SsakArt` species drawings **untouched**. Only `Backdrop`/`PlantView` gain a wall toggle, plus one new `SsakMark`.
- **iOS 16 min deployment retained.** Liquid Glass is progressive enhancement (iOS 26+) with a `.ultraThinMaterial`/opaque fallback — never a hard gate.
- **Both packages also build for `macOS 13`** (render harness + tests run on the Mac). All iOS-26-only API must be gated so the **macOS module still compiles** — see §1.4.
- **No sound, no haptics** ([ADR-0002](../../adr/0002-drop-haptics.md), base §10). Levers: layout, color, type, motion, glass.
- Portrait-only, iPhone-only, offline, no dependencies. "Finishable first."

---

## 1. Design language

### 1.1 Palette (existing, reused)
| Token | Hex | Use |
|---|---|---|
| cream ground | `#FCF7EB` / grad `#FCF8EE→#E7F0DA` | day sky / app ground |
| ink (adaptive) | `#473828` light · `#ECE4D5` dark | primary text (see §3.4 adaptive rule) |
| sage / sprout | `#5B9A4F`,`#6EAE59`,`#80BF69`, deep `#4E8A44` | leaves, accents |
| terracotta | `#CF7A54`→`#9E523B` | pot |
| marigold gold | `#E8A23A` / bud `#F7CE78→#E1962C` | single warm accent, bud |
| water blue | `#5C9EDB` | Water action, gauge |
| overwater text | `#7A4E08` (deep amber-brown, ≥4.5:1 on cream) | the nudge line — see §5 |

### 1.2 Real-time sky (new) — **all light-mode bands stay light so ink text always reads**
`TimeBand` derived from the injected `now`. Deliberately warm and *light* across the day so the plant, name, and status never need a color flip and never clash with the (cream) Shelf on a tab switch:
| Band | Hours (local) | Wall gradient (top→bottom) | ink text ratio |
|---|---|---|---|
| dawn | 05–08 | `#FBE9CE → #F4DEC6` warm gold | ≥ 6:1 |
| day | 08–17 | `#FCF8EE → #E7F0DA` cream | ≥ 8:1 |
| dusk | 17–20 | `#F7DFC6 → #EAC9AE` amber | ≥ 5.5:1 |
| night | 20–05 | `#E7E2EC → #D9D3E0` soft dusk-mauve (**light, not indigo**) | ≥ 6:1 |
Bands **cross-fade** over the ~1h boundary. **System Dark Mode** is a separate axis (§3.4): in dark mode both screens use a warm-dark ground with light text; the band only nudges hue.

**Determinism:** `SkyBackdrop(now:)` derives the band **purely from the injected `now`** — no internal clock read. The *interactive* `WindowsillView` wraps it in a `TimelineView(.periodic(...))` that feeds `context.date` back through the same pure derivation to keep it live; the **render harness constructs `SkyBackdrop(now: fixedDate)` directly (no TimelineView)** so PNG references are reproducible. The live clock read is cosmetic and test-exempt; streak/watered logic stays `now`-injected.

### 1.3 Typography
- **Serif (New York)** for wordmark / species names / titles (upright), **with Dynamic Type**: `Font.system(.title2, design: .serif)` — the `TextStyle` overload *does* carry `design:` and scales. (Do **not** use `Font.system(size:relativeTo:)` — it doesn't exist; the `relativeTo:` overload is only on `Font.custom`.)
- **SF / SF Rounded** for UI via semantic styles.
- `@ScaledMetric` for any spacing that must track type size. Target legible to AX3, graceful to AX5.

### 1.4 Liquid Glass (iOS 26+, macOS-safe, fallback + a11y aware)
A **`ViewModifier` struct** (not a bare extension — a free `View` method can't host `@Environment`), gated so the **macOS build compiles** (`if #available(iOS 26.0, *)` does *not* raise the macOS floor, and glass APIs are macOS-26-only):
```swift
// GlassBackground.swift
struct SsakGlass<S: InsettableShape>: ViewModifier {   // InsettableShape → strokeBorder is available
    let shape: S; let tint: Color?; let interactive: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        #if os(iOS)                                    // macOS render build always takes the fallback → deterministic
        if #available(iOS 26.0, *), !reduceTransparency {
            var glass = Glass.regular
            if let tint { glass = glass.tint(tint) }   // Glass.tint takes a non-optional Color → apply only when set
            glass = glass.interactive(interactive)
            return AnyView(content.glassEffect(glass, in: shape)
                .overlay(contrast == .increased ? shape.strokeBorder(.primary.opacity(0.3)) : nil))
        }
        #endif
        let fill: AnyShapeStyle = reduceTransparency
            ? AnyShapeStyle(tint?.opacity(0.16) ?? Color(white: 0.96))   // opaque
            : AnyShapeStyle(.ultraThinMaterial)
        return AnyView(content.background(fill, in: shape)
            .overlay(shape.strokeBorder(.white.opacity(0.25))))
    }
}
extension View {
    func ssakGlass<S: InsettableShape>(_ shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(SsakGlass(shape: shape, tint: tint, interactive: interactive))
    }
}
```
- **Floating Water pill** → `.buttonStyle(.glassProminent)` (26+) / `.borderedProminent` capsule (fallback), water-blue tint, interactive.
- **Top-corner icons** → `.buttonStyle(.glass)` in a `GlassEffectContainer`.
- **Tab bar** auto-adopts glass on the iOS 26 SDK; fallback is the standard bar.

### 1.5 Motion (existing scope only)
Idle sway, gauge ripple, bloom-open ceremony, sky cross-fade — all gated by `@Environment(\.accessibilityReduceMotion)` (static when reduced). No sound/haptics.

### 1.6 Spacing
8pt grid; side margins 20pt; group spacing 24–32pt; tap targets ≥44pt; the Water control ≥64pt tall.

---

## 2. Screen-by-screen

### 2.1 Onboarding — re-space (the cramping fix)
Same three beats and copy, rebuilt for air:
| Element | Now | Target |
|---|---|---|
| top inset | `Spacer(minLength: 8)` | balanced `Spacer()` |
| title → subtitle | 4pt | 12pt |
| title block → beats | 22pt | 44pt |
| between beats | 18pt | 28pt |
| beats → CTA | flexible | `Spacer()` + generous |
| CTA bottom | 28pt | safe-area + 24pt |
Dynamic Type reflow; CTA never clipped. Microcopy kept; one tweak — *"Watch the drop — it reads the soil."* No animated hero (user's choice).

### 2.2 Windowsill — the core redesign
Zones, top→bottom:
1. **Status bar (top).** `StreakBadge` (left); a `GlassEffectContainer` with `WateredTodayTick` + a **quiet glass Share icon** (right). These two signals live **here only** (not duplicated below). 20pt margins, ≥44pt targets.
2. **Hero.** `SkyBackdrop(now:)` fills the frame; a faint **`SpeciesWatermark`** (~6% 싹, species-tinted) behind; `PlantView(wall: false)` centered with ~50%+ negative space; idle sway. **Tap-the-plant waters** (ripple) in addition to the button.
3. **Name block.** EN serif + KO secondary, in the **adaptive ink color** (§3.4) so it reads on every band and in dark mode.
4. **Status cluster (quiet, gauge-only).** Just `DropGauge` (+ a small moisture read) — the streak/tick are **not** repeated here. This is the fix for "the gauge is mixed in with the buttons": the read-out is now visually separate from *and* de-duplicated against the action.
5. **Overwater nudge (conditional).** The gentle line, deep-amber `#7A4E08`, with its 💧 as a non-color cue.
6. **Floating Water control.** A large Liquid Glass capsule, water-blue, **floating in the lower third — clearly above and separated from the tab bar** (it must not sit flush against it, or the two glass surfaces re-couple, undoing "Water out of the nav"). One primary verb; never disabled (freedom — over-full shows the nudge).

**Screenshot-ready / chrome-light (base §6):** in the idle "just looking" state (no recent interaction) the **Water pill and tab bar recede** (fade + slight translate) so the plant + sky stand alone; they return on tap/scroll. Only the tab bar anchors the very bottom edge.

**Bloom moment:** at `stage == .bloom` the Share icon promotes to a labeled CTA ("Share your bloom") and the plant plays the bloom-open ceremony; press-to-shelf stays on the Shelf.

### 2.3 Shelf — light restyle only
Keep the 6-slot grid + replant. Empty slots become a **faint `SsakMark(.mono)` sprout glyph** (generic — *not* a per-species outline, which would require touching species art). Match the glass tab bar; 8pt spacing; "Garden complete 🌸" kept.

### 2.4 Navigation (`RootView`)
Two-tab `TabView` (Windowsill · Shelf), glass bar on 26+. `reconcileOnOpen` on `scenePhase == .active` and share presentation **unchanged**.

### 2.5 Share card (`BloomCard`)
Add the faint 싹 watermark; keep the clean cream frame — **no** real-time sky (timeless, and it dodges the `ImageRenderer` determinism trap). Otherwise unchanged.

### 2.6 App icon — Bloom-Point (Plan B)
Chosen mark: two green cotyledons framing a **furled gold bud** (bloom implied, never opened). **Designed and proofed this session** — rendered via headless Chrome at 1024/40px and as a flat mono silhouette (proof PNGs in the working scratchpad); the **SVG source is not yet committed** — Plan B commits it (mirroring commit `0e850b7`'s reference-render pattern).
- Ported to a SwiftUI `SsakMark` Shape (SsakArt) for reuse as icon + watermark + shelf glyph.
- **Delivery (Plan B):** an `Assets.xcassets/AppIcon` set. Wire it explicitly in `project.yml`: add `Assets.xcassets` to the App target `sources` and set `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`. Ship the **iOS 26 layered `.icon`** (Icon Composer → Light/Dark/Tinted/Clear) **plus a single 1024 PNG fallback** — not the full legacy size set. Add an iOS-16 icon-render sanity check to the manual list.
- Variant recipes: Appendix A.

---

## 3. Component architecture

### 3.1 Page-level (modified): `OnboardingView`, `WindowsillView`, `ShelfView`, `RootView`, `BloomCard` — same entry points, reworked internals.

### 3.2 New reusable components
| Component | Package | Props / API | Purpose |
|---|---|---|---|
| `SkyBackdrop` | SsakArt | `init(now: Date)` (pure band derivation) | real-time wall behind the plant |
| `SsakMark` | SsakArt | `init(_ variant: Variant = .light)`, `Variant ∈ {light,dark,tinted,mono,glass}` | sprout mark: icon + watermark + shelf glyph |
| `SpeciesWatermark` | SsakApp | `init(species:opacity:)` | faint ghosted mark behind hero |
| `WaterButton` | SsakApp | `init(isOverfull:Bool, action:@escaping ()->Void)` | floating glass primary pill (+ fallback) |
| `GlassIconButton` | SsakApp | `init(systemImage:label:prominent:action:)` | top-corner glass icon (share) |
| `StatusCluster` | SsakApp | `init(fraction: Double, band: ClosedRange<Double>)` — **gauge only** (`band` = moisture range) | quiet moisture read-out |
| `SsakGlass` / `.ssakGlass` | SsakApp | ViewModifier (see §1.4) | glass-or-fallback, a11y-aware, macOS-safe |

### 3.3 Modified components
- `Backdrop.swift` (`Sill`): factor the wall gradient into `SkyBackdrop`; `Sill` keeps the board/ledge.
- `PlantView.swift`: add `wall: Bool = true`. **`wall: true` re-renders the exact old static cream wall** (the current `Sill` colors, *not* the live `SkyBackdrop`) so every default caller stays **byte-identical**. `WindowsillView` alone passes `wall: false` and layers `SkyBackdrop` itself.
- `DropGauge`/`StreakBadge`/`WateredTodayTick`: visuals unchanged; regrouped (gauge → `StatusCluster`; streak/tick → top bar).

### 3.4 State ownership & adaptive color
- `GardenModel` (`@MainActor ObservableObject`) stays the single source of truth. **No new persistent fields.**
- `TimeBand` is **derived** from the injected `now` (§1.2) — not stored, no new logic clock read.
- **Adaptive text color:** replace hardcoded ink `#473828` / bare `.secondary` with a color that responds to `@Environment(\.colorScheme)` (ink in light, `#ECE4D5` in dark). Because all *light-mode* bands stay light (§1.2), ink always clears ≥4.5:1; dark mode uses the dark ground + light text. No per-band text threading needed.
- A11y flags via `@Environment(\.accessibilityReduceTransparency / .accessibilityReduceMotion / .colorSchemeContrast)`.

---

## 4. States & edge cases

| Screen | Loading | Empty | Error | Disabled | Notable edge cases |
|---|---|---|---|---|---|
| Onboarding | none | — | — | CTA always on | Dynamic Type AX5, dark mode, SE |
| Windowsill | none — local state instant | never empty | persistence `try?` (local, non-fatal) — silent, documented | Water **never disabled** (over-full → nudge) | fresh plant (no `lastWateredAt`) → gauge/streak "—"; **dark mode**; midnight/DST streak roll; band cross-fade while open; longest KO name; Reduce Transparency → solid; Reduce Motion → still |
| Shelf | none | 0 collected → six `SsakMark(.mono)` glyphs | — | replant only when collected | all six → "Garden complete"; dark mode |
| Share | `ImageRenderer` nil → guarded no-op | — | render nil → log, no crash | — | fixed-size card ignores Dynamic Type |
| Icon (Plan B) | — | — | Clear/Glass is OS-composited (not statically previewable) | — | tinted legibility @40px (proofed); iOS-16 render path |

---

## 5. Accessibility

- **Dynamic Type** everywhere via semantic fonts (serif included, §1.3); no clipping to AX3, graceful to AX5.
- **VoiceOver** (currently zero a11y code in the app — all of this is net-new):
  - Hero: combined label *"Marigold, budding, soil moist"* (**omit "watered today"** — the top-bar tick carries it, avoiding double-speak). Tap-to-water exposed as an `.accessibilityAction`.
  - `WaterButton` label "Water", hint "Waters your plant"; Share labeled.
  - `StreakBadge` → "Streak, N days"; `WateredTodayTick` → "Watered today"; `DropGauge` → "Soil moisture, N percent".
  - Decorative art (`SkyBackdrop`, `SpeciesWatermark`, `PlantView`) `.accessibilityHidden(true)`.
- **Contrast (recomputed, on real adjacent colors):**
  - Overwater **text** is a 12–13pt line → needs AA **4.5:1**. The current `#D1851F` is ~2.8:1 (**fails**) and can't reach 3:1 on any background. Fix → **`#7A4E08`** (deep amber-brown, ≥4.5:1 on cream), kept warm/gentle, with the 💧 as a non-color cue.
  - `DropGauge` dry-fill `#EB9E38` is a **graphic**, judged at 3:1 against its **own** drop background `#D2E3F2` (not cream) — it clears that bar, so it **stays unchanged** (resolves the earlier false "2.1:1 on cream" premise, which used the wrong adjacent color).
  - Verify all text ≥4.5:1 on **every** band (§1.2 ratios) and in dark mode.
- **Reduce Transparency** → opaque (handled in `SsakGlass`). **Reduce Motion** → no sway/ripple/instant sky. **Increased Contrast** → glass hairline border (§1.4).
- **Tap targets** ≥44pt; Water ≥64pt.

---

## 6. Files to create / update

**Create** — `SsakArt/Sources/SsakArt/SkyBackdrop.swift`, `SsakArt/Sources/SsakArt/SsakMark.swift`, `SsakApp/Sources/SsakApp/GlassBackground.swift` (`SsakGlass`+`WaterButton`+`GlassIconButton`), `SsakApp/Sources/SsakApp/SpeciesWatermark.swift`, `SsakApp/Sources/SsakApp/StatusCluster.swift`. **(Plan B)** `Assets.xcassets/AppIcon` + layered `.icon`.

**Update** — `SsakApp/Sources/SsakApp/OnboardingView.swift`, `WindowsillView.swift`, `ShelfView.swift`, `RootView.swift`, `BloomCard.swift`; `SsakArt/Sources/SsakArt/Backdrop.swift`, **`SsakArt/Sources/SsakArt/PlantView.swift`** (the `wall` param); `SsakApp/Sources/SsakAppRender/Render.swift` (new/updated renders: respaced onboarding, windowsill × TimeBand, mono-glyph shelf, dark mode). **(Plan B)** `project.yml` (AppIcon wiring; retain iOS 16).

**Unchanged — but verified byte-stable, not merely by signature:** all `SsakCore` + tests; all `SsakArt` species drawings; `SsakArtRender/Render.swift` and `RenderInvariantsTests` (`RenderInvariantsTests` only asserts non-nil + stage-distinctness, so it can **not** guard the wall — the real guard is a **reference-image diff** confirming `PlantView(wall: true)` output is byte-identical); `GardenModelTests`.

---

## 7. Verification

**Automated / headless** — `cd SsakApp && swift run SsakAppRender` → regenerate PNGs; **reference-diff** onboarding, windowsill (bloom/dry/nursing/overwater × dawn/day/dusk/night × light/dark), shelf (empty/partial/complete), share card. Prove `PlantView(wall: true)` renders **byte-identical** to pre-change (the real Sill-split guard). `swift test` in all three packages green (macOS build must compile — §1.4 gate). Icon SVG variants proofed via headless Chrome.

**Manual (Simulator + device)**
- [ ] Water pill **and** tap-the-plant both water; ripple responds.
- [ ] Share (top-right) opens sheet; card crisp.
- [ ] Background→foreground: `reconcileOnOpen` grows the plant.
- [ ] Sky matches time of day; cross-fades near a boundary; **idle chrome fades** so the plant stands alone.
- [ ] Dynamic Type AX1→AX5: no clipping.
- [ ] VoiceOver: hero, Water, Share, streak, tick, gauge, tabs all labeled; no double-speak.
- [ ] Light **and** Dark mode both coherent across a Windowsill↔Shelf tab switch.
- [ ] Reduce Transparency (glass→solid); Reduce Motion (still).
- [ ] iOS 26 (real glass) **and** iOS 16 (fallback) devices.
- [ ] iPhone SE and Pro Max layouts.
- [ ] (Plan B) App icon on home screen in light/dark/tinted; iOS-16 render path.

**Edge cases** — fresh plant, midnight/DST roll, band boundary while open, longest KO name, over-full nudge, garden-complete, dark mode on both screens.

**Regression risks**
1. `PlantView`/`Sill` refactor → guarded by `wall: true` re-rendering the exact old wall; **reference-diff** proves byte-stability (not `RenderInvariantsTests`).
2. Glass availability branch → **macOS module must compile** (§1.4 `#if os(iOS)`); test both iOS 16 and 26 runtime paths; fallback never blanks.
3. Tab selection & share presentation unchanged — smoke test.
4. Sky determinism → `SkyBackdrop(now:)` is pure; the live `TimelineView` clock read is cosmetic/test-exempt; logic stays `now`-injected.
5. Overwater text recolor — confirm it still reads "gentle."
6. No `SsakCore` edits — logic tests are the tripwire.

---

## 8. Out of scope (someday)
Full-screen "place" nav, diegetic-only watering, haptics, sound, notifications, animated onboarding hero, italic species names, iPad/landscape, sharing the shelf, any AI/raster art.

---

## Appendix A — Bloom-Point icon (reproducible)
Canvas 220×220, squircle `rx≈49`, mark centered `x=110`, ~53% frame height, calm corners.
- **Stem** `M110 146 C110 154 110 160 110 166`, 8pt round `#4C8642`.
- **Left leaf** `M108 147 C88 151 64 145 54 122 C66 112 90 128 108 147 Z`, grad `#7EBA61→#4C8642`.
- **Right leaf** `M112 147 C132 151 156 145 166 124 C154 114 130 130 112 147 Z`, grad `#6BA956→#47823E`.
- **Bud (rounded furl)** `M110 146 C94 120 96 88 106 60 C107 55 113 55 114 60 C124 88 126 120 110 146 Z`, grad `#F7CE78→#E1962C`; furl seam `#C9812A@0.5`; left highlight `#FADFA0@0.55`.
- **Contact shadow** radial ellipse `cx110 cy170 rx44 ry9`, `#473828@0.18→0`.

**Variants** — Light: cream→sage bg, mark as above. Dark: bg `#2A241C→#17130F` + warm radial glow; leaves `#8AC86C→#4F9145`; bud `#FAD583→#E89B32`. Tinted: dark bg, single-tint grayscale source (bud lightest `#DCE7C8`). Clear/Glass: OS-composited frosted (translucent white relief + specular edges over the layered art).

---

## Decision ledger
| # | Decision | Choice |
|---|---|---|
| R1 | Home layout | Liquid Glass dock + 2 tabs; Water = floating pill, decoupled from nav, idle-fading |
| R2 | Onboarding | Re-space existing 3-beat screen (no animated hero) |
| R3 | Share | Quiet top-right glass icon; CTA at bloom |
| R4 | Sky | Real-time warm gradient, **all light-mode bands light** (night = dusk-mauve); dark mode = warm-dark ground; pure `now`-derived |
| R5 | Watermark | Faint 싹 behind hero + share card |
| R6 | Typography | Upright serif names via `Font.system(.style, design:.serif)`; SF for UI; Dynamic Type |
| R7 | App icon | Bloom-Point; **Plan B** delivers the iOS 26 layered asset |
| R8 | Liquid Glass | `SsakGlass` ViewModifier; `#if os(iOS)` + iOS-26 avail; material/opaque fallback; Reduce-Transparency & Increased-Contrast aware |
| R9 | Guardrails | No SsakCore/species-art/gameplay/sound/haptics; macOS build must compile; portrait iPhone only |
