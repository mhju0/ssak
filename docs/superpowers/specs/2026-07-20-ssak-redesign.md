# Ssak (싹) — UI Redesign & App Icon Spec

**Date:** 2026-07-20
**Status:** Drafted in brainstorming session with Michael Ju. Pending user review before writing-plans.
**Extends:** `2026-07-19-ssak-design.md` (concept, growth model, six species — all unchanged). This spec covers **only the visual/UI layer**: onboarding, windowsill, navigation, share card, the app icon, and a real-time sky. No gameplay, logic, persistence, or species-art changes.

---

## 0. Goal & guardrails

Elevate Ssak's UI to "clean, calm, Apple-Design-Award" quality while staying inside the project's soul and scope.

**In scope**
- Re-spaced onboarding (fix the cramping).
- Windowsill: lift **Water** into a floating **Liquid Glass** control detached from the nav; move **Share** to a quiet top-right glass icon; a **real-time warm sky**; a **faint 싹 watermark** behind the plant; a quiet status cluster.
- A new **app icon** — the *Bloom-Point* sprout mark — with the full iOS 26 variant set.
- **Liquid Glass** on the tab bar, the floating Water pill, top-corner icons, and sheets.
- **Accessibility** brought up to production bar (Dynamic Type, VoiceOver, Reduce Transparency/Motion, contrast, tap targets).

**Guardrails (hard lines)**
- `SsakCore` (all gameplay/logic/persistence) is **untouched**. Its tests must still pass unchanged.
- `SsakArt` per-species drawings are **untouched** (only `Sill`/backdrop is refactored, and one new `SsakMark`).
- **iOS 16 minimum deployment is retained.** Liquid Glass is *progressive enhancement* on iOS 26+ with a graceful `.ultraThinMaterial`/bordered fallback below — never a hard gate.
- **No sound, no haptics** — dropped by [ADR-0002](../../adr/0002-drop-haptics.md) and out of scope in the base spec §10. Levers are layout, color, type, motion, and glass only.
- Portrait-only, iPhone-only (`TARGETED_DEVICE_FAMILY=1`), offline, no dependencies. "Finishable first" — we polish the existing two screens, we do not add features.

---

## 1. Design language

### 1.1 Palette (existing, reused)
| Token | Hex | Use |
|---|---|---|
| cream | `#FCF7EB` / grad `#FCF8EE→#E7F0DA` | app ground |
| ink | `#473828` | primary text, mono mark |
| sage / sprout | `#5B9A4F`, `#6EAE59`, `#80BF69`, deep `#4E8A44` | leaves, accents |
| terracotta | `#CF7A54`→`#9E523B` | pot, warm accent |
| marigold gold | `#E8A23A` / bud `#F7CE78→#E1962C` | single warm accent, bud |
| water blue | `#5C9EDB` | water action, gauge |
| warn amber | `#D1850F` (darkened from current `#EB9E38` for contrast — see §5) | overwater nudge |

### 1.2 Real-time sky (new)
A `TimeBand` derived from the injected `now` (never stored, never a new clock read — `WindowsillView` already gets `now`):
| Band | Hours (local) | Wall gradient (top→bottom) |
|---|---|---|
| dawn | 05–08 | `#FBE6C4 → #F3D9C0` warm gold |
| day | 08–17 | `#FCF8EE → #E7F0DA` (current cream) |
| dusk | 17–20 | `#F6D9BE → #E8C4A8` amber |
| night | 20–05 | `#2E3550 → #232A42` dim indigo (plant + pot stay lit; text flips to light) |
Bands **cross-fade** (interpolate over the ~1h boundary) so there is no hard snap. A `TimelineView(.periodic(from:by:))` at ~5-min cadence keeps it live while the app is open; otherwise it settles from `now` on appear.

### 1.3 Typography
- **Serif (New York, `.serif`)** for the wordmark, species names, and screen titles (kept upright per user — no italic).
- **SF / SF Rounded** for all UI labels and controls.
- **Dynamic Type**: replace fixed `.font(.system(size:))` with semantic styles (`.title`, `.headline`, `.subheadline`, `.body`, `.caption`) or `.system(size:relativeTo:)` so everything scales. Target legible layout to AX3, no clipping to AX5.

