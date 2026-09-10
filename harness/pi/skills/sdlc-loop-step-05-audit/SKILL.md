---
name: sdlc-loop-step-05-audit
description: Step 5 of the SDLC loop. Audit that the feature map still matches the code. Runs once at the end of an effort, never inside the loop. Use after verification passes, or when asked whether the map is complete.
---

# Step 5: audit

The audit closes the loop. It runs once at the end of an effort, after
verification passes. It never runs per iteration and never at the beginning.
Completeness only has meaning once the work is done.

## What it checks

Run the gate script `scripts/audit-features.sh` in this skill's directory
against the repo's map directory:

```bash
./scripts/audit-features.sh <features-dir>
```

It checks, per feature file: the `ID:` line names the feature, the `Type:`
line names Behavior or Surface, the required sections exist in order, the
Anchors section exists, and every anchor's needle still greps in its file. It
checks the index links every feature file, that every sub-feature ID is
defined in exactly one file, and that every `renders` / `feeds` / `consults`
/ `consumes` link resolves to a defined sub-feature ID. It walks type folders
(`behavior/`, `surface/`) when present. Failure output names the file and the
missing piece.

## Resolving failures

- An anchor no longer greps: the code moved or the feature was removed.
  Update the anchor, or delete the map entry if the feature is gone.
- A code entry point has no map entry: map it, or add the pattern to the
  repo's known-internal list.
- A section is missing: fix the map file, not the script.

## Rules

- The gate script is the enforcement. Do not do the audit by eye.
- The repo wires the script into its own check command so the audit can fail
  a build. In ls-trader that is `cargo run -p tools -- check`.
- The reverse direction, code entry points with no map entry, needs the repo's
  own inventory patterns. Extend the repo's check command with them. The
  generic script checks anchors and structure only.
