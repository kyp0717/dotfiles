---
name: sdlc-loop-step-03-driver
description: Step 3 of the SDLC loop. Build the driver that exercises the feature and prints evidence. CLI subcommand for behavior features, snapshot harness or screenshot for surface features. Use after the code from step 2 exists.
---

# Step 3: driver

The driver runs the feature without a human at the keyboard and prints the
evidence the map entry names. The `Type:` line picks the driver: behavior
gets a CLI driver, surface gets a snapshot or screenshot driver.

## Behavior: CLI driver

Add a subcommand to the repo's tooling CLI. It exercises the feature on
recorded or synthetic inputs and prints the resulting evidence: the journal
rows, the CSV rows, the decisions. Requirements:

- Deterministic. Same input, same output.
- Prints evidence, not verdicts. Verdicts are step 4.
- Re-runnable by anyone. The command is the artifact a reviewer runs.
- For changed features, the driver can replay the same input against the old
  behavior so step 4 can compare before and after.

## Surface: snapshot or screenshot driver

A CLI command cannot check what a panel looks like. For rendered state:

- Prefer a headless snapshot harness that renders the widget tree to an image
  without a window, if the UI framework has one. Deterministic.
- Otherwise drive the live app in a known state and capture a screenshot.
  This proves the real artifact but needs the app runnable.

## Rules

- The driver exists before the feature change is trusted. For a changed
  feature, record the baseline output first.
- One command, one feature. Do not build a framework.
- The map entry's Driving section names this command. If the command and the
  map disagree, the map is stale and the audit will catch it.
