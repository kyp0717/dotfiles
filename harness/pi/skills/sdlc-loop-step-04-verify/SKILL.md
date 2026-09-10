---
name: sdlc-loop-step-04-verify
description: Step 4 of the SDLC loop. Verify the feature against the map's proof predicate in three layers. Unit tests, live evidence through the driver, perf where speed matters. Evidence over self-report, honest verdicts. Use after building the driver in step 3.
---

# Step 4: verify

Tests alone are not sufficient verification. A feature is verified only when
every applicable layer passes.

## The three layers

1. **Unit.** The feature's logic gets tests in the repo's test suite.
   Boundary cases included.
2. **Live.** Run the driver from step 3 against the real artifact. Inspect
   the evidence directly: the journal row, the CSV row, the rendered frame.
   Check it against the proof predicate in the map entry.
3. **Perf.** Only where speed matters. Measure the new code against the
   baseline and name the number that fails. Skip this layer where speed does
   not matter.

## Verdict discipline

Every check ends in one of three verdicts: VERIFIED, NOT VERIFIED, or
INCONCLUSIVE. Inconclusive is not a pass. Report it and say what was missing.

## Evidence rules

- The `Type:` line names the artifact to inspect. Behavior: the data row.
  Surface: the rendered frame. Inspect the one the entry promises, not the
  other.
- Inspect the artifact, never a self-report. A log line saying "passed" that
  the code printed about itself is not evidence.
- If a check passes too easily, suspect the check before the code. A blank
  screenshot proves nothing about a panel.
- For changed features, run the same input through before and after. The
  delta must match the intended change and nothing else.
- Keep the verdict and the evidence path with the work. A reviewer re-runs
  the driver rather than trusting the claim.
