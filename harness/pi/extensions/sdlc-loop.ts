import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const REMINDER =
  "SDLC loop: feature work follows map, build, driver, verify, audit last. " +
  "The feature map is the contract. First ask behavior or surface. Behavior " +
  "drives via CLI, surface via snapshot or screenshot. Skills: sdlc-loop, " +
  "sdlc-loop-step-01-map through sdlc-loop-step-05-audit.";

const LOOP_TEXT = `SDLC loop

First: behavior or surface? Behavior proof is a data row, surface proof is
rendered state. The Type: line records it and drives every step.

1. Map. The feature map entry is the spec. Add, update, or delete it first.
2. Build. Code matches the map. Behavior runs without the screen, surface
   renders without a live feed.
3. Driver. CLI subcommand for behavior, snapshot or screenshot for surface.
4. Verify. Unit, live evidence, perf where speed matters. VERIFIED, NOT VERIFIED, or INCONCLUSIVE.
5. Audit. Once, at the end. The gate script checks map against code.

Skills: sdlc-loop, sdlc-loop-step-01-map, sdlc-loop-step-02-build,
sdlc-loop-step-03-driver, sdlc-loop-step-04-verify, sdlc-loop-step-05-audit.`;

export default function (pi: ExtensionAPI) {
  // Inject the reminder once per session, not every turn.
  let reminded = false;
  pi.on("before_agent_start", async (_event, _ctx) => {
    if (reminded) return {};
    reminded = true;
    return {
      message: {
        customType: "sdlc-loop",
        content: REMINDER,
        display: false,
      },
    };
  });

  pi.registerCommand("sdlc-loop", {
    description: "Print the SDLC loop",
    handler: async (_args, ctx) => {
      ctx.ui.notify(LOOP_TEXT, "info");
    },
  });
}
