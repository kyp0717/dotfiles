import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Companion to npm:pi-session-move (pinned in scripts/pi.requirements.txt):
// that package registers /move; this repo-local extension aliases
// /move-session -> /move by rewriting input before pi parses slash commands.
// Deployed by `stow pi`; pi.install.sh warns when this file is missing.
// Keeps the original /move command too.
export default function (pi: ExtensionAPI) {
  pi.on("input", async (event) => {
    const match = event.text.match(/^\/move-session(?=[\s]|$)/);
    if (!match) return { action: "continue" };
    return {
      action: "transform",
      text: event.text.replace(match[0], "/move"),
      images: event.images,
    };
  });
}
