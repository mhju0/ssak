# Ssak — postmortem

**2026-07-15 → 2026-08-02 · 186 commits · closed on purpose.**

This is the write-up for a project that is finished and will not continue. It covers what
I set out to do, the game I scrapped first, what actually got built, what Fable was and
wasn't good at, and why it stops here.

---

## 1. What I actually set out to do

Two goals, both modest:

1. **Build a game.** I had never made one.
2. **Run a whole project through Anthropic's Fable model** — spec to shipping build — and
   find out where that workflow actually breaks. I had never used it.

Neither goal was "publish to the App Store" or "get players." I want to be exact about
that, because by the goals I set this went fine, and by goals I never set it looks like a
failure. It isn't one. It's a finished experiment.

---

## 2. The game I scrapped first

The repo starts as **Meok (먹)** — an ink-wash skilling RPG. Six skills (fishing,
foraging, cooking, crafting, gardening, artistry), an XP curve, unlock tables, a
procedurally rendered ink world that reacted to your city's real weather and solar
position.

It got **66 commits in 5 days**, through milestone M3. It worked. There was a scrolling
tall-scroll world with parallax ink layers, a day/night solar curve, rain that bled into
the paper, a keeper figure that walked, an end-to-end fishing loop with 11 species, and
SwiftData persistence.

I killed it anyway.

The honest reason: M0–M3 had shipped and the remaining scope — three more skills, unlock
tables for all six, visitors, a gallery — was *larger than everything already built*, and
I was five days in. The design ledger for a first game shouldn't have six interlocking
progression systems in it. I had confused "ambitious" with "good."

**Everything survives at the git tag [`meok-archive`](../../tree/meok-archive)** (66
commits, nothing deleted). The scrap is inspectable, which is the point — deciding to stop
is only credible if you can see what was stopped.

Scrapping working code was harder than scrapping broken code would have been, and it's the
decision in this repo I'm most confident was right.

---

## 3. What Ssak is

The restart, four days later, deliberately small enough to finish: **one** plant on a
windowsill, raised on the real clock, six species to collect. 119 commits over 15 days.

It plays. Plant a marigold, water it, come back tomorrow. It grows through five visibly
distinct stages on a compressed real-time schedule (~1 real day ≈ 1 plant-week), but
**only while it's healthy** — too dry or over-watered and progress pauses. Sustained
neglect wilts it back exactly one stage, never below seed, never to death. Bloom, press it
to the shelf, pick the next seed. Six pressed blooms completes the garden.

**Shape** — 59 Swift files, 4,066 lines, three SwiftPM packages:

| Package | What it is |
|---|---|
| `SsakCore` | Pure, time-injected game logic — growth, moisture, wilt, streaks, persistence. No UI, no clock of its own. **39 tests.** |
| `SsakArt` | Every flower hand-drawn in SwiftUI `Path`s, authored through a headless render-to-PNG loop. No runtime art engine. **4 tests.** |
| `SsakApp` | The screens over a single `GardenModel` reducer. **15 tests.** |

**58 tests, 0 failures** (verified 2026-08-24, Xcode 26.6).

Everything is local. No backend, no accounts, no third-party dependencies, no analytics,
no ads, no IAP. No sound and no haptics — by decision, not omission
([ADR-0001](docs/adr/0001-no-sound-no-haptics.md)).

The design went through a **14-decision ledger** (D1–D14, spec Appendix A) before any code,
and the UI went through **three complete redesign rounds** — Liquid Glass → a living
`RoomScene` with top-pill navigation → a 한지 압화집 (hanji pressed-flower album) that
retired the glass kit entirely.

---

## 4. What the agent workflow was and wasn't good at

The whole project was built by driving Claude Code on Anthropic's Fable model from written
specs and plans, with a repo-level operating manual (`CLAUDE.md`), a domain glossary
(`CONTEXT.md`), ADRs, and a five-label triage vocabulary (`docs/agents/`). Findings, in
rough order of how much they surprised me:

**Where it was genuinely strong**

- **Pure, well-specified logic.** `SsakCore` is the best code here, and it's the part that
  was easiest to specify: deterministic, time-injected, no UI. Growth/moisture/wilt math
  with 39 tests came out clean and stayed clean.
- **Breadth of mechanical work.** Six species of hand-authored vector art, each across five
  growth stages, is tedious in a way that never became a bottleneck.
- **Writing things down was load-bearing, not overhead.** The decision ledger and ADRs
  weren't ceremony — they were how the agent stayed consistent across 186 commits. When
  a doc was vague, the code was wrong.

**Where it broke, with receipts**

- **It ships code that passes tests but doesn't play.** The worst bug in the repo:
  `pressAndReplant` was only reachable by tapping an *already-collected* shelf card, so a
  first bloom could never be pressed and the six-species collection was literally
  unreachable from the UI. The core loop was a dead end. Every test passed. Fixed in
  [`72c3b95`](../../commit/72c3b95). Nothing in a test suite catches "the game has no
  second half" — only playing it does.
