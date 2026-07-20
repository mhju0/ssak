# Ssak UI Redesign (Plan A) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`). **This plan is almost entirely UI** — there is no new game logic (guardrail: `SsakCore` untouched). **Three verification modes:** (a) screens are authored against the headless render→PNG→inspect loop (`swift run SsakAppRender`, reuse `SsakArt.pngData`); (b) the `PlantView`/`Sill` refactor is guarded by a **same-machine before/after render diff** (PNG output is environment-sensitive — the committed refs were rendered on another SDK and already differ on this host, so the guard diffs against a baseline rendered on the *same* machine, never the committed refs); (c) VoiceOver, tap/drag gestures, real Liquid Glass, and on-device Dynamic Type run only in a Simulator/device — flagged per task.

**Goal:** Ship the visual redesign in spec [`2026-07-20-ssak-redesign.md`](../specs/2026-07-20-ssak-redesign.md): a real-time sky windowsill with a floating Liquid Glass Water control decoupled from the nav, a quiet glass Share, a gauge-only status cluster, a faint 싹 watermark; re-spaced onboarding; a light Shelf restyle; Liquid Glass on tab bar / controls; and accessibility to a production bar — all inside the existing `SsakApp`/`SsakArt` packages, with **no gameplay, logic, persistence, or species-art changes.**

**Architecture:** Additive. New reusable pieces land in `SsakArt` (`SkyBackdrop`, `SsakMark`) and `SsakApp` (`SsakGlass` modifier, `WaterButton`, `GlassIconButton`, `SpeciesWatermark`, `StatusCluster`, adaptive-ink helpers). The five page views (`OnboardingView`, `WindowsillView`, `ShelfView`, `RootView`, `BloomCard`) keep their exact entry points (§3.1) and are reworked internally. `PlantView` gains one `wall: Bool = true` parameter that threads to `Sill`; **every existing caller keeps the default and renders byte-identical.** Liquid Glass is a progressive enhancement gated so the macOS render/test build still compiles.

**Tech Stack:** SwiftUI, `Glass`/`glassEffect`/`GlassEffectContainer` (iOS 26+, `#if os(iOS)`-gated), `.ultraThinMaterial` fallback, `@Environment` a11y flags, `ImageRenderer` (existing render harness).

## Global Constraints

