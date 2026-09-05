# Ssak (싹) — Decision Ledger

**Compiled 2026-09-04** from the git history, the spec/plan documents, the ADRs, the
retrospective, and Claude Code session transcripts. Chronological.

This is the "why" record. Git shows *what* changed; this shows what was decided, what it
replaced, why it moved, and whether it still stands. **Pay particular attention to the
`REVERSED` and `ABANDONED` entries** — those are the ones the code alone cannot explain.

**Status vocabulary** — `ACTIVE` (in force today) · `REVERSED` (done, then explicitly undone)
· `SUPERSEDED` (replaced by a later decision) · `DEFERRED` (agreed, not done) ·
`EXPERIMENTAL` (shipped but unvalidated) · `ABANDONED` (dropped without replacement) ·
`UNKNOWN` (rationale not recoverable).

Evidence tags: **[Verified]** read/executed this session · **[Inferred]** ·
**[Conversation]** only source is Claude session history.

---

## Era 0 — Meok (먹), 2026-07-15 → 07-19

### M-1 · Build an ink-wash skilling RPG with six progression systems — `ABANDONED`

- **Decided**: fishing, foraging, cooking, crafting, gardening, artistry; XP curves, unlock
  tables, a procedural ink world reacting to the player's real weather and solar position;
  SwiftData persistence. Milestones M0–M6.
- **Why**: first-game ambition; the author explicitly notes he "had confused *ambitious* with *good*".
- **What changed**: M0–M3 shipped and worked — parallax ink scroll world, solar day/night
  curve, rain bleeding into paper, a walking keeper figure, an end-to-end fishing loop with
  11 species. Then the remaining scope (three more skills, six unlock tables, visitors, a
  gallery) was measured as **larger than everything already built**, at day five.
- **Why it changed**: a first game should not have six interlocking progression systems.
  The author calls this "the decision in this repo I'm most confident was right," and notes
  scrapping *working* code was harder than scrapping broken code would have been.
