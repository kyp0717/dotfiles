import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { uptime } from "node:os";
import { promisify } from "node:util";

const execFileP = promisify(execFile);

// Blue Yeti (Logitech 046d:0ab7). Change here if the mic changes.
const USB_VID = "046d";
const USB_PID = "0ab7";

// Installed system-wide, passwordless via /etc/sudoers.d/yeti-usb-reset.
// See microphone/yeti-usb-reset.md in the dotfiles repo.
const RESET_SCRIPT = "/usr/local/sbin/yeti-usb-reset";

const POLL_MS = 30_000;
// If wall clock advanced this much more than uptime since the last poll,
// the machine was asleep in between.
const SUSPEND_GAP_S = 5;

function findMic(): string[] {
  const base = "/sys/bus/usb/devices";
  const found: string[] = [];
  let entries: string[] = [];
  try {
    entries = readdirSync(base);
  } catch {
    return found;
  }
  for (const entry of entries) {
    const vidPath = `${base}/${entry}/idVendor`;
    const pidPath = `${base}/${entry}/idProduct`;
    if (!existsSync(vidPath) || !existsSync(pidPath)) continue;
    try {
      if (
        readFileSync(vidPath, "utf8").trim() === USB_VID &&
        readFileSync(pidPath, "utf8").trim() === USB_PID
      ) {
        found.push(entry);
      }
    } catch {
      // device vanished mid-scan, skip
    }
  }
  return found;
}

async function tryCmd(cmd: string, args: string[], timeoutMs: number): Promise<boolean> {
  try {
    await execFileP(cmd, args, { timeout: timeoutMs });
    return true;
  } catch {
    return false;
  }
}

export default function (pi: ExtensionAPI) {
  let timer: ReturnType<typeof setInterval> | undefined;
  let lastWall = Date.now();
  let lastUp = uptime();

  const stop = () => {
    if (timer) clearInterval(timer);
    timer = undefined;
  };

  async function resetMic(ctx: { ui: { notify: (m: string, k: "info" | "warning" | "error") => void } }) {
    const devices = findMic();
    if (devices.length === 0) return; // no Yeti on this machine
    if (await tryCmd("sudo", ["-n", RESET_SCRIPT], 15_000)) {
      ctx.ui.notify("USB mic reset after sleep", "info");
      return;
    }
    // No passwordless sudo rule: ask via polkit (GUI prompt on GNOME).
    if (await tryCmd("pkexec", [RESET_SCRIPT], 120_000)) {
      ctx.ui.notify("USB mic reset after sleep (pkexec)", "info");
      return;
    }
    ctx.ui.notify(
      `Mic reset needs root. Install the helper: see microphone/yeti-usb-reset.md (sudo -n ${RESET_SCRIPT})`,
      "warning",
    );
  }

  pi.on("session_start", (_event, ctx) => {
    stop();
    lastWall = Date.now();
    lastUp = uptime();
    timer = setInterval(() => {
      const now = Date.now();
      const up = uptime();
      const gap = (now - lastWall) / 1000 - (up - lastUp);
      lastWall = now;
      lastUp = up;
      if (gap > SUSPEND_GAP_S) void resetMic(ctx);
    }, POLL_MS);
  });

  pi.on("session_shutdown", () => stop());

  pi.registerCommand("mic-reset", {
    description: "Reset the USB Blue Yeti (software replug, fixes dead mic after sleep)",
    handler: async (_args, ctx) => {
      if (findMic().length === 0) {
        ctx.ui.notify("Blue Yeti (046d:0ab7) not found on this machine", "warning");
        return;
      }
      await resetMic(ctx);
    },
  });
}
