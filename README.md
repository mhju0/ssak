<div align="center">

<img src="art/appicon/appicon-1024.png" width="124" alt="Ssak app icon" />

# Ssak&nbsp;·&nbsp;싹

**Raise one flower from seed to bloom — on the real clock, tended gently, six to collect.**

<p>
  <img src="https://img.shields.io/badge/iOS-16%2B-5F8F45?style=flat-square&amp;logo=apple&amp;logoColor=white" alt="iOS 16+" />
  <img src="https://img.shields.io/badge/Swift_5.9-SwiftUI-F05138?style=flat-square&amp;logo=swift&amp;logoColor=white" alt="Swift 5.9 · SwiftUI" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-5F8F45?style=flat-square" alt="License: MIT" /></a>
</p>

<img src="SsakApp/rendered/windowsill_bloom_day.png" width="248" alt="A marigold blooming on the windowsill" />

</div>

---

**Ssak** (싹, *"sprout"*) is a calm, quiet iOS game. You keep **one** plant on your
windowsill and raise it at the speed of a real plant — no timers to beat, nothing to
spend. Water a little, come back tomorrow, watch it grow.

### How it plays

- **On the real clock.** Your flower grows on its own compressed timeline — about a
  real day per plant-week — and only while it's healthy. Patience is the mechanic.
- **One at a time.** No sprawling garden to manage: one flower, your full attention,
  seed to bloom.
- **Forgiving by design.** Droop and gentle nudges, never punishment — no permadeath,
  and your shelf of past blooms is never lost.

### Collect six

<div align="center">
<img src="SsakArt/rendered/all_species_grid.png" width="100%" alt="The six species, each rendered seed to bloom" />
</div>

Marigold · Nasturtium · Cosmos · Zinnia · Sunflower · Morning&nbsp;glory — press each
bloom to your shelf.

### Run it

**You'll need** macOS with Xcode 16 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen     # once
xcodegen generate         # from the repo root → Ssak.xcodeproj
open Ssak.xcodeproj        # pick a Simulator ▸ Run
```

`Ssak.xcodeproj` is generated from `project.yml` and isn't committed — re-run
`xcodegen generate` whenever the package set changes.

### Built with

100% Swift/SwiftUI · no backend · no third-party dependencies · hand-authored static
vector art. The game is three SwiftPM packages:

- **`SsakCore`** — pure, time-injected game logic (growth, moisture, streaks, persistence), fully unit-tested.
- **`SsakArt`** — every flower hand-drawn in SwiftUI `Path`s, authored through a headless render-to-PNG loop; no runtime art engine.
- **`SsakApp`** — the screens over a single `GardenModel` reducer.

No sound, no haptics — calm is the whole point ([ADR-0001](docs/adr/0001-no-sound-no-haptics.md)).

### Docs

- **Design spec** — [`docs/superpowers/specs/2026-07-20-ssak-redesign.md`](docs/superpowers/specs/2026-07-20-ssak-redesign.md)
- **Domain glossary** — [`CONTEXT.md`](CONTEXT.md)
- **Decision records** — [`docs/adr/`](docs/adr/)

### License

MIT © 2026 Michael Ju — see [LICENSE](LICENSE).