### 1.4 Liquid Glass (iOS 26+, with fallback)
One shared modifier hides the availability check:
```swift
// GlassBackground.swift
extension View {
    /// Liquid Glass on iOS 26+, ultraThinMaterial fallback below. Honors Reduce Transparency.
    @ViewBuilder func ssakGlass(_ shape: some Shape, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *), !reduceTransparency {
            self.glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
        } else if !reduceTransparency {
            self.background(.ultraThinMaterial, in: shape).overlay(shape.strokeBorder(.white.opacity(0.25)))
        } else {
            self.background(tint?.opacity(0.16) ?? Color(white: 0.96), in: shape) // opaque
        }
    }
}
```
- **Floating Water pill** → `.buttonStyle(.glassProminent)` (26+) / `.borderedProminent` capsule (fallback), water-blue tint, `.interactive()`.
- **Top-corner icons (share, and shelf if full-screen later)** → `.buttonStyle(.glass)` grouped in a `GlassEffectContainer` so they share one glass surface.
- **Tab bar** auto-adopts Liquid Glass when built against the iOS 26 SDK; no code needed, fallback is the standard bar.
- **Sheets** (seed-chooser, share) → glass backgrounds where 26+.

### 1.5 Motion (existing scope only)
Idle plant sway, water ripple on the gauge, the bloom-open ceremony, sky cross-fade. All gated by `@Environment(\.accessibilityReduceMotion)` → static when reduced. No new heavy animation.

### 1.6 Spacing
8pt grid throughout; screen side margins 20pt; group spacing 24–32pt; tap targets ≥44pt, the primary Water control ≥64pt tall.

---

## 2. Screen-by-screen

### 2.1 Onboarding — re-space (the cramping fix)
Same three beats and copy, rebuilt for air. Current → target spacing:
| Element | Now | Target |
|---|---|---|
| top inset | `Spacer(minLength: 8)` | `Spacer()` (balanced) + 8pt-grid top pad |
| title → subtitle | 4pt | 12pt |
| title block → beats | 22pt | 44pt |
| between beats | 18pt | 28pt |
| beat icon → text | 16pt | 16pt (keep) |
| beats → CTA | flexible | `Spacer()` + generous |
| CTA bottom | 28pt | safe-area + 24pt |
- Beats become an 8pt-grid list; icons 44pt; title `.largeTitle`-ish serif, subtitle `.subheadline` secondary.
- Microcopy: keep all; single tweak — *"Watch the drop — it reads the soil."*
- Dark mode: warm-dark ground; text flips light. Dynamic Type: list reflows, CTA never clipped.
- **No** animated/floating hero (user chose the static re-space).

### 2.2 Windowsill — the core redesign
Vertical zones, top to bottom:
1. **Status bar (top).** Left: `StreakBadge`. Right: a `GlassEffectContainer` with the `WateredTodayTick` and a **quiet glass Share icon**. 20pt margins, ≥44pt targets.
2. **Hero.** `SkyBackdrop(now:)` fills the frame (real-time band); a **`SpeciesWatermark`** (faint oversized 싹, tinted to species, ~6% opacity) sits behind; `PlantView` centered with large negative space (~50%+). Idle sway. **Tap-the-plant waters** (with the ripple), in addition to the button.
3. **Name block.** EN serif + KO secondary.
4. **Status cluster (quiet).** `DropGauge` + a small "watered today"/streak read-out, grouped and *visually separate from the action* — this is the fix for "the gauge is mixed in with the buttons." Small, low-emphasis.
5. **Overwater nudge (conditional).** The existing gentle amber line when `wouldOverwater`.
6. **Floating Water control.** A large Liquid Glass **capsule**, water-blue, centered low, clearly **detached** from the tab bar (padding + shadow + glass separates it). This is the one primary verb. Disabled state: never — watering stays allowed (freedom); over-full shows the nudge, not a disable.

Bloom moment: when `stage == .bloom`, the Share icon promotes to a prominent labeled CTA ("Share your bloom"); the plant plays the bloom-open ceremony; the "press to shelf" affordance remains on the Shelf (unchanged flow).