- **`SsakCore` untouched; its tests pass unchanged.** No new persistent fields, no logic-clock reads. `TimeBand` is *derived* from an injected `now`, not stored. — verbatim (spec §0, §3.4).
- **`SsakArt` species drawings untouched.** Only `Backdrop.swift` (`Sill`) and `PlantView.swift` gain the `wall` toggle, plus two *new* SsakArt files (`SkyBackdrop`, `SsakMark`). — verbatim (spec §0).
- **iOS 16 min deployment retained; both packages still build for macOS 13.** All iOS-26-only glass API is inside `#if os(iOS)` + `if #available(iOS 26.0, *)`, so the macOS module compiles and takes the fallback branch — the deterministic render path. — verbatim (spec §0, §1.4).
- **No sound, no haptics** ([ADR-0002](../../adr/0002-drop-haptics.md)). Levers only: layout, color, type, motion, glass. Portrait-only, iPhone-only, offline, no dependencies. — verbatim (spec §0).
- **`PlantView(wall: true)` (the default) must render byte-identical to pre-change.** The guard is a **same-machine before/after render diff**: snapshot the renders with the pre-change code, re-render after the edit, `diff` the two on the *same host*. **PNG bytes are environment-sensitive** (verified: this macOS-26 host re-renders `all_species_grid.png` differently from the committed ref, but same-machine re-renders are byte-identical), so the committed refs must **not** be the comparison target. This is the real guard — not `RenderInvariantsTests` (which only asserts non-nil + stage-distinctness and cannot see the wall) — spec §6, §7 risk 1.
- **Text uses semantic Dynamic Type styles (spec §1.3), never fixed `Font.system(size:)`.** The app today has **17 fixed-size font sites and zero semantic styles**, so Dynamic Type is currently broken. Each view-rebuild task (6–9) converts its own sites as it goes — serif names/titles → `Font.system(.title2/.title3/…, design: .serif)` (the `TextStyle` overload carries `design:` and scales; **never** `Font.system(size:relativeTo:)`, which doesn't exist), UI → semantic styles. Task 10 audits AX1→AX5 and catches any straggler (`DropGauge`/`StreakBadge`). — spec §1.3, §5.

### Two refinements to the spec's design (deliberate, flagged)

1. **No `TimelineView` for the live sky.** Spec §1.2 sketches a `TimelineView(.periodic)` to keep the sky live while the app stays open. `RootView` already re-reads `Date()` and re-injects `now` into `WindowsillView` on every `scenePhase == .active` reconcile and every state change (`@Published`), so the sky already refreshes on every foreground and every watering — enough for a once-a-day game. Dropping `TimelineView` also makes the render harness deterministic for free (no live clock in the view tree). `// ponytail: no in-session live band cross-fade; add a TimelineView(.periodic) wrapper in WindowsillView only if same-session sky animation is ever wanted.` Keeps the spec's `SkyBackdrop(now:)` API exactly.
2. **`SkyBackdrop(now:calendar:)` — inject the calendar.** The band depends on the *local hour*, so a bare `now`-only derivation reading `Calendar.current` makes the windowsill reference PNGs vary by the render machine's timezone. Adding `calendar: Calendar = .current` (live app uses local; the harness passes its existing UTC `Self.cal`) matches this project's time-injection discipline and makes band renders reproducible. This extends the spec's `init(now:)` signature by one defaulted parameter — noted here so it is a conscious choice.

## Verification model (read before starting)

| Layer | How verified | Who |
|---|---|---|
| New reusable views (`SkyBackdrop`, `SsakMark`, glass primitives, `SpeciesWatermark`, `StatusCluster`) | `SsakAppRender`/`SsakArtRender` → PNG → open & inspect; fallback branch on macOS | headless (this env) |
| `PlantView`/`Sill` `wall` split | same-machine baseline: render → snapshot → edit → re-render → **`diff -rq`** the two = no differences (**not** vs committed refs — env-sensitive) | headless (this env) |
| Redesigned screens (Windowsill, Onboarding, Shelf, BloomCard) | render matrix (state × band × light/dark) → open; re-approve tracked references | headless (this env) |
| macOS compile gate (§1.4) | `swift build` in `SsakApp` + `SsakArt` (host = macOS) is green | headless (this env) |
| Real Liquid Glass, VoiceOver, tap/drag, on-device Dynamic Type, idle-chrome fade | Xcode Simulator / device | **user, on a Mac** |

---

### Task 1: Design primitives — adaptive ink/ground, `SsakGlass`, `WaterButton`, `GlassIconButton`

**Files:** Create `SsakApp/Sources/SsakApp/GlassBackground.swift` (the `SsakGlass` modifier + `WaterButton` + `GlassIconButton`, per spec §6) and `SsakApp/Sources/SsakApp/InkColors.swift` (adaptive ink/ground). Modify `SsakAppRender/Render.swift`.

**Interfaces (produce exactly — spec §1.4, §3.2):**
```swift
// InkColors.swift — reads @Environment(\.colorScheme); reliable in the render harness
// (which sets colorScheme explicitly) on both iOS and macOS. `.secondary` stays as-is (it adapts).
extension View { func inkText() -> some View }          // #473828 light · #ECE4D5 dark
struct SsakGround: ViewModifier { }                     // cream light · warm-dark (#2A241C→#17130F) dark
extension View { func ssakGround() -> some View }

// GlassBackground.swift — verbatim from spec §1.4
struct SsakGlass<S: InsettableShape>: ViewModifier {    // @Environment reduceTransparency + colorSchemeContrast
    // #if os(iOS) → iOS 26 glassEffect(_:in:) (+ increased-contrast strokeBorder); else material/opaque fallback
}
extension View { func ssakGlass<S: InsettableShape>(_ shape: S, tint: Color? = nil, interactive: Bool = false) -> some View }

public struct WaterButton: View {                       // ≥64pt tall; floating primary pill
    public init(isOverfull: Bool, action: @escaping () -> Void)
    // iOS26: .buttonStyle(.glassProminent), water-blue tint, .interactive; fallback: .borderedProminent capsule
}
public struct GlassIconButton: View {                   // top-corner glass icon (share)
    public init(systemImage: String, label: String, prominent: Bool = false, action: @escaping () -> Void)
    // iOS26: .buttonStyle(.glass) in a GlassEffectContainer; fallback: .bordered
}
```

- [ ] Step 1: `SsakGlass` verbatim from spec §1.4 (the `#if os(iOS)` + `if #available(iOS 26.0, *)` gate; material/opaque fallback; `reduceTransparency`/`colorSchemeContrast` aware). `.inkText()`/`SsakGround` reading `@Environment(\.colorScheme)`.
- [ ] Step 2: `WaterButton` and `GlassIconButton` composing `SsakGlass`/glass button styles with fallbacks. Water-blue `#5C9EDB`.
- [ ] Step 3: `Render.swift`: a `glass_primitives.png` on a light card + the **same** view `.environment(\.colorScheme, .dark)` → `glass_primitives_dark.png`. Both take the macOS fallback path (deterministic); open and confirm the pill reads ≥64pt and calm, the fallback never blanks.
- [ ] Step 4: `cd SsakApp && swift build && swift run SsakAppRender` green (this is the **macOS compile gate**, §1.4). Commit `feat(ui): glass primitives + adaptive ink (Plan A Task 1)`.

---

### Task 2: `SkyBackdrop` — the real-time sky (SsakArt)

**Files:** Create `SsakArt/Sources/SsakArt/SkyBackdrop.swift`. Modify `SsakAppRender/Render.swift`.

**Interfaces:**
```swift
public struct SkyBackdrop: View {
    public init(now: Date, calendar: Calendar = .current)   // pure band derivation; see refinement #2
}
enum TimeBand { case dawn, day, dusk, night }               // derived purely from calendar.component(.hour, from: now)
```
Bands & gradients **verbatim from spec §1.2** (all light-mode bands stay *light* so ink always reads; night = dusk-mauve `#E7E2EC→#D9D3E0`, not indigo). **Cross-fade** over the ~1h boundary: blend the two adjacent band gradients by a 0…1 factor computed from minutes-into-boundary — a pure function of `now`. **Dark mode is a separate axis (§3.4):** read `@Environment(\.colorScheme)`; in dark mode use the warm-dark ground (`#2A241C→#17130F` + faint radial glow), the band only nudges hue. No iOS-26 API → compiles on macOS 13.

- [ ] Step 1: `TimeBand.from(hour:)` + gradient table (spec §1.2); boundary cross-fade blend; light/dark axis via `@Environment(\.colorScheme)`.
- [ ] Step 2: `Render.swift`: render `SkyBackdrop(now: day0h(H), calendar: Self.cal)` for H ∈ {6 dawn, 12 day, 18 dusk, 22 night} × {light, `.environment(\.colorScheme,.dark)`} → `sky_<band>_<mode>.png`. Open all 8; confirm every light band is light and warm, dark is warm-dark.
- [ ] Step 3: Commit `feat(ui): real-time sky backdrop (Plan A Task 2)`.

---

### Task 3: `PlantView(wall:)` + `Sill(wall:)` split — the byte-stability task (SsakArt)

**Files:** Modify `SsakArt/Sources/SsakArt/Backdrop.swift` (`Sill`) and `SsakArt/Sources/SsakArt/PlantView.swift`.

**Interfaces (spec §3.3):**
```swift
public struct Sill: View { public init(wall: Bool = true) }   // wall:true → EXACT current gradient+board; wall:false → board/ledge only
public struct PlantView: View {
    public init(species: Species, stage: GrowthStage, droop: Double = 0, wall: Bool = true)  // forwards wall → Sill(wall:)
}
```
`wall: true` re-renders the **exact old static cream wall** (the current `Sill` LinearGradient `#FCF7E8→#F7EDD9` + board, `Backdrop.swift:10–19`) — *not* `SkyBackdrop`. Only `WindowsillView` (Task 6) passes `wall: false` and layers `SkyBackdrop` itself. Do the split by wrapping the current gradient in `if wall { … }`; the board/ledge always draws. Nothing else in `Sill`/`PlantView` moves.

- [ ] Step 1: **Capture a same-machine baseline BEFORE editing** (committed refs are env-shifted and can't be the target; same-machine re-render is byte-identical): `cd SsakArt && swift run SsakArtRender && rm -rf /tmp/ssakart-base && cp -R rendered /tmp/ssakart-base && git checkout -- rendered/`.
- [ ] Step 2: Add `wall: Bool = true` to `Sill.init` and `PlantView.init`; gate only the wall LinearGradient on `wall`; `PlantView` passes `wall` into `Sill(wall:)`.
- [ ] Step 3: **Byte-stability guard.** `swift run SsakArtRender && diff -rq rendered /tmp/ssakart-base` → **must report no differences** (every render — incl. `marigold_row`, `marigold_bloom_portrait`, `all_species_grid` — routes `PlantView` at its default `wall: true`; zero bytes may change vs the baseline). Non-empty diff → the default path was disturbed; fix before proceeding. Then `git checkout -- rendered/` (leave the committed env-shifted refs untouched — species art is unchanged, §0).
- [ ] Step 4: `swift test` in SsakArt green (`RenderInvariantsTests` still passes — note it does *not* guard the wall; the same-machine diff above does). Commit `refactor(art): PlantView wall toggle; Sill wall/board split — byte-identical default (Plan A Task 3)`.

---

### Task 4: `SsakMark` — the sprout mark (SsakArt; shared with Plan B)

**Files:** Create `SsakArt/Sources/SsakArt/SsakMark.swift`. Modify `SsakAppRender/Render.swift` (**not** `SsakArtRender/Render.swift` — spec §6 keeps that file Unchanged as the clean byte-stability tripwire; `SsakAppRender` already `import SsakArt`, so it can render `SsakMark`).

**Interfaces (spec §3.2, §2.6, Appendix A):**
```swift
public struct SsakMark: View {
    public enum Variant { case light, dark, tinted, mono, glass }
    public init(_ variant: Variant = .light)
}
public struct SsakMarkPath: Shape {          // MUST be public: SsakApp's SpeciesWatermark (T5) + BloomCard (T9)
    public init()                            // consume this raw silhouette cross-module (per-species tint at 6% needs
    public func path(in rect: CGRect) -> Path // the Shape, not the fixed-fill SsakMark(.mono) view)
}                                            // the pure silhouette (two cotyledons + furled bud + stem)
```
The Bloom-Point mark (two green cotyledons framing a furled gold bud) from **Appendix A** path data, ported to SwiftUI. `mono` = single-color silhouette (`SsakMarkPath` filled) for the shelf glyph + watermark; `light`/`dark`/`tinted` = the styled variants (Appendix A recipes). `glass` reuses `SsakMarkPath` as the relief shape. macOS-safe (no iOS-26 API).

- [ ] Step 1: `SsakMarkPath` (public) from Appendix A (stem, left/right leaf, bud furl, contact shadow), then the styled `Variant`s.
- [ ] Step 2: In `SsakAppRender/Render.swift`: `ssakmark_<variant>.png` for all five (leave `SsakArtRender/Render.swift` untouched). Open; confirm the mark reads as a sprout at both a large (icon) and small (shelf-slot) frame.
- [ ] Step 3: Commit `feat(art): SsakMark sprout mark + variants (Plan A Task 4)`.

---

### Task 5: `SpeciesWatermark` + `StatusCluster` (SsakApp)

**Files:** Create `SsakApp/Sources/SsakApp/SpeciesWatermark.swift`, `SsakApp/Sources/SsakApp/StatusCluster.swift`. Modify `SsakAppRender/Render.swift`.

**Interfaces (spec §3.2):**
```swift
public struct SpeciesWatermark: View {
    public init(species: Species, opacity: Double = 0.06)   // ghosted SsakMarkPath, species-tinted (palette.foliage)
}
public struct StatusCluster: View {
    public init(fraction: Double, band: ClosedRange<Double>) // GAUGE ONLY (+ a small moisture read); no streak/tick here
}
```
`SpeciesWatermark` = `SsakMark`'s silhouette tinted with `SpeciesPalette.palette(for: species.id).foliage` at ~6% opacity, sits behind the hero. `StatusCluster` wraps the existing `DropGauge` + a small "moist/dry" caption — deliberately **de-duplicated** from the streak/tick (which live only in the top bar, spec §2.2 zone 1 & 4).

- [ ] Step 1: Author both (reuse `DropGauge`'s **static visuals unchanged** — spec §3.3). Add the spec §1.5 **gauge ripple** as a subtle animated water-surface overlay *inside `StatusCluster`* (not a change to `DropGauge`'s shape), gated by `accessibilityReduceMotion` (static when reduced) — verified in the Simulator; the headless render is its static frame.
- [ ] Step 2: `Render.swift`: `watermark_marigold.png` (over a band), `status_cluster_{dry,ok}.png` (static frame). Open; watermark must be *faint*, cluster must read as a quiet read-out.
- [ ] Step 3: Commit `feat(ui): species watermark + gauge-only status cluster (Plan A Task 5)`.

---

### Task 6: WindowsillView redesign — the core (SsakApp)

**Files:** Rewrite internals of `SsakApp/Sources/SsakApp/WindowsillView.swift` (**same `init(model:now:onWater:onShare:)`**, spec §3.1). Modify `SsakAppRender/Render.swift`.

**Zones, top→bottom (spec §2.2):**
1. **Status bar:** `StreakBadge` (left); `WateredTodayTick` + a quiet glass Share (`GlassIconButton`) (right). These two signals live **here only**. 20pt margins, ≥44pt targets. `GlassEffectContainer` is iOS/macOS-26-only, so wrap the right cluster with the **same structural gate + fallback as Task 1**: `#if os(iOS)` + `if #available(iOS 26.0, *)` → `GlassEffectContainer { tick; share }`, `#else`/`else` → a plain `HStack { tick; share }`. Without the explicit `else` the two signals vanish on the macOS-13 render path (which all headless verification uses) and on iOS 16.
2. **Hero:** `SkyBackdrop(now: now, calendar: model.calendar)` fills the frame (**pass the model's calendar** — `GardenModel.calendar` is module-visible, `GardenModel.swift:12`; the live app's model defaults to `.current` for the correct wall-clock band, the render harness's model carries UTC `Self.cal` so the tracked windowsill PNGs render the *intended* band — this is refinement #2, threaded through the view instead of left to `SkyBackdrop`'s default); `SpeciesWatermark(species:)` behind; `PlantView(species:stage:droop:wall: false)` centered with ~50%+ negative space; idle sway (gated by `accessibilityReduceMotion`). **Tap-the-plant waters** (ripple) via `.accessibilityAction` + tap gesture calling `onWater`.
3. **Name block:** EN serif + KO secondary, `.inkText()` (reads on every band + dark mode).
4. **Status cluster:** `StatusCluster(fraction:band:)` only — streak/tick **not** repeated (the "gauge mixed with buttons" fix).
5. **Overwater nudge (conditional):** the gentle line recolored to **`#7A4E08`** (deep amber-brown, ≥4.5:1 — replaces the current failing `#D1851F` at `WindowsillView.swift:60`), 💧 as a non-color cue.
6. **Floating `WaterButton(isOverfull:action:)`** in the lower third, **clearly above and separated from the tab bar** (never flush — or the two glass surfaces re-couple). Never disabled; over-full shows the nudge.

Idle "just looking" state: Water pill + tab bar recede (fade + slight translate) so plant+sky stand alone; return on tap/scroll. `.ssakGround()` behind everything for dark mode.

- [ ] Step 1: Rebuild the view from the zones above; derive `droop` unchanged (existing `band`/`droop` computed vars stay). Wire tap-to-water + `WaterButton` both to `onWater`.
- [ ] Step 2: `Render.swift`: replace the current single `windowsill_*` set with the **matrix** — state ∈ {bloom, dry, nursing, overwater} × band ∈ {dawn, day, dusk, night} × {light, dark} (curate a representative subset to track; render the full grid to inspect). Reuse the existing `windowsill(mutate:now:)` helper, passing `day0h(H)`; wrap dark in `.environment(\.colorScheme,.dark)`. Open; iterate to calm + screenshot-ready; confirm the Water pill sits clear of the bottom edge.
- [ ] Step 3: Commit `feat(ui): windowsill redesign — sky, glass water, watermark, gauge-only cluster (Plan A Task 6)`.
- [ ] **Simulator (user):** tap-plant + pill both water and ripple; idle chrome fades then returns; real glass on iOS 26.

---

### Task 7: OnboardingView — re-space (SsakApp)

**Files:** Modify `SsakApp/Sources/SsakApp/OnboardingView.swift` (**same `init(onDone:)`**). Modify `SsakAppRender/Render.swift`.

**Spacing targets (spec §2.1 table)** — same three beats/copy, rebuilt for air:

| Element | Now (`OnboardingView.swift`) | Target |
|---|---|---|
| top inset | `Spacer(minLength: 8)` (line 13) | balanced `Spacer()` |
| title → subtitle | `spacing: 4` (line 14) | 12pt |
| title block → beats | `VStack(spacing: 22)` (line 12) | 44pt |
| between beats | `spacing: 18` (line 19) | 28pt |
| beats → CTA | `Spacer()` | `Spacer()` + generous |
| CTA bottom | `.padding(.bottom, 28)` (line 33) | safe-area + 24pt |

Use `@ScaledMetric` for spacings that must track type size; ink → `.inkText()`; one copy tweak — the "Watch the drop" sub becomes *"Watch the drop — it reads the soil."* (spec §2.1). No animated hero (R2). CTA never clipped under Dynamic Type reflow.

- [ ] Step 1: Apply the spacing table; `.inkText()`; copy tweak; `@ScaledMetric` where noted.
- [ ] Step 2: `Render.swift`: re-render `onboarding.png` (+ a dark variant). Open; confirm it breathes. **NOTE (found in execution): `ImageRenderer` ignores `\.dynamicTypeSize`**, so a headless AX render is pixel-identical to default and proves nothing — Dynamic Type scaling/clipping is **Simulator-verified**. The real headless deliverable is the *semantic fonts* themselves (grep confirms no `Font.system(size:)`).
- [ ] Step 3: Commit `feat(ui): re-spaced onboarding (Plan A Task 7)`.

---

### Task 8: ShelfView — light restyle (SsakApp)

**Files:** Modify `SsakApp/Sources/SsakApp/ShelfView.swift` (**same `init(model:onReplant:)`**). Modify `SsakAppRender/Render.swift`.

**Change (spec §2.3):** empty slots' dashed `Circle` (current `ShelfView.swift:44–46`) → a faint **`SsakMark(.mono)`** sprout glyph (generic, *not* per-species). Keep the 6-slot grid + replant + "Garden complete 🌸". Header ink → `.inkText()`; `.ssakGround()` for dark mode; match the glass tab bar (auto on 26). 8pt spacing.

- [ ] Step 1: Swap the empty-slot glyph to `SsakMark(.mono)` (faint); `.inkText()`/`.ssakGround()`.
- [ ] Step 2: `Render.swift`: `shelf_empty.png` (six mono glyphs), `shelf_partial.png`, `shelf_complete.png`, each + a dark variant. Open; confirm cozy + legible, glyphs read as sprouts.
- [ ] Step 3: Commit `feat(ui): shelf mono-glyph slots + dark mode (Plan A Task 8)`.

---

### Task 9: RootView glass tab + bloom CTA; BloomCard watermark (SsakApp)

**Files:** Modify `SsakApp/Sources/SsakApp/RootView.swift` and `SsakApp/Sources/SsakApp/BloomCard.swift`. Modify `SsakAppRender/Render.swift`.

**RootView (spec §2.2 bloom moment, §2.4):** two-tab `TabView` unchanged in structure; the glass bar is **auto-adopted on the iOS 26 SDK** (no code change needed beyond confirming the fallback bar on 16). At `model.stage == .bloom`, the Share `GlassIconButton` promotes to a labeled CTA ("Share your bloom") — thread a `prominent`/labeled flag down to `WindowsillView`'s status bar (or gate inside the view on `model.stage`). `reconcileOnOpen` + `presentShare()` logic **unchanged** (smoke only). Keep `now: Date()` injection (refinement #1 — this is what keeps the sky live).

**BloomCard (spec §2.5):** add the faint 싹 watermark (`SsakMarkPath` behind the plant, very low opacity); keep the clean cream frame — **no** real-time sky (timeless + dodges the `ImageRenderer` determinism trap). Ink stays the fixed brown (the card renders on a fixed light frame regardless of device mode). Otherwise unchanged, incl. `shareImage()`.

- [ ] Step 1: Bloom-moment CTA promotion in the status bar; confirm 16 fallback tab bar; add the watermark to `BloomCard`.
- [ ] Step 1b: **Bloom-open ceremony** (spec §1.5, §2.2) — on transition to `model.stage == .bloom`, the hero plant plays a one-shot open animation (a gentle scale/opacity/settle of the bloom), gated by `accessibilityReduceMotion` (instant when reduced). Drives off the stage change in `WindowsillView`'s hero; motion itself is Simulator-verified, its static end-state is the existing `windowsill_bloom_*` render.
- [ ] Step 2: `Render.swift`: re-render `share_card.png` (with watermark); render `root_windowsill.png` + `root_shelf.png` at a fixed `now`. Open; card still share-worthy, watermark faint.
- [ ] Step 3: Commit `feat(ui): glass tab + bloom-moment share CTA + card watermark (Plan A Task 9)`.
- [ ] **Simulator (user):** glass tab bar on 26; bloom promotes the Share CTA **and plays the bloom-open ceremony** (still under Reduce Motion); share sheet still opens; card crisp.

---

### Task 10: Accessibility pass (SsakApp — all net-new, spec §5)

**Files:** Modify `WindowsillView.swift`, `OnboardingView.swift`, `ShelfView.swift`, `DropGauge.swift`/`StatusCluster.swift`, `StreakBadge`/`WateredTodayTick`. Modify `SsakAppRender/Render.swift`.

**Add (spec §5):**
- **VoiceOver:** hero **combined** label *"Marigold, budding, soil moist"* (**omit "watered today"** — the top-bar tick carries it, no double-speak); tap-to-water as `.accessibilityAction`. `WaterButton` "Water" / hint "Waters your plant"; Share labeled. `StreakBadge` → "Streak, N days"; `WateredTodayTick` → "Watered today"; `DropGauge` → "Soil moisture, N percent". Decorative art (`SkyBackdrop`, `SpeciesWatermark`, `PlantView`) `.accessibilityHidden(true)`.
- **Dynamic Type** — the app ships **17 fixed `Font.system(size:)` sites and zero semantic styles**, so scaling is currently broken. Tasks 6–9 convert each view's sites as they rebuild (serif names/titles → `Font.system(.title2/.title3/…, design: .serif)`; UI → semantic styles; **never** `Font.system(size:relativeTo:)` — that overload doesn't exist, spec §1.3). This task **audits that every text site actually scales AX1→AX5** and converts any straggler the rebuild tasks didn't own (`DropGauge`, `StreakBadge`, `WateredTodayTick`). A fixed-size font passes an AX5 render trivially (no scale, no clip) while failing the requirement — so the audit checks the font *type*, not just the render.
- **Reduce Motion** → gate **all four** spec §1.5 motions: idle sway, gauge ripple (T5), bloom-open ceremony (T9), sky cross-fade — static/instant when reduced. **Reduce Transparency** / **Increased Contrast** already handled in `SsakGlass` — verify they reach the buttons.
- **Contrast verify:** all text ≥4.5:1 on **every** band (§1.2 ratios) and dark mode; overwater `#7A4E08` confirmed ≥4.5:1 on cream; `DropGauge` dry-fill unchanged (judged 3:1 against its own drop background, not cream — spec §5).

- [ ] Step 1: Add labels/hints/actions/hidden flags; gate motion on `accessibilityReduceMotion`; verify the hero label composes without double-speak.
- [ ] Step 2: `Render.swift`: `windowsill_reduce_transparency.png` (`.environment(\.accessibilityReduceTransparency, true)` → glass goes solid, must not blank). Open; confirm. (Dynamic Type scaling and VoiceOver speech are Simulator-only — `ImageRenderer` ignores `\.dynamicTypeSize`; the headless guarantee is that every text site uses a *semantic* font, checked by grep.)
- [ ] Step 3: Commit `feat(a11y): VoiceOver labels, reduce-motion/transparency, contrast pass (Plan A Task 10)`.
- [ ] **Simulator (user):** VoiceOver reads hero/Water/Share/streak/tick/gauge/tabs with no double-speak; Reduce Motion still; Reduce Transparency solid; AX1→AX5 no clipping on SE + Pro Max.

---

### Task 11: Reference re-approval + full green

**Files:** Finalize `SsakApp/.gitignore` (curated reference set), track the re-approved PNGs, `SsakAppRender/Render.swift` (final render list).

- [ ] Step 1: Curate and re-approve the tracked SsakApp references: replace `windowsill_bloom.png` with a representative redesigned windowsill (e.g. `windowsill_bloom_day.png` + one dark, one night), the mono-glyph `shelf_partial.png`, respaced `onboarding.png`, watermarked `share_card.png`. Update `.gitignore`'s `!rendered/...` allowlist to match; `git add` the approved PNGs.
- [ ] Step 2: **Full green gate:** `swift test` in `SsakCore`, `SsakArt`, `SsakApp` all pass (SsakCore proves no logic touched — spec §7 risk 6); `swift build` in SsakApp + SsakArt (macOS compile gate, §1.4); re-run the **same-machine before/after SsakArt render diff** from Task 3 one final time (byte-stability — never a diff against the committed refs, which are env-shifted).
- [ ] Step 3: Commit `docs(app): re-approve redesigned reference screens (Plan A Task 11)`.

---

## Self-Review (spec coverage)

- **Design language — glass, sky, type, adaptive ink, a11y flags (§1):** Tasks 1, 2, 10 (+ `.inkText()`/`SsakGround` for §3.4). ✓
- **Motion (§1.5) — all four:** idle sway (T6), gauge ripple (T5), bloom-open ceremony (T9), sky cross-fade (T2); every one Reduce-Motion-gated in T10. ✓
- **Dynamic Type (§1.3, §5):** semantic fonts adopted per view in Tasks 6–9 (converting the 17 fixed-size sites); AX1→AX5 audit in T10. ✓
- **Windowsill core redesign (§2.2):** Task 6 — sky, watermark, floating decoupled glass Water, quiet glass Share, gauge-only cluster, recolored nudge, idle chrome-fade, tap-to-water. ✓
- **Onboarding re-space (§2.1):** Task 7 (spacing table, copy tweak, no animated hero). ✓
- **Shelf light restyle (§2.3):** Task 8 (`SsakMark(.mono)` slots, glass tab, garden-complete kept). ✓
- **Navigation glass + bloom CTA (§2.2, §2.4):** Task 9 (auto glass bar, bloom-moment Share promotion, reconcile/share unchanged). ✓
- **Share card watermark, no sky (§2.5):** Task 9. ✓
- **New components (§3.2):** `SkyBackdrop` (T2), `SsakMark` (T4), `SpeciesWatermark`+`StatusCluster` (T5), `SsakGlass`+`WaterButton`+`GlassIconButton` (T1). ✓
- **`PlantView`/`Sill` split, byte-identical default (§3.3, §6, §7 risk 1):** Task 3 (git-diff guard) + Task 11 (final re-check). ✓
- **Accessibility to production bar (§5):** Task 10. ✓
- **Guardrails (§0):** SsakCore/species-art/gameplay untouched (SsakCore tests are the tripwire, T11); iOS 16 retained + macOS compiles (T1/T11 build gate); no sound/haptics; portrait iPhone only. ✓

**Deliberate simplifications (flagged above):** no `TimelineView` for in-session live sky (foreground-refresh covers it); `SkyBackdrop(now:calendar:)` gains a defaulted calendar for TZ-reproducible renders. **Simulator-only handoffs:** real Liquid Glass (iOS 26 device), VoiceOver speech, tap/drag ripple, idle-chrome fade, on-device Dynamic Type/SE/Pro Max — the flows headless rendering can't verify.

**Cross-plan:** `SsakMark` (Task 4) is also the reuse source the app icon ports from — see **Plan B** ([`2026-07-20-ssak-appicon.md`](./2026-07-20-ssak-appicon.md)), which is otherwise independent (its icon source is the committed SVG, not `SsakMark`).
