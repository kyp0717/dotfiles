---
name: sdlc-loop-step-01-map
description: Step 1 of the SDLC loop. Build the feature map, add a new feature entry with its proof predicate, or update an existing entry when the feature changes. Use when starting any feature work or when the map is missing.
---

# Step 1: map

The map is the contract. Everything later reads from it. It lives in the repo
at `resource/features/` (ls-trader) or wherever the repo keeps it: one index
`README.md` plus one file per feature, sorted by type into `behavior/` and
`surface/` folders.

## When this step runs

- **No map yet.** Build it. Top 3-5 load-bearing features first. Find them
  from menus, commands, modes, and docs, not from code structure.
- **New feature.** Add its entry before writing code. The proof predicate is
  the spec.
- **Changed feature.** Update the entry's proof predicate to the intended new
  behavior. Record the old predicate as the baseline.
- **Removed feature.** Delete the entry.

## Classify first

Ask what the feature is before writing the entry. The answer drives the
proof predicate, the driver, and every step after.

- **Behavior.** The proof is data: a journal row, a CSV row, a log line, a
  decision. The `Type:` line reads `Behavior`.
- **Surface.** The proof is rendered state: a banner, a color, a marker, a
  window, a font. The `Type:` line reads `Surface`.

A capability that spans both is split into two entries: the metric is
behavior, the grid that renders the metric is surface. One `Type:` per entry.
The folder matches the type: `behavior/` for behavior entries, `surface/` for
surface entries.

## Per-feature file format

Title, an `ID:` line naming the feature, a `Type:` line naming Behavior or
Surface, one paragraph on the user-visible behavior, then exactly these H2
sections in order:

1. `Sub-features` — short IDs, one line each, unique across the map.
2. `How to get to it (user POV)` — every user entry point.
3. `Driving it with <harness>` — `Preconditions:` then labeled bullets pairing
   each user action with the exact command and the observable result.
4. `Gotchas` — traps that waste or invalidate a run.
5. `Anchors` — the code that proves the feature exists, one bullet per anchor
   as `- <path>: <needle>`. The audit greps each path for its needle.

Keep implementation detail out of the first four sections. Name only user
paths, stable handles, required state, commands, and observable proof. The
Anchors section is the one place code detail belongs.

## The index

`README.md` holds baseline preconditions, driving conventions, proof and skip
reporting, and the feature list linking every file.

## Rules

- Classify first. The `Type:` line names Behavior or Surface, and it drives
  the proof predicate and the driver. Behavior proof is a data row, driven
  by the CLI loop. Surface proof is rendered state, driven by the UI loop.
- A surface entry links to the behavior parts it renders or controls with
  `renders <id>` or `feeds <id>`. A behavior driver that calls a gate or
  pipeline in another feature links with `consults <id>` or `consumes <id>`.
  The audit fails if a link target is not defined anywhere.
- The proof predicate must name evidence: a row, a line, a visible state.
  Never "works".
- Record the feature ID and entry point with every verification artifact.
