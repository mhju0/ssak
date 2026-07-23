# Round-3 implementation plan — 압화집 (hanji album)

Spec: `docs/superpowers/specs/2026-07-23-ssak-round3-hanji.md`. One commit per task,
tests + renders verified at each checkpoint.

## Affected files (full inventory, up front)

- **SsakArt** — new `HanjiBackdrop.swift` (band-driven paper + public `HanjiPalette`);
  `SsakArtRender/Render.swift` (+hanji band renders).
- **SsakApp** — new `InkKit.swift` (SealBadge · InkGauge · InkNavTabs · InkWaterButton ·
  InkShareButton · BandClock) + `SsakFonts.swift` (CoreText registration) +
  `Resources/Fonts/` (NanumMyeongjo Regular/ExtraBold + OFL.txt); `Package.swift`
  (resources); reworked `WindowsillView.swift`, `RootView.swift`, `ShelfView.swift`,
  `BloomCard.swift`; deletions in `GlassBackground.swift` + `DropGauge.swift` (D12);
  `SsakAppRender/Render.swift` (harness swap); `SsakApp/.gitignore` (tracked-ref
  whitelist: `windowsill_bloom_dark` → `windowsill_bloom_dusk` + `windowsill_bloom_night`).
- **Untouched**: SsakCore, all species art, StartGuide content, `App/SsakApp.swift`
  (font registration lives in the package, called from RootView.init).

## Tasks

- **T1 — Paper.** `HanjiBackdrop(now:calendar:)` in SsakArt: 4-band paper gradients,
  fiber flecks, dusk lamp radial + vignette, night dark paper. Public
  `HanjiPalette(band:)` exposing paper/ink/seal tones. Harness: `hanji_<band>.png`.
  Verify: SsakArt tests + renders inspected.
- **T2 — Fonts + ink kit + windowsill + root.** Bundle/register Nanum Myeongjo;
  `Font.ssakDisplayKO(_:)` helpers with graceful fallback. Build InkKit components.
  Rework WindowsillView to the B4 layout (band clock · specimen label · seal · name
  block KO-first · ink gauge · centered water · corner share) over HanjiBackdrop;
  RootView swaps TopNavPill → InkNavTabs. Guide anchors (`plant`/`water`/`shelf`) kept.
  Verify: SsakApp tests, windowsill day/dusk/night + guide renders inspected.
- **T3 — Shelf on paper.** Paper ground + hairline paper cards + KO copy + seal-red
  press-here state. Verify: shelf empty/press-here/partial/complete renders.
- **T4 — BloomCard hanji.** KO-first specimen card + small seal. Verify: share_card
  renders (bloom + day-1 seed).
- **T5 — Retire glass + re-approve references.** Delete D12 components and their
  harness writes; update tracked-ref whitelist; full render pass; all tests; iOS
  Simulator build; push.

## Simulator-manual afterward (flagged, not in-plan)

Live look on device (real fonts at device scale), StartGuide tap-through over paper,
VoiceOver spot-check, then the README hero re-shoot once Michael approves the look.