- **Current state**: fully preserved, nothing deleted, at tag `meok-archive` → `8c88a63`.
  67 commits reachable from the tag [Verified 2026-09-05: `git rev-list --count meok-archive`];
  the retrospective’s 66 was a contemporary estimate.
  Ten unfinished features closed as `wontfix` (issues #9, #10, #11, #19, #20, #28, #29, #30, #31, #32).
- **Evidence**: `RETROSPECTIVE.md` §2 · design spec §12 · `gh issue list --state all` [Verified]

### M-2 · The procedural runtime art engine — `ABANDONED` (and named as a trap)

- **Decided (Meok)**: draw the world procedurally at runtime — ink layers, weather, solar
  position, all generated.
- **Why it changed**: it was the single largest sink in Meok. The Ssak spec calls it out by
  name: static hand-authored art is chosen because a runtime art engine is *"the specific
  trap that sank Meok."*
- **Current state**: no procedural art anywhere in Ssak. Every flower is authored SwiftUI
  `Path` code. See D5.
- **Evidence**: design spec §5.1 [Verified]

### M-3 · Two Meok ADRs — `SUPERSEDED`

- ADR-0001 (weather/solar sourcing) and ADR-0002 (SwiftData) were replaced wholesale at the
  restart. The current `docs/adr/0001-no-sound-no-haptics.md` and `0002-species-art-dispatch.md`
  reuse the numbers for entirely different subjects.
- **Side effect**: `docs/adr/0002-species-art-dispatch.md` carried the internal title
  "ADR 0003" from drafting. Corrected to ADR 0002 during the final archive on 2026-09-05.

---

## Era 1 — Ssak design ledger (spec Appendix A, D1–D14), 2026-07-19

All fourteen were settled **before any Ssak code was written**, in a brainstorming session.
Statuses below are as of today, not as of the spec.

| # | Decision | Status today |
|---|---|---|
| **D1** | **One plant at a time, not a garden grid.** Attention over management; a grid re-creates Meok's breadth problem. | `ACTIVE` |
| **D2** | **Real-clock growth, compressed** (~1 real day ≈ 1 plant-week). Patience *is* the mechanic. | `ACTIVE` |
| **D3** | **Growth accrues only while healthy.** Too dry or over-full pauses progress rather than damaging. | `ACTIVE` — implemented as the two-window integration in `GrowthEngine.reconcile` [Verified] |
| **D4** | **Six species, fixed catalog**, one starter (marigold), `bloomDays` 7→13 so later species feel slower. | `ACTIVE` — `SpeciesCatalog` [Verified] |
| **D5** | **Hand-authored static vector art, no runtime art engine.** | `ACTIVE` — the single most load-bearing decision in the project. |
| **D6** | **No backend, no accounts, no network.** Local JSON only. | `ACTIVE` |
| **D7** | **Five growth stages**, visibly distinct: seed → sprout → leaves → bud → bloom. | `ACTIVE` |
| **D8** | **Press-and-shelf as the collection loop**; the shelf is never lost. | `ACTIVE` |
| **D9** | **Time is injected, never read inside the engine.** Enables deterministic tests + the render harness. | `ACTIVE` — every `SsakCore` function takes `now:` [Verified] |
| **D10** | **Moisture as a single scalar** with dry/healthy/over-full bands, no separate nutrient/light systems. | `ACTIVE` |
| **D11** | **Wilt is a one-stage setback, never death.** Floors at seed. | `ACTIVE` — `GrowthEngine.swift:69-78` [Verified] |
| **D12** | **Streaks are penalty-free.** A missed day ends the streak's *effect*; it never subtracts progress. | `ACTIVE` — and it is *why* `reconcile` deliberately doesn't reset the counter (see A-3). |
| **D13** | **Tuning lives in one struct** (`GrowthTuning`) so feel can be changed in one place. | `ACTIVE` |
| **D14** | **Archive Meok under a tag and rename the repo/folder** rather than starting a new repo. | `ACTIVE` — done in the first Ssak commit. |

**Evidence**: `docs/superpowers/specs/2026-07-19-ssak-design.md` Appendix A [Verified]

### D-scope · Out of scope, decided up front (spec §10) — `ACTIVE`

Notifications · weather/season reactivity · sound · iCloud sync · more than six species ·
a share studio · sharing the shelf · **any AI-generated raster art**. These are *decisions*,
not gaps. Restated in `RETROSPECTIVE.md` §5. See `ROADMAP.md` → EXPLICITLY REJECTED.

---

## Era 2 — Foundation build, 2026-07-19

### A-1 · Three SwiftPM packages + a thin app shell, generated by XcodeGen — `ACTIVE`

- **Decided**: `SsakCore` / `SsakArt` / `SsakApp` as local packages; `App/` holds only
  `@main` (14 lines) and the icon catalog; `Ssak.xcodeproj` is **generated from `project.yml`
  and gitignored**.
- **Why**: keeps the entire test + render loop runnable with `swift test` on macOS with no
  Xcode project and no simulator; makes the project file a non-source of merge conflicts.
- **Consequence that bit later**: every iOS-26-only API had to be `#if os(iOS)`-gated to keep
  the macOS build alive. This is *why* the Liquid Glass code was written the way it was.
- **Evidence**: `project.yml`, three `Package.swift`, `.gitignore:15` [Verified]

### A-2 · TDD for `SsakCore`, tests must genuinely discriminate — `ACTIVE`

- **Decided**: write the failing test first; a regression test that passes on unfixed code is
  not a regression test.
- **Enforcement history**: in `b68d872` the agent added a NaN-boundary regression test that
  **passed on the unfixed code** (Swift's `max(x, y)` returns `x` when `y` is NaN) and said so
  honestly in the commit body. Later, `888c3de` hardened four weak tests — a vacuous
  below-seed wilt case, the untested `!isNursing` short-circuit, the untested corrupt-file
  decode path, and the exact wilt boundaries — *each proven to fail on mutated source before
  commit*.
- **Current state**: 39 core tests, all discriminating as far as was checked.
  **Do not re-report those four as open findings** — they were fixed [Verified: `WiltTests.swift`, `PersistenceTests.swift`].
- **Evidence**: `RETROSPECTIVE.md` §4 · commits `b68d872`, `888c3de` [Verified]

### A-3 · `reconcile` does **not** reset the streak counter — `ACTIVE` (deliberate, documented)

- **Decided**: the persisted `streak` is only re-based on the next `water()`. Whether the
  streak is *alive* is derived at the consumer from `lastWateredAt`, exactly like
  `hasWateredToday`.
- **Why**: D12 (penalty-free streaks) plus keeping `reconcile` free of a `Calendar` parameter.
- **Known consequence**: the stored counter can briefly overstate after neglect until the
  next watering. Accepted, and written into the source as a comment.
- **Never done**: the in-code `ponytail:` note proposing "derive effective streak in UI".
- **Evidence**: `GrowthEngine.swift:36-40` · `GardenModel.isStreakAlive` [Verified]

### A-4 · Local JSON persistence, silent failure — `ACTIVE`

- **Decided**: one `Codable` file `ssak.json`, atomic write, `try? store.save(state)`
  — a failed local save is non-fatal and silent; a corrupt file returns `nil` and the game
  starts fresh with no migration path.
- **Why**: zero-stakes local save; an error dialog would violate the calm brief.
- **Evidence**: `PlantStore.swift` · spec §4 states table [Verified]

### A-5 · Headless render-to-PNG authoring loop — `ACTIVE`

- **Decided**: `SsakArtRender` / `SsakAppRender` executables render screens to PNG via
  `ImageRenderer`, so art can be iterated without a simulator, and a curated set of reference
  PNGs is whitelisted into git per package.
- **Consequences that shaped real code** (all still present):
  - the shelf grid is a plain `VStack`/`HStack`, **not** `LazyVGrid` — lazy children never
    materialize under `ImageRenderer` and the refs came out empty;
  - `ShelfView` splits `#if os(iOS) ScrollView #else` top-aligned+clipped;
  - `SsakAppRender` renders a **throwaway warm-up view** first, because a freshly
    CoreText-registered font's first one-shot render comes back zero-sized.
- **Hard limit discovered**: PNG bytes are **environment-sensitive** — the committed refs
  already differ byte-wise on a different SDK, while same-machine re-renders are
  byte-identical. So committed refs must never be the comparison target; capture a
  same-machine baseline first.
- **Evidence**: `ShelfView.swift:22-28,52` · `SsakAppRender/Render.swift:17-23` ·
  `docs/superpowers/plans/2026-07-20-ssak-redesign-ui.md` Global Constraints [Verified]

### A-6 · PR #35 closed unmerged, reopened as #36 — `SUPERSEDED` (mechanical)

- #35 (`ssak-art-species`) targeted `ssak-art-foundation` instead of `main`; it was closed
  and re-opened as #36 against `main`, which merged. Not a design reversal.
- **Evidence**: `gh pr list --state all` [Verified]

### A-7 · ADR-0001 — no sound, no haptics — `ACTIVE`

- **Decided**: ship silent, with no haptic feedback at all.
- **Why**: calm is the product. Audio and haptics both make the app *demand* attention,
  and both add asset/permission surface for zero mechanical value.
- **Evidence**: `docs/adr/0001-no-sound-no-haptics.md` · README [Verified]

---

## Era 3 — UI redesign round 1, 2026-07-20

### R-1 · Adopt iOS 26 Liquid Glass as progressive enhancement — `REVERSED`

- **Decided**: adopt `glassEffect` behind availability checks, with a hand-rolled fallback
  for iOS 16–25 and for macOS; a whole component kit (`TopNavPill`, `WaterButton`,
  `GlassIconButton`, `StreakBadge`, `MoistChip`, `DropGauge`, `WateredTodayTick`).
- **Why then**: it was the platform's new visual language and looked modern for free.
- **What changed**: round 3 deleted the entire kit.
- **Why it changed**: the glass look never resolved into something *calm*; round 3's spec
  decision D12 is literally titled "Retire dead glass." The direction moved to paper, and
  translucent chrome fought the paper.
- **Current state**: **gone from the app.** The stale README Liquid Glass claim and old
  portfolio images were corrected during the final archive on 2026-09-05.
- **Evidence**: `8443d50` (adopt) → round-3 spec D12 → `1ea45a4` (retire) [Verified]

### R-2 · Real-time sky backdrop (`SkyBackdrop`) — `SUPERSEDED`

- **Decided**: the window shows a sky that tracks the actual time of day.
- **Deliberate deviations recorded in the plan**: no `TimelineView` for the sky (the parent
  already re-renders), and `SkyBackdrop(now:calendar:)` injects the calendar rather than
  reading `.current` — so tests stay deterministic.
- **Superseded by** `RoomScene` (round 2) then `HanjiBackdrop` (round 3). The
  `TimeBand` concept it introduced **survives all three** and is still what drives the
  hanji paper today.
- **Current state**: `SkyBackdrop.swift` still exists in `SsakArt`, referenced only by the
  render harness. See `PROJECT_HANDOFF.md` §10 item 1.
- **Evidence**: `docs/superpowers/plans/2026-07-20-ssak-redesign-ui.md` [Verified]

### R-3 · Extract `SoilState`; dedupe `Calendar.dayGap` — `ACTIVE`, with one `DEFERRED` half

- **Decided**: give the dry/moist/overfull category one home (`SoilState`) since the UI read
  it three different ways; give the streak counter and the streak-alive check one shared
  day-gap helper so they cannot disagree.
- **Deferred, explicitly**: adopting `SoilState` *inside* `GrowthEngine` too. The doc comment
  says the redesign "keeps existing engine logic untouched." Still deferred today — the
  engine re-derives the bands from tuning inline.
- **Evidence**: `SoilState.swift` doc comment · `CalendarDayGap.swift` [Verified]

### R-4 · ADR-0002 — do **not** abstract species art dispatch — `ACTIVE`

- **Decided**: keep the flat 24-arm `switch (species.id, stage)` in `PlantView`, with a
  `Placeholder` default. Reject a protocol/registry/`SpeciesArt` abstraction.
- **Why**: with a fixed catalog of six the switch is exhaustive-by-inspection, the compiler
  points at the exact missing case, and an abstraction buys nothing but indirection.
- **Reconsider only if** (stated in the ADR): the catalog grows past ~10 species, or
  string-key typos start causing real bugs.
- **Consequence**: `Placeholder` is unreachable today but deliberately retained as the
  mechanism that makes an unimplemented species visible instead of blank.
- **Evidence**: `docs/adr/0002-species-art-dispatch.md` · `PlantView.swift:72` [Verified]

### R-5 · Bloom-Point app icon — `ACTIVE`

- **Decided**: a single 싹 sprout mark (`SsakMark`) reused as app icon, watermark, and empty
  shelf slot, with the icon geometry specified numerically in the round-1 spec appendix.
- **Evidence**: round-1 spec Appendix A · `SsakMark.swift` · `art/appicon/` [Verified]

### R-6 · Accessibility pass — `ACTIVE`, partially `DEFERRED`

- **Decided**: VoiceOver labels on hero/water/share/gauge/shelf slots, Dynamic Type via
  semantic styles, Reduce Motion gating, ≥44pt targets.
- **Deferred at round 3**: localizing the VoiceOver strings to Korean when the visible UI
  went Korean-first. Chosen deliberately over silently mixing languages.
- **Current state**: **UI is Korean, VoiceOver is English.** Known and intentional.
- **Evidence**: round-3 spec D1 · `InkKit.swift:86` `// VoiceOver stays English this round` [Verified]

---

## Era 4 — UI redesign round 2, 2026-07-22 → 07-23

### R-7 · Bottom `TabView` → top glass pill nav — `SUPERSEDED`

- Replaced by round 3's ink text tabs (`InkNavTabs`). Two full navigation rewrites in four days.

### R-8 · `RoomScene` — put the plant in a living room — `SUPERSEDED`

- **Decided**: a drawn interior (wall, sill, board) so the plant sits somewhere rather than
  floating on a gradient.
- **Superseded by** the hanji album in round 3, which abandoned literal depiction of a room
  entirely. The `wall`/`board` parameters threaded through `PlantView` are a leftover of it.
- **Current state**: `RoomScene.swift` still in `SsakArt`, app-dead, harness-live (round-3
  D12 kept it as an "art library + harness reference").
- **Evidence**: round-3 spec D12 · `git grep RoomScene` [Verified]

### R-9 · Three-screen `OnboardingView` → coach-mark `StartGuide` — `ACTIVE`

- **Decided**: delete the separate onboarding screens; teach in place with spotlight coach
  marks anchored to real controls via a `PreferenceKey`.
- **Why**: a calm one-plant game shouldn't open with a slideshow; teaching on the real screen
  keeps the first thing you see the actual game.
- **Evidence**: `1782300` · `StartGuide.swift` [Verified]

---

## Era 5 — UI redesign round 3: 한지 압화집, 2026-07-23 → 07-24

The final visual direction: the app is a **hanji (한지) pressed-flower album**. Spec decisions
D1–D12 in `docs/superpowers/specs/2026-07-23-ssak-round3-hanji.md`.

### R-10 · Korean-first UI copy — `ACTIVE`

- 메리골드 · 창가 · 압화집 · "흙이 촉촉해요". Round-3 D1. VoiceOver stayed English (see R-6).

### R-11 · Bundle and register Nanum Myeongjo via CoreText — `ACTIVE`

- **Decided**: ship the font in `SsakApp` resources (SIL OFL, `OFL.txt` bundled) and register
  it at runtime from `Bundle.module` rather than declaring it in an Info.plist.
- **Why**: the same code path then works in the app, in `swift test`, and in the macOS render
  harness — an Info.plist entry works in none of the latter two.
- **Evidence**: `SsakFonts.swift` · `SsakApp/Package.swift` resources [Verified]

### R-12 · Retire dead glass (D12) — `ACTIVE` (this is the execution of R-1's reversal)

- Deleted: `TopNavPill`, `WaterButton`, `GlassIconButton`, `StreakBadge`, `MoistChip`,
  `DropGauge`, `WateredTodayTick`.
- **Explicitly kept**: `RoomScene` and `SkyBackdrop` in `SsakArt` as art-library + harness
  references; the app simply stops using them.
- **Evidence**: round-3 spec D12 · `1ea45a4` [Verified]

### R-13 · Status chrome: `StatusCluster` → `MoistChip` → `InkGauge` — `ACTIVE` (third form)

- Three consecutive representations of the same moisture reading in five days. The current
  one is an ink gauge with Korean soil copy.

### R-14 · Idle chrome-fade — `REVERSED` within the same round

- **Decided**: fade the chrome away when idle to maximize calm. **Shipped, then removed**
  (`912f7fb`) — the disappearing controls read as broken rather than calm, and interacted
  badly with the coach marks.
- A clean example of a "calm" idea that was correct in the abstract and wrong in the hand.

### R-15 · Bug fixes in this round (all `ACTIVE` fixes)

| Commit | Bug |
|---|---|
| `72c3b95` | **The core loop dead-ended.** `pressAndReplant` was only reachable by tapping an *already-collected* shelf card, so a first bloom could never be pressed — the six-species collection was unreachable from the UI. Every test passed. Fixed by making the current species' slot the press target when `model.stage == .bloom` [Verified: `ShelfView.swift` `pressHere`]. |
| `cfdbe05` | The share card always drew a bloom regardless of actual stage. |
| `ec1646e` | The clock was frozen — no periodic re-render; fixed with `TimelineView(.periodic, 60)`. |
| `ba0cb00` | A coach-mark spotlight that landed correctly in the simulator **missed on device** and leaked taps through the cutout. |
| `1150f2f` | Over-full state gave mixed signals across the three places moisture was displayed. |

`72c3b95` and `b68d872` are the two findings the retrospective holds up as *the* failure mode
of unreviewed agent output: "it ships code that passes tests but doesn't play," and
"it writes tests that don't discriminate."

### R-16 · Day-1 watering tutorial: the first seed starts thirsty — `ACTIVE`

- **Decided**: `firstSeed(...)` sets `moisture = 0.15` and `lastWateredAt = nil` so the very
  first plant *needs* water immediately and the tutorial has something real to teach.
- Paired with the start-screen **seed picker** (`choosePlant`, guarded to `stage == .seed &&
  collected.isEmpty`), added 2026-07-24.
- **Evidence**: `GardenModel.swift` [Verified]

---

## Era 6 — Licensing, 2026-07-30 → 08-02

### L-1 · MIT license → all rights reserved — `REVERSED`

- **Originally**: an MIT `LICENSE` file was added, and plan docs referenced it.
- **Reversed**: `LICENSE` deleted; README license section rewritten to
  *"Copyright (c) 2026 Michael Ju. All rights reserved. No license is granted … This
  repository is public for portfolio review purposes only."*, dated 2026-07-30, and moved to
  the end of the README. Plan docs corrected in a follow-up.
- **Why**: the repo is public for portfolio reading, not for reuse. Open-sourcing it was not
  the intent; MIT had been a reflex.
- **Current state**: **no `LICENSE` file exists, and that is correct.** Do not "fix" it.
- **Evidence**: `722002e`, `9186553`, `f3fc8e7` · `README.md:93-96` · no `LICENSE` in `git ls-files` [Verified]

---

## Era 7 — Agent harness decisions (about how the project was *built*, not about the product)

### H-1 · A repo-level operating manual (`CLAUDE.md`) + glossary (`CONTEXT.md`) + ADRs — `ACTIVE` in spirit

- **Decided**: write things down before building; the retrospective calls this "load-bearing,
  not overhead — when a doc was vague, the code was wrong."
- **Still true and portable**: `CONTEXT.md` (the domain glossary) and `docs/adr/`.
- **Not portable**: the `CLAUDE.md` "Agent skills" section and `docs/agents/`, which encode the
  conventions of specific Claude plugins. `mattpocock-skills` is still installed; the
  `superpowers` plugin that actually drove the Ssak build — and produced `docs/superpowers/`
  and the untracked `.superpowers/` working directory — **is no longer installed**
  [Verified: absent from `~/.claude/plugins/cache`].

### H-2 · Inline a shared "working standard" into `CLAUDE.md` — `REVERSED`

- **Decided 2026-07-27** (`2bc6db5`): paste a ~50-line global baseline into the project file
  so the rules travelled with the repo.
- **Reversed 2026-08-02** (`9fa6a5d`, "Remove inlined global baseline from CLAUDE.md"): six
  days later. Duplicating a global standard into every repo makes it stale in every repo.
- **Bearing on the Codex migration**: this reversal is a small precedent for the current
  brief — the author has already once decided that agent-behavior rules should not be copied
  into the project.
- **Evidence**: `git show 2bc6db5 9fa6a5d` [Verified]

### H-3 · Five-label triage vocabulary — `ACTIVE` as a record, `LIKELY-OBSOLETE` as a workflow

- `needs-triage` / `needs-info` / `ready-for-agent` / `ready-for-human` / `wontfix`, mapped in
  `docs/agents/triage-labels.md`. It was used for real: all 32 Meok issues were triaged and
  closed, ten as `wontfix`. Zero Ssak issues were ever filed — the Ssak era ran on specs and
  plans instead, so the tracker fell out of use *before* the project closed.
- **Evidence**: `gh issue list --state all` [Verified]

### H-4 · Push to `main` directly during the closing phase — `ACTIVE` (one-off, expired)

- The author granted a session-scoped exception to the standing "never push to main" rule
  while closing the project out ("I approve you to push to main in this session. It's an
  exception.").
- **This exception does not carry forward.** The repo is archived; pushes are rejected anyway.
- **Evidence**: [Conversation — Claude session transcript, 2026-08]

---

## Era 8 — Closing, 2026-08-24

### C-1 · Stop the project deliberately — `ACTIVE`

- **Decided**: close Ssak rather than continue. Written up in `RETROSPECTIVE.md` §7:
  *"Because I got what I came for."* Both stated goals (build a game; learn where the agent
  workflow breaks) were met; everything past this point would be maintenance of a game with
  no players for a store he wasn't going to submit to.
- **Executed**: retrospective written, README status block added, walkthrough GIF recorded
  (iOS 26.5 simulator), `v1.0-final` tagged, GitHub repo **archived read-only**.
- **Evidence**: `b69e754` · `gh repo view` `isArchived: true` [Verified]

### C-2 · `POSTMORTEM.md` → `RETROSPECTIVE.md` — `ACTIVE`

- Renamed in `a46f851`, the final commit. "Postmortem" framed a deliberate stop as a death.

### C-3 · Corrected the file/LOC count — `ACTIVE`

- `832517a` fixed "63 files / 5,720 lines" to **59 files / 4,066 lines** — the first figure
  had counted generated `.build/` runner files. Claude's auto-memory still carries the old
  number; see `PROJECT_HANDOFF.md` §15.

### C-4 · Korean retrospective written but never published — `DEFERRED`

- `docs/ko/RETROSPECTIVE.ko.md` (121 lines) was translated for velog/tistory. It is
  **deliberately gitignored** (`.gitignore:18` "Korean drafts — local only") and was never
  posted. It exists only on this machine.
- **Evidence**: [Verified: file present, `.gitignore` entry]

### C-5 · Two device defects accepted, not fixed — `ACTIVE` (accepted)

1. **iOS 26.0 simulator makes the chrome nearly invisible** on cream hanji (top nav, day
   counter, water button). **iOS 26.5 renders correctly** — always use 26.5 for this repo.
   Judged a simulator rendering issue, not an app bug.
2. **The 압화집 tab's hit area sits ~14pt below its label** — synthetic taps at the glyphs
   (y≈90) miss; y≈104 works. A real thumb hits it, so it was left.
- **These exist in no repo file.** Preserved here from Claude's auto-memory.
- **Evidence**: [Conversation — `~/.claude/.../memory/ssak-closed.md`]

### C-6 · Pin the repo on the GitHub profile — `COMPLETED` (2026-09-05)

- Pinned `mhju0/ssak`, replacing `glass-table` under the author's delegated judgment.
  Ssak adds a finished Swift/iOS game and retrospective while preserving the four featured
  AI/backend projects and `allergy-tracker`; `glass-table` remains linked in the profile README.
- Completed through GitHub's *Customize your pins* UI. The earlier inference that no
  profile-pinning API meant no automation was incorrect; no new integration was needed.
- **Evidence**: [Verified 2026-09-05: GitHub displayed "Your pins have been updated" and
  listed `ssak` among the six pinned repositories.]

---

## Era 9 — Toolchain handoff, 2026-09-04 → 09-05

### T-1 · Move from Claude Code to OpenAI Codex, without cloning the harness — `ACTIVE`

- **Decided**: hand the project to Codex, deliberately separating (1) facts about the project,
  which are preserved, from (2) instructions Claude needed to behave well and (3) historical
  preferences a current model handles unprompted — neither of which is migrated.
- **Why**: start the new toolchain with a smaller, cleaner surface. Not a criticism of the old
  harness; the point was to avoid inheriting accumulated agent scaffolding by default.
- **Executed**: `docs/PROJECT_HANDOFF.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md`, and
  `docs/CLAUDE_ENV_INVENTORY.md` written from the code, git history, specs, ADRs and Claude
  session transcripts. **Nothing Claude-side was carried over** — no global instructions,
  skills, MCP servers, hooks, subagents, or preferences.
- **Precedent**: this is the same conclusion reached once before, when an inlined agent
  baseline was added to `CLAUDE.md` and removed six days later (see H-2).
- **Evidence**: this repo's `docs/` · [Conversation — 2026-09-04/05 handoff sessions]

### T-2 · A minimal `AGENTS.md`, and only that — `ACTIVE`

- **Decided**: add a ~28-line `AGENTS.md` carrying three things a new agent cannot derive from
  the repo: that the project is closed and archived, the ordered hierarchy of where truth
  lives (code → git → DECISIONS → ROADMAP → HANDOFF → historical Claude material), and when
  each doc should be updated.
- **Why this and nothing more**: Codex reads `AGENTS.md` and does not read `CLAUDE.md`, so the
  operating agreement had no other home. Everything else — build commands, architecture,
  known defects — already lives in the docs the hierarchy points at, and duplicating it would
  guarantee drift.
- **Standing bar for adding more**: a *repeated* real limitation, matched to the smallest fix
  — `AGENTS.md` for a persistent project-wide instruction, a skill for a reusable workflow,
  MCP for an external tool or data connection, Codex config for actual runtime configuration.
  Not a new instruction because something happened once.
- **`CLAUDE.md` is left in place** as part of the historical record; it is not maintained.

---

### T-3 · One final archival synchronization, then permanent closure — `ACTIVE`

- **Decided 2026-09-05**: the author explicitly authorized temporarily unarchiving GitHub,
  publishing all recent documentation and final assets through a PR, merging it, synchronizing
  local `main`, and archiving again. This is archival work; product development remains closed.
- Preserve the Korean retrospective draft in git; external blog publication remains unrequested.
- Refresh the README hero and social preview from the final SwiftUI interface, remove the
  obsolete MIT claim in the old social card, and keep the historical tags unchanged.
- **Evidence**: author instruction, 2026-09-05; [final archive record](FINAL_ARCHIVE.md).

---

## Appendix — decisions whose rationale is not recoverable

| Item | Status |
|---|---|
| The exact `bloomDays` values (7 / 8 / 9 / 10 / 11 / 13 — note the jump from 11 to 13) | `UNKNOWN`. The spec says pacing was "tuned by feel, not derived." No record explains the skipped 12. |
| The tuning constants (`waterAmount 0.6`, `drainPerDay 0.55`, `moistureMax 1.3`, `glowStreak 3`) | `UNKNOWN` numerically; `ACTIVE` and centralized by D13. Same "by feel" note applies. |
| `MARKETING_VERSION 0.1.0` never bumped, even for `v1.0-final` | `UNKNOWN` — most likely simply never revisited, since no build was ever distributed. |
