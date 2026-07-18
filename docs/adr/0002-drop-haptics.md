# ADR 0002: Drop haptics — the bobber's tremble is the bite signature

- **Date:** 2026-07-19
- **Status:** Accepted
- **Decided by:** Michael Ju

## Context

The spec pinned haptics as fishing's core sensory bet: "the phone is the rod;
mastery is haptic literacy" (§2 Fishing mechanics), with a synchronized visual
+ audio cue built as an *accessibility mirror* for players who disable
haptics. M2 shipped this as one `BiteTap` envelope driving three mirrors —
CoreHaptics pattern, bobber tremble, procedural audio — plus a planned
"haptics/audio toggle" in M3 settings.

Haptics can't be felt in the Simulator (untestable in the dev loop) and were
never verified on device. Michael decided against the channel.

## Decision

**Remove the haptic channel entirely.** The on-screen bobber tremble becomes
the *primary* bite signature; procedural audio is the secondary mirror. What
was the accessibility fallback is now the main event — no sense is privileged
that some players (or a phone on a table) can't perceive.

The `BiteTap` envelope stays the single source of truth: `sharpness` now shapes
the audio's pitch and the tremble's snap-depth instead of a haptic parameter.
Each species still reads apart by how its float dips.

## Consequences

- Fishing's framing shifts from "haptic literacy" to **reading the bobber** —
  the tremble amplitude/rhythm is now legible enough to carry species identity
  (dip scales with intensity × sharpness).
- `CoreHaptics` and its engine are gone from `BiteFeedback` (now audio-only);
  `Meok/Fishing/BiteFeedback.swift`, `FishingScene.playTremble/shake`, and the
  kernel `BiteTap` doc are updated. No kernel logic or tests changed.
- M3's settings "haptics/audio toggle" collapses to an **audio toggle** (+
  accessibility options). One fewer switch.
- Supersedes, on this point only: spec §2 "Fishing mechanics" (haptic
  signatures / fight "sharp haptic"), §2 "Audio & haptics", and the §4 settings
  "haptics toggle." The spec prose still reads "haptic" in places; this ADR is
  the authority where they conflict.
