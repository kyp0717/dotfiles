---
name: sdlc-loop-step-02-build
description: Step 2 of the SDLC loop. Build the new feature or change the existing one so the code matches the map entry from step 1. Use after the map entry exists and before building the driver.
---

# Step 2: build

The code follows the map. The map entry from step 1 says what the feature
does and what proves it. Build to that.

## Discipline

Build to the `Type:` line from the map. Behavior and surface build
differently.

### Behavior

- The logic runs without the screen. Anything the driver must check must be
  reachable from a command line or a test. If a choice is tangled into UI or
  IO code, pull the choice into a function that takes plain values and
  returns one result, and let the surrounding code act on the answer. This
  is the only structural rule for behavior.

### Surface

- The rendered state must be reachable in a snapshot or screenshot: a window
  that opens, a panel that lays out, a grid that renders, a font at a named
  size. Render the widget without a live data feed so the state is
  deterministic.

### Both

- No comments. Do not write comments in code: names and structure carry
  the explanation, and the feature map carries the why. A real constraint
  is encoded in a type, a test, or a check, never a comment.
- Match the proof predicate exactly. The map says what evidence counts. If
  the map promises a journal row with a specific reason string, the code
  writes exactly that string. If it promises a visible state, the widget
  renders exactly that state.
- Changed features: change only where the updated predicate says. Everything
  else stays identical so the baseline comparison in step 4 is clean.
- Removed features: delete the code, delete its callers, leave no flags or
  dead branches behind.

## Anti-patterns

- Building first and writing the map after. The map is the spec, not the
  documentation of what happened.
- Improving neighboring code while you are in the file. A clean diff is what
  makes step 4 mean something.
