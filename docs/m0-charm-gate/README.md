# M0 Charm Gate — review materials

Everything here is rendered live by the stroke engine and shaders — zero
image assets exist in the app. Captured on the iPhone 17 Pro simulator
(iOS 26.5) from the M0 code (issues #1–#7, all closed).

## Materials

| File | What it shows |
|---|---|
| `composite-dry.png` | The composite scene on a clear day: hanji paper, mountain wash, keeper at staffage scale, carp in the valley pond |
| `composite-downpour.png` | Same scene with rain-bleed forced to 0.95 — ink runs down the paper in uneven columns; the carp renders wet from the same recipe |
| `carp-dry-wet.png` | The carp recipe rendered twice from identical data: dry above, wet(0.7) below |
| `keeper-poses.png` | Keeper standing/seated, large and at true staffage scale |
| `reveal-rain.mp4` | Fresh launch under rain: the scene paints itself in (carp stroke-by-stroke, then keeper) |

## How to reproduce

```sh
# clean full-screen run, forced downpour:
xcrun simctl launch <sim> com.mhju0.meok -meok-clean -meok-bleed 0.95
# recipe sheets: -meok-carp / -meok-keeper / -meok-strokes (tap to replay)
```

## The gate (issue #8 — human part)

Show the composite + recording to **≥3 people outside the project**. Per the
design spec (§5, fallback ladder §3), their reactions pick one of:

1. **Proceed** — fully-procedural art direction confirmed; M1 planning unblocked.
2. **Commission** — ~15 hero assets as *vector stroke data* (ordered recipes,
   never rasters), engine and weathering unchanged.
3. **Pivot** — flat-silhouette art direction; all game systems survive.

Also fold in issue #6's hallway test: does someone unfamiliar call the carp
a fish without prompting?

**Record the verdict as `docs/adr/0001-charm-gate-verdict.md`** (decision,
who saw it, reactions, chosen ladder rung), then close #8 and #6's open
hallway item.

Pending device checks that ride along with the verdict: 60 fps on a real
iPhone for the paper (#1) and rain-bleed (#4) scenes.
