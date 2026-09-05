# Ssak (싹) — Roadmap

**Compiled 2026-09-04; updated 2026-09-05.** Reflects the project's *current* intent, not accumulated
brainstorming.

> ## The honest summary
>
> **NOW, NEXT and LATER are empty.** Ssak was closed deliberately on 2026-08-24 and the
> GitHub repo is archived read-only. This document exists mainly to record what was
> **decided against**, so that a future reader (or agent) does not mistake a rejection for a
> gap and start "finishing" the project.
>
> Nothing below is a commitment. The sections that carry real information are
> **EXPLICITLY REJECTED** and **COMPLETED RECENTLY**.

---

## NOW

*Nothing.*

There is no active development. The last product-code commit was `63e1f4c` (2026-07-24);
everything after it is documentation and closing work.

No administrative items remain open. The GitHub profile pin was completed on 2026-09-05.

---

## NEXT

*Nothing.*

If the project were ever resumed, these are the items that were closest to being real work —
listed as **candidates, not plans**, and none of them was ever committed to:

| Candidate | Where it came from | Note |
|---|---|---|
| Localize VoiceOver strings to Korean | Round-3 spec D1 deferred it explicitly | The visible UI is Korean; the accessibility layer is English. Deliberately deferred rather than half-mixed. |
| Delete `RoomScene` + `SkyBackdrop` from `SsakArt` | Round-3 D12 kept them as "art library + harness references" | ~320 lines the app no longer uses. Dead weight only if someone resumes. |
| Adopt `SoilState` inside `GrowthEngine` | `SoilState.swift` doc comment: "could be adopted too (deferred: the redesign keeps existing engine logic untouched)" | Would remove the engine's inline re-derivation of the same bands. |
| Derive the effective streak in the UI | `ponytail:` note in `GrowthEngine.swift:40` | Would remove the "persisted streak can briefly overstate after neglect" wart. |

**None of these is scheduled.** They are recorded so that finding them later reads as
"known and deferred," not "overlooked."

---

## LATER

*Nothing.*

The project has no long-horizon plan. Its stop condition was reached — see
[`RETROSPECTIVE.md`](../RETROSPECTIVE.md) §7.

---

## BLOCKED

| Item | Blocked by |
|---|---|
| **Any push to GitHub** | The GitHub repo `mhju0/ssak` is **archived read-only**. Pushes are rejected until someone un-archives it in repo settings. [Verified: `gh repo view` → `isArchived: true`] |
| Real-device photography | Never completed. The final README now uses a clearly labeled headless render of the current UI. |
| Publishing the Korean retrospective | `docs/ko/RETROSPECTIVE.ko.md` is preserved in git as an archival draft but not posted to a blog. Blocked on the author's decision to publish, nothing technical. |
| Validating that the game is "calm" | Zero players. Cannot be answered without someone else playing it. |
| Validating the six-species long game | Takes weeks of real time; only ever observed by moving the clock forward. |

---

## CONSIDERED BUT NOT COMMITTED

Ideas that were genuinely discussed and left in an undecided state — **not** rejected, but
never adopted. Do not treat these as backlog.

- **Abstracting species art dispatch** behind a protocol/registry. Explicitly *not* done
  ([ADR-0002](adr/0002-species-art-dispatch.md)), but the ADR names its own reopening
  condition: *reconsider only if the catalog grows past ~10 species, or string-key typos
  start causing real bugs.* Neither happened.
- **Automating reference-PNG comparison in CI.** The environment-sensitivity of
  `ImageRenderer` output was diagnosed and the mitigation (same-machine baselines) was
  written down — but never automated, and there is no CI to put it in.
- **A schema/migration path for `ssak.json`.** A corrupt or older save silently resets. Fine
  for a local zero-stakes game; would matter only if the game ever shipped.
- **Bumping `MARKETING_VERSION` past `0.1.0`.** Never revisited; no build was distributed.
- **Reviewing only the highest-risk diffs instead of everything.** The retrospective's
  "what I'd do differently" #4 proposes a two-line rule (anything touching the core loop,
  and every new test's assertion). That is advice for the *next* project, not a Ssak task.

---

## EXPLICITLY REJECTED

**This is the most useful section in this file.** Every item here was decided against on
purpose. Re-proposing any of them is a regression, not an improvement.

### Rejected in the Ssak design spec (§10 "Out of scope") and restated in the retrospective §5

- **Notifications / reminders** — the game must never demand attention.
- **Weather or season reactivity** — Meok had it; it is scope, and it makes the game depend
  on the outside world.
- **Sound** — see below.
- **iCloud sync** — no accounts, no network, ever.
- **More than six species** — a fixed catalog is what makes the switch-based art dispatch and
  the "collect them all" ending work.
- **A share studio** (posing/decorating the share card) — one card, one tap.
- **Sharing the shelf** — only a single bloom card is shareable.
- **Any AI-generated raster art** — all art is hand-authored vector.

### Rejected by ADR

- **Sound and haptics** — [ADR-0001](adr/0001-no-sound-no-haptics.md). "Calm is the whole
  point." Both make the app demand attention and add asset/permission surface for zero
  mechanical value.
- **An art-dispatch abstraction** — [ADR-0002](adr/0002-species-art-dispatch.md).

