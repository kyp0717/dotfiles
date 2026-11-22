# 2026-11-22 — pi-acp-agents extension: installed via git pin, two per-machine steps

## What

Added the pi-acp-agents extension (ACP client: spawn Gemini CLI / other
ACP agents as sub-agent tools inside pi) to pi.

## Repo state (portable, committed)

- `pi/.pi/agent/settings.json` packages gained:
  `git:github.com/buihongduc132/pi-acp-agents@1d3ba9aa9b5a89d37943a5c39fbad4f17268c619`
  (main HEAD, v0.5.1). The npm release (0.3.0, latest) is uninstallable:
  its tarball depends on `pi-acp-types: "workspace:*"`. Tag v0.5.0 has the
  same bug; the fix is only on main, untagged, hence the commit-hash pin.

## Per-machine steps (woodlawn done unless noted; linden must repeat)

1. `pi install git:github.com/buihongduc132/pi-acp-agents@1d3ba9aa9b5a89d37943a5c39fbad4f17268c619`
2. zod patch (upstream bug: `src/tui/persona-resolver.ts` imports
   `zod/v4`, zod is in no manifest; it resolves only via pnpm hoisting
   in the author's monorepo):
   `cd ~/.pi/agent/git/github.com/buihongduc132/pi-acp-agents && npm install zod@^4 --no-save --no-audit --no-fund`
   Safe because the pin is a commit hash: pi does not refetch/reset
   commit-hash refs, so the extra node_modules entry persists.
   Verify: `pi --help` 2>&1 shows no "Cannot find module 'zod/v4'".
3. Install Gemini CLI (default ACP agent) and authenticate:
   `npm install -g @google/gemini-cli`, then `gemini` once to log in
   with the Google account. Verified via web research (2026-11-22):
   a consumer Google AI Pro monthly subscription authenticates Gemini
   CLI at 1,500 requests/user/day (Ultra: 2,000), and `gemini --acp` is
   an officially supported protocol, so the pi-acp-agents path rides
   the existing subscription with no API key or extra cost. NOT done
   on woodlawn yet.
   Optional config at `~/.pi/acp-agents/config.json` (see the extension
   README quick start).

## Open

- gemini CLI install: DONE on woodlawn (0.70.0). Auth: user pivoted
  to the OAuth extension below instead of the API key.
- NEW (2026-11-22 evening): `npm:@justjoshn/pi-google-oauth-v2@0.1.7`
  installed and pinned (settings.json + pi.requirements.txt). Routes pi
  requests against the Google AI Pro consumer quota via OAuth, no API
  key. USER STEPS in the pi TUI: `/login` (browser OAuth with the
  Google AI Pro account), then `/model` to pick a google-oauth-v2 model
  (e.g. gemini-4-argon, gemini-3.8-flash).
- API-key finding: the AI Studio key the user provided (AQ.-prefixed)
  is VALID but the account is flagged new-user: gemini-2.5-flash and
  gemini-2.5-pro return 404 "no longer available to new users". So the
  ACP/gemini-cli path must NOT use 2.5 defaults: set
  `~/.pi/acp-agents/config.json` default_model to gemini-3.8-flash (or
  another listed model) and, if the CLI router still fails, set `model`
  in ~/.gemini/settings.json. Key was pasted in chat; rotate it if that
  matters.
- Upstream: npm tarball workspace:* dep and missing zod dep are unfixed
  as of 2026-11-22; if a v0.5.2+ releases on npm with both fixed, switch
  the pin to `npm:pi-acp-agents@<version>`.
