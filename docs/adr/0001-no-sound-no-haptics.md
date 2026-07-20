# ADR 0001: No sound, no haptics — Ssak is silent and still by design

- **Date:** 2026-07-20
- **Status:** Accepted
- **Decided by:** Michael Ju

## Context

Ssak is a cozy, calm game: raise one flower at a time on the real clock. Its
predecessor **Meok** bet heavily on sensory feedback — a haptic "bite" for
fishing, procedural audio. Ssak starts fresh and needs its own record of the
sensory decision, since the redesign spec and the UI plan both cite it as a hard
guardrail.

## Decision

**Ssak ships with no sound and no haptics.** No audio engine, no `CoreHaptics`,
no `UIFeedbackGenerator`. The game is silent and still; calm comes from the
visual layer alone.

The only sensory levers are visual: layout, color, type, motion (all gated by
`Reduce Motion`), and Liquid Glass. Accessibility is served by VoiceOver labels
(screen-reader metadata) — not by any sound the app itself produces.

## Consequences

- No settings toggle for sound or haptics; there is nothing to toggle.
- The redesign spec (§0) and the UI redesign plan cite this ADR as the authority
  for the "no sound, no haptics" guardrail.
- Retires, for Ssak, the Meok-era ADRs (0001 charm-gate art verdict, 0002 drop
  haptics), which described a different game. Meok's full history — including
  those decision records — remains under the `meok-archive` git tag.
