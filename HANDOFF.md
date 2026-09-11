# HANDOFF.md — continuation brief (next session)

**Read this first in a new context window.** Lives at the dotfiles root;
`AGENTS.md` there orders every session to read it. Paths in section 2 are
relative to `harness/`. Updated 2026-09-11 (skill split, stow package,
microphone move); restructured 2026-09-03 into `dsh/`, `pi/`, `sync/`,
`docs/`.

---

## 0. Next machine: woodlawn (first session there, week of 2026-09-15)

linden commits `ce6beb3` + `bb7e359` changed the layout. After `git pull`:

1. `stow -d ~/dotfiles/harness -t ~/.pi/agent pi` — links pi skills and
   `unslop.ts` into `~/.pi/agent/`.
2. `npm run skills:install` in `harness/` — refreshes `~/.dsh/skills/`
   from the new `dsh/skills/`.
3. Delete sdlc-loop leftovers: `rm -rf ~/.agents/skills/sdlc-loop*
   ~/.pi/agent/extensions/sdlc-loop.ts`; remove `~/.agents` if empty.
4. Whisper: the pull leaves untracked artifacts in the old
   `harness/pi/speech-to-text/` (`target/`, `ggml-base.bin`, logs). Move
   them into `microphone/rust-whisper-server/`, then `rm -rf
   harness/pi/speech-to-text`.
5. Repoint the service: `sed -i 's|harness/pi/speech-to-text|microphone|g'
   ~/.config/systemd/user/rust-whisper-server.service && systemctl --user
   daemon-reload && systemctl --user restart rust-whisper-server`. Verify
   with `curl -s localhost:10301/health`. If startup fails, the old
   `target/` carries baked-in paths: clean rebuild per
   `microphone/rust-whisper-server/SETUP.md`.
6. Delete this section once all five steps check out on woodlawn.

---

## 1. What this project is

`ai-harness` is the deployment config for **two agent harnesses** on two
machines (woodlawn, linden) that swap weekly:

- **dsh** (DeepSeek Harness) with the Kimi Code integration: Kimi CLI as a
  subagent (`subagent_kimi`) via ACP, Kimi K3 (1M context) on the user's
  subscription as the main model, NVIDIA free-tier model profile.
- **pi**, with voice input via the official `pi-voice-stt` npm extension
  (records with ffmpeg) and a local whisper speech-to-text server (Rust +
  whisper-rs, `ggml-base.bin`, OpenAI-compatible endpoint on `0.0.0.0:10301`)
  as the transcription backend. Client install: `pi install npm:pi-voice-stt`
  plus `sudo apt install ffmpeg`.
- Poteto's pstack-strict skills (30) vendored twice, once per harness:
  `pi/skills/` (stowed to `~/.pi/agent/skills/`) and `dsh/skills/` (copied
  to `~/.dsh/skills/` via `npm run skills:install`). The two sets are
  independent and may diverge.

## 2. Repo layout (post-2026-09-03)

| Path | Purpose |
|---|---|
| `dsh/scripts/` | `setup-kimi.mjs` (idempotent full dsh config), `kimi-login.mjs` (subscription login, recommended auth path), `bridge-kimi-token.mjs` (fallback, shared lineage), `install-skills.mjs`, `import-skills.mjs`, `lib.mjs` |
| `dsh/vendor/` | Pinned tarballs: `@deepseek-ai/dsh-subagent-acp@0.1.1-rc.2`, `@agentclientprotocol/sdk@0.25.1` |
| `dsh/docs/` | `SETUP.md`, `KIMI-INTEGRATION.md`, `MODIFYING-DSH.md`, `ORCHESTRATION.md` |
| `../microphone/rust-whisper-server/` | Whisper server source + SETUP.md; model, `target/`, logs are gitignored |
| `../microphone/pi-voice-stt-setup.md` | Client extension install (npm package, ffmpeg, stt.json, keybinds) |
| `pi/skills/` + `pi/extensions/` | pi stow package: `stow -d ~/dotfiles/harness -t ~/.pi/agent pi` links them into `~/.pi/agent/` |
| `dsh/skills/` | dsh's own skill set (pstack-strict), installed per machine by `npm run skills:install` |
| `sync/` | `README.md` (fresh-machine runbook + weekly swap + parity checks), `MACHINES.md` (per-machine facts) |
| `docs/` | `POTETO-SKILLS-WORKFLOW.md` (harness-agnostic) |

npm scripts: dsh ones carry a `dsh:` prefix (`npm run dsh:setup`,
`npm run dsh:kimi-login`, `npm run dsh:bridge[:verify]`). Skills scripts stay
unprefixed (`npm run skills:install`, `skills:import`).

## 3. Current live state

(linden, updated 2026-09-11)

- dsh `0.1.1-rc.2`, web profile at `~/.dsh/profiles/web`; GUI on
  `127.0.0.1:3080`.
