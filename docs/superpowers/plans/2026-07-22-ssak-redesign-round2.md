# Ssak UI Redesign Round 2 — "The plant gets the whole window"

> **Visual source of truth:** [`docs/design/ssak-redesign-round2-mockup.html`](../../design/ssak-redesign-round2-mockup.html)
> (interactive; open in a browser — sky segments, tab switch, and the start-guide tour all work).
> This plan translates that approved mockup into SwiftUI. Where the mockup and this plan
> disagree, the mockup wins on *look*, this plan wins on *engineering constraints*.

**Goal:** land the round-2 direction on top of the round-1 Liquid-Glass redesign: the plant
full-screen in a **living room scene** (window with real-time sky, sunbeam, blurred plant
friends, dust motes, sill fade), **nav moved to the top** as a glass pill (bottom `TabView`
removed), Water as a **small floating circular glass drop**, and the 3-screen onboarding
replaced by a **coach-mark start guide** (welcome sheet → 3 spotlight steps). The whole pass
carries the approved Toss/TDS tokens: type 28/20/17/15/13 via *semantic* styles, radii
12/16/24/pill, 8pt spacing, ≥44pt targets, 52pt bottom-CTA.

## Global constraints (unchanged from round 1)

- **`SsakCore` untouched**, tests pass unchanged. No new persisted state (`hasOnboarded`
  stays the only gate, in `@AppStorage`).
- **Species drawings untouched.** SsakArt gains new files only (`RoomScene`), plus an
  internal band-helper extraction from `SkyBackdrop` (public API of `SkyBackdrop` unchanged).
- **iOS 16 floor; both packages still build & test on macOS 13** — all iOS-26 glass stays
  behind `#if os(iOS)` + `#available`; ambient motion (motes, sway) is `reduceMotion`-gated
  and renders its resting frame headlessly (deterministic PNGs).
- **Semantic Dynamic Type only.** The Toss scale maps exactly:
  28→`.title`, 20→`.title3`, 17/600→`.headline`, 15→`.subheadline`, 13→`.footnote`.
- **No sound, no haptics** (ADR-0001).
- Verification per slice: `swift build` + `swift test` (all 3 packages) + `SsakAppRender`
  → PNG → inspect. Gradient renders drift across relinks — never a behavior signal; the
  deterministic renders + test suites are the guard. Real glass/VoiceOver/gestures →
  Simulator at the end.

## Toss token mapping (approved "all of A–G")

| Mockup token | SwiftUI |
|---|---|
| `--fs-display` 28 serif | `.font(.system(.title, design: .serif).weight(.semibold))` |
| `--fs-title` 20 serif | `.title3` serif semibold |
| `--fs-cta` 17/600 | `.headline` |
| `--fs-body` 15 | `.subheadline` |
| `--fs-label` 13 (floor) | `.footnote` — **nothing below** (`.caption*` banned) |
| `--r-sm/md/lg` 12/16/24, pill | `Design.rSM/rMD/rLG` + `Capsule` (tokens in `InkColors.swift`) |
| `--pad` 20, 8pt grid | `Design.pad` + 8-multiples only |
| ≥44pt hit areas | `.frame(minWidth/minHeight: 44)` / `.contentShape` beyond visual bounds |
| BottomCTA 52pt r16 | guide sheet "Plant a seed" button |

## Tasks

- [x] **T1 — docs**: commit the mockup (`docs/design/`) + this plan.
- [x] **T2 — `RoomScene` (SsakArt)**: extract `SkyBackdrop`'s hour→band machinery into an
  internal `Daylight` helper (SkyBackdrop's public API + output unchanged); new
  `RoomScene(now:calendar:)` composing: band-tinted room gradient → window (SkyBackdrop
  sky + muntins + bokeh) → sunbeam (`.screen` blend) → glow → two blurred plant friends →
  sill fade (no hard edge). Dark mode = warm-dark room, band nudges hue. Dust motes:
  `TimelineView` canvas, fixed seed table (deterministic), iOS-only + `reduceMotion`-gated —
  macOS render path draws none (resting frame).
- [x] **T3 — top nav + windowsill rework (SsakApp)**: `Design` tokens; `TopNavPill`
  (glass capsule, 2 segments, ≥44pt hits) overlaid top-center in `RootView` — `TabView`
  deleted; `WindowsillView` adopts `RoomScene`, plant hero anchored to the sill (bottom
  ~20%), gentle sway + water-pour dip (`reduceMotion`-gated), name block →
  `.title` serif + `.footnote` KR, `StatusCluster` **deleted** in favor of a `MoistChip`
  glass pill (mini `DropGauge` + word — keeps the fill-level signal); `WaterButton` →
  62pt floating circular glass drop, bottom-right, bob animation (dead `isOverfull` param
  dropped); `StreakBadge` restyled to a 40pt glass chip. Idle chrome-fade kept.
- [x] **T4 — start guide (SsakApp)**: `StartGuide` overlay replaces `OnboardingView`
  (file deleted; smoke test repointed): welcome sheet (SsakMark, `.title` serif, 3 rows,
  52pt "Plant a seed" CTA) → 3 spotlight steps (plant → water drop → Shelf tab) via
  anchor preferences + even-odd dim cutout, speech bubble with dots + Next, Skip top-right
  (decision: stays top-right). Modal a11y; Reduce Motion = no animated transitions.
  Gate unchanged: `!hasOnboarded` shows the guide over the live windowsill.
- [x] **T5 — shelf rework (SsakApp)**: 2-column grid of 3:4 cards (`rMD`), left-aligned
  `.title3` serif header + `.footnote` progress sub, in a `ScrollView` with zero bottom
  padding so the third row bleeds past the fold (scroll affordance). Replant flow + a11y
  unchanged.
- [x] **T6 — render matrix + full gate**: harness renders RoomScene bands, MoistChip
  states, guide sheet + step, nav pill, windowsill/shelf matrix; re-approve the tracked
  reference set (`onboarding.png` → `guide_welcome.png`); all packages build + test green
  on macOS.
- [x] **T7 — Simulator + hero**: `xcodegen` → build → run on iOS sim, screenshot the real
  redesigned windowsill → new `art/hero.png` → README unchanged (same path). Manual-only
  checks (VoiceOver, gestures, real glass) flagged to Michael.

## Deliberate skips (ponytail)

- No per-band chip tinting (mockup's `--chip` ramp): system materials already adapt to
  what's behind them — revisit only if a Simulator pass shows a band where chips fail contrast.
- No `TimelineView` for the sky itself (round-1 decision stands); motes animate, sky updates
  on foreground/interaction.
- BloomCard untouched — round-2 scope is windowsill/nav/guide/shelf.