### Rejected by the design ledger (spec Appendix A)

- **A garden grid / multiple simultaneous plants** (D1) — recreates Meok's breadth problem.
- **Plant death or permadeath** (D11) — wilt is a one-stage setback, floored at seed.
- **Streak penalties** (D12) — a missed day ends the streak's effect, never subtracts progress.
- **A runtime procedural art engine** (D5) — named in the spec as *"the specific trap that
  sank Meok."*
- **A backend, accounts, analytics, ads, IAP** (D6).

### Rejected by closing the predecessor — the ten Meok `wontfix` issues

All Meok-era, all closed as `wontfix` when the RPG was scrapped [Verified: `gh issue list --state all`]:
**#9, #10, #11, #19, #20, #28, #29, #30, #31, #32** — the unfinished skill systems (foraging,
cooking, crafting, gardening, artistry), unlock tables, visitors and the gallery.

### Rejected as a product goal

- **App Store submission.** Never a goal; no provisioning, no privacy manifest, no review.
- **Open-source licensing.** MIT was briefly added and then removed — the repo is public for
  portfolio reading, all rights reserved. See [`DECISIONS.md`](DECISIONS.md) L-1. Do not add
  a `LICENSE` file.
- **Continuing the project.** [`RETROSPECTIVE.md`](../RETROSPECTIVE.md) §7. "Continuing out of
  momentum is how Meok nearly went wrong."

---

## COMPLETED RECENTLY

Reverse chronological.

**2026-09-05 — Final archival synchronization**

- Recent handoff documents and `AGENTS.md` preserved, Korean draft included, stale README
  and ADR claims corrected, final UI references refreshed, portfolio assets regenerated.
- Product development remains closed. See [the final archive record](FINAL_ARCHIVE.md)
  for verification and the PR that carries these changes.

**2026-09-05 — GitHub profile pin completed**

- Pinned `mhju0/ssak`, replacing the `glass-table` pin. The other five pins remain;
  `glass-table` remains linked in the profile README.
- Saved and verified through GitHub's *Customize your pins* UI. The earlier claim that
  the absence of a profile-pinning API prevented automation was incorrect.

**2026-08-24 — Project closed**
- `RETROSPECTIVE.md` written (goals, the scrapped predecessor, where the agent workflow broke
  with commit receipts, limits, what he'd do differently, why it stops).
- README "Status — complete and closed" block; walkthrough GIF (iOS 26.5 simulator); social card.
- File/LOC count corrected to 59 files / 4,066 lines (`832517a`).
- `docs/ko/` gitignored (`ea29c50`); `POSTMORTEM.md` → `RETROSPECTIVE.md` (`a46f851`).
- `v1.0-final` tagged; GitHub repo archived read-only.

**2026-08-02 — Harness cleanup**
- Inlined "working standard" removed from `CLAUDE.md` (`9fa6a5d`).

**2026-07-30 → 08-02 — Licensing reversed**
- MIT `LICENSE` deleted; all-rights-reserved notice; plan docs corrected (`722002e`, `9186553`, `f3fc8e7`).

**2026-07-24 — Final product code**
- Seed picker on the start screen; interactive first-watering tutorial; Koreanized guide copy.
- Last product commit: `63e1f4c`.

**2026-07-23 — Redesign round 3 (한지 압화집) + the real bug fixes**
- Hanji paper backdrop across four time bands; Nanum Myeongjo via CoreText; the ink component
  kit; Korean-first copy; the whole Liquid Glass kit retired.
- **Core-loop dead end fixed** (`72c3b95`) — a first bloom was previously impossible to press.
- Share card stage bug (`cfdbe05`); frozen clock (`ec1646e`); on-device spotlight miss
  (`ba0cb00`); over-full mixed signals (`1150f2f`); idle chrome-fade removed (`912f7fb`).

**2026-07-22 → 23 — Redesign round 2**
- `RoomScene`, top pill navigation, `OnboardingView` → coach-mark `StartGuide` (`1782300`).

**2026-07-20 — Redesign round 1**
- Liquid Glass adoption, real-time `SkyBackdrop`, Bloom-Point app icon, accessibility pass,
  `SoilState` extraction, `Calendar.dayGap` dedup, ADR-0002.

**2026-07-19 — Ssak foundation**
- Meok archived + repo/folder renamed; `SsakCore` engine built TDD (PR #33); `SsakArt`
  foundation and all six species (PRs #34, #36); `SsakApp` screens and the iOS shell;
  test hardening (`888c3de`).

**2026-07-15 → 19 — Meok, then scrapped**
- 67 commits through milestone M3; archived at tag `meok-archive`.

---

## Verification status of the "done" claim

Re-checked on 2026-09-05, on Xcode 26.6 / Swift 6.3.3 [Verified: run this session]:

- `swift test` in all three packages: **58 tests, 0 failures** (SsakCore 39 · SsakArt 4 · SsakApp 15).
- `xcodebuild -scheme Ssak -destination 'generic/platform=iOS Simulator' build`: **BUILD SUCCEEDED**.
- The pre-archive baseline was `a46f851`; final synchronization is recorded in [FINAL_ARCHIVE.md](FINAL_ARCHIVE.md).

The project is closed in a working state — not abandoned mid-change.