### 2.3 Shelf — light restyle only
Keep the 6-slot grid and replant behavior. Changes: match the glass tab bar; empty slots become **soft species silhouettes** (a faint mono `PlantView` shape) instead of dashed circles (per cozy-games research); 8pt spacing; "Garden complete 🌸" state kept. No structural change.

### 2.4 Navigation (`RootView`)
Two-tab `TabView` (Windowsill · Shelf) — restyled Liquid Glass tab bar on 26+, standard below. `reconcileOnOpen` on `scenePhase == .active` is unchanged. Share presentation (`UIActivityViewController`) unchanged.

### 2.5 Share card (`BloomCard`)
Add the faint 싹 watermark; keep the clean cream frame (timeless — **no** real-time sky here). Otherwise unchanged; still rendered via `ImageRenderer`.

### 2.6 App icon — Bloom-Point
The chosen mark: two green cotyledons framing a **furled gold bud** rising from them (bloom implied, never opened). Verified to read at 40px and as a flat mono silhouette.
- Authored as vector (source SVG locked; ported to a SwiftUI `SsakMark` Shape in `SsakArt` for reuse as icon + watermark).
- **iOS 26 layered icon** (Icon Composer): background layer (cream→sage gradient) + foreground (sprout), yielding **Light / Dark / Tinted / Clear** automatically. Variant recipes in Appendix A.
- Delivery: an `AppIcon` asset set with PNGs exported at required sizes from the render harness (`SsakMark` → `ImageRenderer`), plus the `.icon` layered source. All app-icon sizes (1024 marketing + home/spotlight/settings).

---

## 3. Component architecture

### 3.1 Page-level (modified)
`OnboardingView`, `WindowsillView`, `ShelfView`, `RootView`, `BloomCard` — same public entry points; internals reworked.

### 3.2 Reusable components (new)
| Component | Package | Props / API | Purpose |
|---|---|---|---|
| `SkyBackdrop` | SsakArt | `init(now: Date)` → derives `TimeBand` | real-time wall gradient behind the plant |
| `SsakMark` | SsakArt | `init(variant: Variant = .light)` where `Variant ∈ {light,dark,tinted,mono,glass}` | the sprout icon as a `View`; app icon + watermark + onboarding accent |
| `SpeciesWatermark` | SsakApp/Art | `init(species:opacity:)` | faint ghosted mark behind hero |
| `WaterButton` | SsakApp | `init(isOverfull:Bool, action:@escaping ()->Void)` | floating Liquid Glass primary pill (+ fallback) |
| `GlassIconButton` | SsakApp | `init(systemImage:label:prominent:action:)` | top-corner glass icon (share) |
| `StatusCluster` | SsakApp | `init(fraction:band:streak:alive:wateredToday:)` | quiet grouped read-out (wraps `DropGauge`, streak, tick) |
| `View.ssakGlass(_:tint:interactive:)` | SsakApp | modifier | glass-or-fallback, honors Reduce Transparency |