- `~/.dsh/settings.yaml`: `agent-default-model: {provider: kimi-coding,
  model: k3}`; kimi-coding + NVIDIA provider profiles.
- `~/.dsh/.credentials.yaml`: independent subscription credential
  (`llm-pi-ai/kimi-coding`, kind grant), verified working.
- `~/.dsh/skills/`: 30 skills installed (pstack-strict set).
- Kimi CLI `0.38.0` at `~/.kimi-code/bin/kimi`; CLI login was DEAD as of
  2026-08-28 (shared-lineage incident), re-auth is a user action.
- **rust-whisper-server**: systemd user service, active, port 10301, unit at
  `~/.config/systemd/user/rust-whisper-server.service`, updated 2026-09-03
  for the `pi/` move and verified healthy after restart.
- **pi-voice-stt** (client extension, linden, 2026-09-08): official npm
  package `pi-voice-stt` 0.7.0 installed via `pi install`, ffmpeg 8.0.1
  installed, config at `~/.pi/agent/stt.json` with provider type `local`
  pointing at the whisper server. The earlier hand-written extension of the
  same name was removed. See `../microphone/pi-voice-stt-setup.md`.

**linden (2026-09-11):**

- Repo checkout at `~/dotfiles/harness` (`~/.dotfiles` retired everywhere).
- **rust-whisper-server**: fixed after the repo move. The unit still pointed
  at `~/.dotfiles/...` (crash-loop, exit `status 209/STDOUT`, 789 cycles)
  and `ggml-base.bin` had not survived the move (panic on startup). Paths
  corrected, model re-downloaded (sha256 verified), end-to-end test passes
  (`/health` OK, ffmpeg record → transcription JSON). Incident + verification
  checklist in the whisper SETUP.md.

## 4. Pending / next steps

1. **Set up linden** (arrives week of 2026-09-08): follow `sync/README.md`
   (fresh machine section). Whisper server (fixed 2026-09-11) and
   pi-voice-stt are done; Kimi CLI re-auth and `set_n_threads()` tuning are
   still open.
2. **Fill in `sync/MACHINES.md`** for linden once the hardware is known.
3. **Re-auth the Kimi CLI** (`kimi login`, user action) for `subagent_kimi`.
4. **Try pstack for real** on a user project: *"use poteto-mode: <task>"*.
   See `docs/POTETO-SKILLS-WORKFLOW.md`.
5. **woodlawn repo move**: retire `~/.dotfiles` — re-clone the checkout to
   `~/dotfiles`, update the whisper unit paths (`sed
   's|/home/phage/\.dotfiles/|/home/phage/dotfiles/|g'` on
   `~/.config/systemd/user/rust-whisper-server.service`), `daemon-reload`,
   restart, and run the post-move verification in the whisper SETUP.md.

## 5. Known issues / caveats

- **Patch syntax**: new rows in `cordis.patch.yml` must use `- insert:`
  blocks; bare `- id:` rows silently don't mount.
- **Settings → Models shows an API-key field for `kimi-coding`**: leave it
  empty; the OAuth credential is what's used.
- **Pstack came from poteto's Noodle ecosystem**: Noodle is not installed;
  playbooks naming missing skills (`swarm`, `recall`) are adapted inline
  (see `docs/POTETO-SKILLS-WORKFLOW.md` § 4).
- **`poteto-mode` is user-invocable only** (`disable-model-invocation`).
- **Whisper input format**: WAV, 16 kHz, mono; the server does not resample.
- **Whisper down after a repo move**: crash-loop `status 209/STDOUT` = stale
  unit paths; panic on `ggml-base.bin` = model lost. Both faults and the
  verification checklist are in the whisper SETUP.md incident section.
- **Sandbox facts for the agent**: bash runs in a bubblewrap sandbox;
  `/tmp` is wiped per call, `~/.dsh` is read-only without
  `sandbox_permissions: danger-full-access`, host processes are not visible,
  and `git push` needs
  `GIT_SSH_COMMAND="ssh -F /dev/null -o StrictHostKeyChecking=accept-new -i $HOME/.ssh/id_ed25519"`.

## 6. Cheat sheet

```bash
npm run dsh:setup            # full dsh config, idempotent
npm run dsh:setup:dry        # preview
npm run dsh:kimi-login       # subscription credential, per machine
npm run dsh:bridge[:verify]  # fallback: import CLI token
npm run skills:install       # repo skills → ~/.dsh/skills
dsh --profile web --dump-config | grep -A6 subagent-kimi   # dsh parity check
systemctl --user status rust-whisper-server                # whisper status
curl localhost:10301/health                                # whisper parity check
pi install npm:pi-voice-stt                                # voice client install
/stt status                                                # voice client status in pi
```

---

*Next session: read `sync/README.md` and `docs/POTETO-SKILLS-WORKFLOW.md`.*