- **It writes tests that don't discriminate.** In [`b68d872`](../../commit/b68d872) the
  agent added a regression test for a `0/0` NaN at the dry-moisture boundary — and the
  test passed on the *unfixed* code, because Swift's `max(x, y)` returns `x` when `y` is
  NaN. It documented this honestly in the commit message rather than claiming a red-green
  cycle, which is the good outcome. But a test that never failed is not a regression test,
  and I'd only have caught that by reading it.
- **Taste doesn't come from a spec.** Three full UI redesign rounds. The agent will
  faithfully build the interface you described and it will be lifeless. Every round was me
  looking at a screenshot and saying "no, not that." That loop never got shorter.
- **Simulator ≠ device.** [`ba0cb00`](../../commit/ba0cb00) — a coach-mark spotlight that
  landed correctly in the simulator missed its target on device and leaked taps through
  the cutout.

**My own read**

*Design was the wall.* I'm mostly a backend developer. I had ideas for how Ssak should look
and feel and almost no ability to get them out of my head and into code — and that gap, not
the game logic, is what three redesign rounds actually measure. The agent could build any
interface I was able to describe precisely. I wasn't able to describe one precisely.

*I became the bottleneck, so I stopped reviewing.* Partway through, I was the slowest part
of the loop — it produced faster than I could read. Fable was only supposed to be available
for a few days, so I was working against a clock, and I let code review go to keep moving.
The two worst findings above — a core loop that dead-ended, and a regression test that never
failed — are exactly the shape of thing that gets through when nobody reads the diff. Given
the deadline I don't think rushing was the wrong call. I think the mistake was dropping
review wholesale instead of deciding which few things I couldn't afford to stop reading.

*Spec-first felt faster.* I believe the write-the-spec-then-build loop beat writing the code
directly. I want to be honest that this is a feel and not a measurement — I have no A/B
here, and the commit history isn't evidence of it.

*I'd change the order, not the tool.* Next time I want to find real design references first
and think like a designer before writing a line: map the thing out concretely — every
screen, every button, the layout, what kind of game it actually is — then design against
that, then code. This one went spec → code → "no, not that," three times over. The next one
starts at design.

---

## 5. Limits — what this is not

- **Never submitted to the App Store**, and won't be. No provisioning, no review, no
  privacy manifest.
- **Simulator-verified, lightly device-tested.** Runs on the iOS 26 simulator; only some
  polish passes were checked on hardware.
- **Zero players.** Nobody has played this but me, so every claim about it being calm or
  cozy is untested against a real person.
- **No sound, no haptics, no notifications, no iCloud sync, no weather or season
  reactivity** — all explicitly out of scope (spec §10), not missing by accident.
- **Ten features cut as `wontfix`**, mostly Meok's unfinished progression systems.
- **The long game is untested by definition.** A full six-species collection takes weeks of
  real time. I have never watched one complete without moving the clock forward.
- **Not licensed for reuse.** Public for reading, not for use — see the README.

---

## 6. What I'd do differently

1. **Play the loop end-to-end before building the second screen.** The dead-end press bug
   existed because I trusted a green test suite over five minutes of actually playing.
   For a game, a passing test says almost nothing about whether it works.
2. **Set the stop condition in the spec.** The spec has success criteria (§11) but no
   definition of *done enough to stop*, so I stopped by running out of interest rather
   than by hitting a line I'd drawn in advance. Meok died the same way, louder.
3. **Start at design, not at spec.** Three redesign rounds cost more than a week of
   collecting references would have. Settle the visual direction and map every screen and
   button concretely *first*, then write the spec against it. I described a feeling and
   expected an interface.
4. **Decide up front what I will never stop reviewing.** When I became the bottleneck I
   dropped review wholesale instead of triaging it. A two-line rule — anything touching the
   core loop, and every new test's assertion — would have caught both bugs above at a
   fraction of the cost of reading everything.
5. **Cut Meok at day two, not day five.** The scope problem was visible in the design
   ledger before M0 shipped. I saw it and kept building anyway.

---

## 7. Why it stops here

Because I got what I came for.

I wanted to know whether I could build a game and what it feels like to run a real project
through an AI agent. I now know both, in specific detail rather than in the abstract — the
receipts are in §4. Ssak reached a state where the thing I set out to learn was learned,
and everything past this point would have been maintenance of a game with no players, for
a store I wasn't going to submit to.

Continuing out of momentum is how Meok nearly went wrong. Stopping deliberately, with the
repo working, the tests green, and the reasoning written down, is the better ending —
and it's the same call I made at day five, made once more with less drama.

The repo is archived read-only. It builds, it runs, it plays. That's a finished thing.

---

*Michael Ju · 2026-08 · [github.com/mhju0/ssak](https://github.com/mhju0/ssak)*