### 3.3 Modified components
`Sill` (SsakArt): split so the **wall gradient** moves to `SkyBackdrop`; `Sill` keeps only the board/ledge. `PlantView` gains an optional `wall: Bool = true` param (default keeps current behavior so **existing call sites and `RenderInvariantsTests` don't break**); `WindowsillView` passes `wall: false` and layers `SkyBackdrop` itself. `DropGauge`, `StreakBadge`, `WateredTodayTick` visuals unchanged (regrouped into `StatusCluster`).

### 3.4 State ownership
- `GardenModel` (`@MainActor ObservableObject`) stays the single source of truth. **No new persistent fields.**
- `TimeBand` is **derived** from `now` in the view — not stored, not a new clock read (`now` already flows in; `RootView` reads `Date()` at the boundary; a `TimelineView` refreshes the derivation).
- Accessibility flags via `@Environment(\.accessibilityReduceTransparency / .accessibilityReduceMotion / .legibilityWeight)`.

---

## 4. States & edge cases

| Screen | Loading | Empty | Error | Disabled | Notable edge cases |
|---|---|---|---|---|---|
| Onboarding | none (static) | — | — | CTA always enabled | Dynamic Type AX5 (reflow), dark mode, small device (SE) |
| Windowsill | none — local state is instant; render plant on first frame, reconcile already ran | never empty (always a plant) | persistence save is `try?` (local, non-fatal) — keep silent, document | Water **never disabled** (freedom); over-full → nudge | fresh plant (no `lastWateredAt`) → gauge/streak read "—"; midnight/DST rollover for streak+sky; band boundary cross-fade while open; very long KO names; Reduce Transparency → solid; Reduce Motion → no sway/ripple |
| Shelf | none | 0 collected → six silhouettes (the "empty" state) | — | replant tap only on collected | all six → "Garden complete"; partial fills |
| Share | `ImageRenderer` may return nil → guard already returns (no crash) | — | render nil → no-op (log) | — | huge Dynamic Type doesn't affect the fixed-size card |
| Icon | — | — | Clear/Glass is OS-composited (can't fully preview statically) | — | tinted legibility at 40px (verified), dark-mode home screen |

---

## 5. Accessibility

- **Dynamic Type** everywhere (semantic fonts); verify no clipping to AX3, graceful to AX5.
- **VoiceOver**: a combined plant-status label on the hero (e.g. *"Marigold, budding, soil moist, watered today"*); `WaterButton` label "Water" + hint "Waters your plant"; Share labeled; decorative art `.accessibilityHidden(true)`. Tap-to-water plant is an `.accessibilityAction`.
- **Reduce Transparency** → glass becomes opaque material/solid (handled in `ssakGlass`).
- **Reduce Motion** → no sway, no ripple, instant sky.
- **Contrast**: the current overwater amber `#EB9E38` on cream is ~2.1:1 — **fails**. Darken to `#D1850F` (~3.3:1, and it's ≥18pt semibold so AA-large passes). Verify all text ≥ AA.
- **Tap targets** ≥44pt; Water ≥64pt.
- **Increased Contrast** → add a hairline border to glass surfaces.

---

## 6. Files to create / update

**Create**
- `SsakArt/Sources/SsakArt/SkyBackdrop.swift` — real-time wall.
- `SsakArt/Sources/SsakArt/SsakMark.swift` — sprout mark (icon/watermark).
- `SsakApp/Sources/SsakApp/GlassBackground.swift` — `ssakGlass` modifier + `WaterButton` + `GlassIconButton`.
- `SsakApp/Sources/SsakApp/SpeciesWatermark.swift`.
- `SsakApp/Sources/SsakApp/StatusCluster.swift`.
- App icon asset set (`Assets.xcassets/AppIcon`) + layered `.icon` source; `project.yml` `INFOPLIST`/asset wiring.

**Update**
- `OnboardingView.swift` (re-space, Dynamic Type).
- `WindowsillView.swift` (zones, floating Water, top-right share, sky, watermark, cluster, tap-to-water, a11y).
- `ShelfView.swift` (silhouette empty slots, spacing).
- `RootView.swift` (glass tab bar wiring; bloom-share promotion).
- `BloomCard.swift` (watermark).
- `SsakArt/Backdrop.swift` (`Sill` split; `PlantView` `wall` param).
- `SsakApp/Sources/SsakAppRender/Render.swift` (new/updated renders: respaced onboarding, windowsill at each `TimeBand`, silhouette shelf, icon variants).
- `project.yml` (AppIcon asset; retain iOS 16 target).

**Unchanged (must not regress)**
- All of `SsakCore` + its tests; all `SsakArt` species drawings; `SsakArtRender`; `RenderInvariantsTests` (guarded by the `wall` default); `GardenModelTests`.

---

## 7. Verification

**Automated / headless**
- `cd SsakApp && swift run SsakAppRender` → regenerate PNGs; visually diff onboarding, windowsill (bloom/dry/nursing/overwater × dawn/day/dusk/night), shelf (empty/partial/complete), share card, icon variants against committed references.
- Icon SVG variants already rendered + verified via headless Chrome.
- `swift test` in all three packages → **all existing tests green** (proves no logic regression).

**Manual (Simulator + device)** checklist
- [ ] Tap **Water** pill and **tap the plant** both water; gauge/ripple respond.
- [ ] Share icon (top-right) opens the sheet; card image is crisp.
- [ ] Background → wait → foreground: `reconcileOnOpen` grows the plant.
- [ ] Sky matches time of day; cross-fades near a boundary.
- [ ] Dynamic Type slider AX1→AX5: no clipping, CTA visible.
- [ ] VoiceOver sweep: hero status, Water, Share, tabs all labeled.
- [ ] Dark mode; Reduce Transparency (glass→solid); Reduce Motion (still).
- [ ] iOS 26 device (real glass) **and** iOS 16 device (fallback) both correct.
- [ ] iPhone SE (smallest) and Pro Max (largest): layout holds.
- [ ] App icon on home screen in light/dark/tinted.

**Edge cases to test**: fresh plant (no water yet), midnight & DST streak rollover, band boundary while open, longest KO name, over-full watering nudge, garden-complete shelf.

**Regression risks**
1. `PlantView`/`Sill` refactor → guarded by `wall` default; re-run `RenderInvariantsTests` + `SsakArtRender`.
2. Glass availability branch → test both iOS 16 and 26 paths (fallback must never crash/blank).
3. Tab selection & share presentation unchanged — smoke test.
4. Time-of-day derivation must not read a second clock or mutate state (keep `now`-injected).
5. Contrast change on the amber warning — confirm the new value still reads "gentle."
6. No `SsakCore` edits — logic tests are the tripwire.

---

## 8. Out of scope (someday)
Full-screen "place" navigation (chose the glass dock), diegetic-only watering, tap-to-water haptics, sound, notifications, animated onboarding hero, italic species names, iPad/landscape, sharing the shelf, any AI/raster art.

---

## Appendix A — Bloom-Point icon (reproducible)

Canvas 220×220, squircle `rx≈49` (22.3%), mark centered on `x=110`, filling ~53% frame height, calm corners.

- **Stem**: `M110 146 C110 154 110 160 110 166`, 8pt round, `#4C8642`.
- **Left leaf**: `M108 147 C88 151 64 145 54 122 C66 112 90 128 108 147 Z`, grad `#7EBA61→#4C8642`.
- **Right leaf**: `M112 147 C132 151 156 145 166 124 C154 114 130 130 112 147 Z`, grad `#6BA956→#47823E` (one value darker → recedes).
- **Bud (rounded furl)**: `M110 146 C94 120 96 88 106 60 C107 55 113 55 114 60 C124 88 126 120 110 146 Z`, grad `#F7CE78→#E1962C`; furl seam `#C9812A@0.5`; left-lobe highlight `#FADFA0@0.55`.
- **Contact shadow**: radial ellipse `cx110 cy170 rx44 ry9`, `#473828@0.18→0`.

**Variant recipes**
- **Light**: cream→sage bg `#FCF8EE→#E7F0DA`, mark as above.
- **Dark**: bg `#2A241C→#17130F` + warm radial glow behind bud; leaves brighten `#8AC86C→#4F9145`; bud `#FAD583→#E89B32`.
- **Tinted**: dark bg, mark in a single light tint (grayscale source: bud lightest `#DCE7C8`, leaves mid, stem darkest) — system applies user tint.
- **Clear/Glass**: OS-composited frosted; source = translucent white relief + specular top edges over the layered art.

---

## Decision ledger (this session)
| # | Decision | Choice |
|---|---|---|
| R1 | Home layout | Liquid Glass dock + 2 tabs; Water lifted to a floating detached glass pill |
| R2 | Onboarding | Re-space the existing 3-beat screen on an 8pt grid (no animated hero) |
| R3 | Share | Quiet top-right glass icon always; promotes to CTA at bloom |
| R4 | Sky | Real-time warm gradient (dawn/day/dusk/night), derived from `now` |
| R5 | Watermark | Faint oversized 싹/species mark behind the hero + share card |
| R6 | Typography | Upright serif names (no italic); SF for UI; Dynamic Type |
| R7 | App icon | *Bloom-Point* sprout — two cotyledons + furled gold bud; full iOS 26 variant set |
| R8 | Liquid Glass | iOS 26+ with iOS 16 `ultraThinMaterial`/bordered fallback; Reduce-Transparency aware |
| R9 | Guardrails | No `SsakCore`/species-art/gameplay changes; no sound/haptics; portrait iPhone only |
