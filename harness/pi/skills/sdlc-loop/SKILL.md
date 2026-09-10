---
name: sdlc-loop
description: The software development life cycle loop for feature work. Five steps, two feature types: behavior or surface. Map first, build, driver, verify, audit last. Use whenever adding, changing, or removing a feature in any repo.
---

# SDLC loop

One loop for all feature work. Add, change, and remove all follow the same
five steps. The map is the contract. The driver is picked by type.

## The loop

1. **Map.** New feature gets a new entry with its proof predicate. Changed
   feature gets an updated predicate. Removed feature gets its entry deleted.
   Step skill: `sdlc-loop-step-01-map`.
2. **Build.** Write or change the code to match the map. Behavior runs
   without the screen, surface renders without a live feed. Step skill:
   `sdlc-loop-step-02-build`.
3. **Driver.** Build or update the command that exercises the feature and
   prints evidence. Behavior: a CLI subcommand. Surface: a headless
   snapshot or a live screenshot. Step skill: `sdlc-loop-step-03-driver`.
4. **Verify.** Unit tests, live evidence, perf where speed matters. Evidence
   over self-report. Honest verdicts: VERIFIED, NOT VERIFIED, INCONCLUSIVE.
   Step skill: `sdlc-loop-step-04-verify`.
5. **Audit.** Once, at the end of the effort, never inside the loop. The gate
   checks the map still matches the code. Step skill:
   `sdlc-loop-step-05-audit`.

## First question: behavior or surface

Before step 1, ask what the feature is. The answer drives every step that
follows.

- **Behavior.** The feature's proof is data: a journal row, a CSV row, a log
  line, a decision. It runs without the screen. The driver is a CLI
  subcommand in the repo's tooling.
- **Surface.** The feature's proof is rendered state: a banner, a color, a
  marker, a window, a font. The driver is a snapshot harness or a screenshot
  of the live app.

A capability can span both. Split it: the metric is behavior, the grid that
renders the metric is surface. Each side gets its own entry with its own
`Type:` line. The map stays one map.

## The map contract

The map lives in the repo, one index plus one file per feature. Each feature
file has a title, a `Type:` line naming Behavior or Surface, one paragraph on
the user-visible behavior, four H2 sections in order (`Sub-features`,
`How to get to it (user POV)`, `Driving it with <harness>`, `Gotchas`), and
an `## Anchors` section listing the code that proves the feature exists. Step skill
`sdlc-loop-step-01-map` has the full format.

## Rules

- Map first. Always. Code follows the map, never the reverse.
- Driver before change. A changed feature needs a recorded baseline.
- The audit is the last step. It is not part of the loop.
- Everything lands in git. The map and the drivers travel with the repo.
