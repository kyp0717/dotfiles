# SETUP.md — Set up one machine (Kimi Code + dsh parity)

This is the per-machine procedure. Run it on **both** computers so they end up
with the same harness configuration. It is written so that running it a second
time on the same machine is a no-op (the script is idempotent).

> Time: ~10 minutes the first time, ~1 minute on re-runs.

---

## 0. Prerequisites

| Requirement | Check | Notes |
|---|---|---|
| Node.js ≥ 18 | `node --version` | dsh requires it |
| `tar` (POSIX) | `tar --version` | used to unpack the vendored packages |
| Kimi Code CLI | `kimi --version` | install from <https://github.com/MoonshotAI/kimi-code>; the installer puts it at `~/.kimi-code/bin/kimi` |
| Kimi login | `kimi login` | one-time, per machine — the OAuth/credentials live under `~/.kimi-code/` and are **machine-local** |
| dsh harness | `dsh --version` | launch it once (`dsh web`) so the `web` profile initializes, then stop it |

## 1. Pin the same harness version on both machines

The integration is version-matched: the ACP bridge version must equal the
harness version. **This machine's harness is `0.1.1-rc.2`.** On the second
machine, launch dsh with the same pinned version:

```bash
npx --yes @deepseek-ai/dsh@0.1.1-rc.2 --profile web        # first boot (initializes the profile)
# afterwards, launch the GUI the same way you do here (or use a pinned alias).
```

The setup script detects the harness version and installs the matching bridge;
it fails loudly if that bridge version does not exist on npm.

## 2. Get the repo and run the setup

```bash
git clone git@github.com:kyp0717/ai-harness.git && cd ai-harness

npm run dsh:setup:dry    # optional: preview what it will do (writes nothing)
npm run dsh:setup        # apply
```

What it does (see the header of `dsh/scripts/setup-kimi.mjs` for the full map):

1. Locates the Kimi CLI binary.
2. Locates the dsh install and reads its version.
3. Installs `@deepseek-ai/dsh-subagent-acp@<harness-version>` and
   `@agentclientprotocol/sdk@0.25.1` into `~/.dsh/profiles/node_modules`
   (from the pinned `dsh/vendor/` tarballs; falls back to the npm registry).
4. Patches `~/.dsh/profiles/web/cordis.patch.yml`:
   - inserts the `kimi` ACP provider row (loader `- insert:` form), and
   - sets the default agent preset to `kimi`.
5. Creates `~/.dsh/.agent-presets/kimi/agent.cordis.yml` — the shipped
   `standard` preset plus the `subagent_kimi` tool row.
6. Writes `~/.dsh/settings.yaml` (idempotently, preserving other keys):
   - `agent-default-model: {provider: kimi-coding, model: k3}` (the 1M-context
     Kimi K3), and
   - the `llm-pi-ai.providers.kimi-coding` provider profile.
7. Verifies the bridge imports from the profile's module resolution path.

After `npm run dsh:setup`, the machine's harness *configuration* is identical to
the known-good one; the only per-machine step left is the subscription
credential (`npm run dsh:kimi-login`).

## 3. Restart and verify

```bash
# stop the running GUI, then start it again
dsh web
```

In the GUI:

1. Start a **new** session (it uses the `kimi` preset by default).
2. Open the tool catalog — confirm `subagent_kimi` is listed.
3. Ask the agent to delegate: *"delegate this task to the kimi subagent."*
   Watch for a `kimi` process spawning (default model `kimi-code/k3-256k`).

Optional CLI verification (shows the composed tree contains the provider row):

```bash
dsh --profile web --dump-config | grep -A6 "subagent-kimi"
```

## Per-machine items (never committed, set once per machine)

These intentionally differ per machine and are **not** part of the repo:

- **Kimi credentials** — `~/.kimi-code/` (OAuth tokens, config.toml, sessions).
- **API keys for using Kimi via the *API*** (pay-as-you-go) — in the harness
  GUI: Settings → API keys → `MOONSHOT_API_KEY` (provider `moonshotai`) or
  `KIMI_API_KEY` (provider `kimi-coding`).
- **Your Kimi *subscription*** (no API key) — see the next section.
- **User-root skills** — `~/.dsh/skills/` mirrors the repo's `.agents/skills/`;
  install per machine with `npm run skills:install` (idempotent).

## 4. Use your Kimi Code subscription as the main model (no API key)

The harness's `kimi-coding` provider can authenticate with the **same
subscription account the CLI uses** ("Sign in with Kimi Code" OAuth), but this
dsh build has no GUI button or command that starts that flow. Two supported
ways to give the harness the subscription credential:

### 4a. Recommended: independent harness login (`npm run dsh:kimi-login`)

Runs the device-code flow directly and stores the credential in the harness
store under `llm-pi-ai/kimi-coding`. **The harness gets its OWN token lineage,
so its background refreshes can never invalidate your CLI's login.**

```bash
npm run dsh:kimi-login
# prints a URL + code → open the URL, sign in with your subscription account, enter the code
```

### 4b. Alternative: bridge the CLI's token (`npm run dsh:bridge`)

Imports the OAuth tokens your CLI already holds (from `kimi login`) into the
harness store. ⚠️ **The harness and CLI then SHARE one token lineage** — the
harness refreshing autonomously can invalidate your CLI's login, and vice
versa (this is exactly what caused the "OAuth refresh failed … invalid grant"
error; see troubleshooting below). Prefer 4a.

```bash
kimi login            # once per machine
npm run dsh:bridge        # imports + validates the CLI token
npm run dsh:bridge:verify # optional: make one small request to prove it works
```

Verified properties (both paths):

- The harness record written is `llm-pi-ai/kimi-coding` (kind `grant`) in
  `~/.dsh/.credentials.yaml`; existing entries (`refs`, other records) are
  preserved.
- Tokens are never printed. Path 4b never modifies your CLI's token file;
  path 4a doesn't touch the CLI at all.

After login: restart the GUI → Settings → Models → pick provider
**`kimi-coding`**, model **`k3`** (Kimi K3, **1M context**) or `k3-256k`
(256K) / `kimi-for-coding` (K2.7 Code), set as default agent model → new
sessions run on your subscription. (This repo's setup sets `k3` — 1M
context — as the default; you can still switch per session from the
conversation's model selector.)

### Troubleshooting: "OAuth refresh failed for kimi-coding … The provided authorization grant is invalid"

The stored refresh token was rejected by `auth.kimi.com`. Causes:

- The shared lineage (4b) was burned: the harness refreshed, the server
  rotated the token, and the other copy (CLI's or the harness's) became
  invalid. This is the classic failure of two clients sharing one OAuth
  refresh token.
- Or the token genuinely expired/revoked.

Fix: run `npm run dsh:kimi-login` (preferred — independent credential), or
`kimi login` followed by `npm run dsh:bridge`. No API key is involved.

## 4b. NVIDIA free tier (build.nvidia.com)

The harness ships NVIDIA as a built-in provider (`nvidia`, endpoint
`https://integrate.api.nvidia.com/v1`); `npm run dsh:setup` now also writes a
30-model free-tier profile into `settings.yaml`. To use:

1. **Settings → API keys** → add `NVIDIA_API_KEY` (your build.nvidia.com key; per machine).
2. **Settings → Models** → provider **NVIDIA (free tier)** → pick a model.
3. New sessions can run on it.

Notable free models include `moonshotai/kimi-k3` (**"Kimi K3 (NVIDIA free)"** —
distinct from your subscription **`kimi-coding/k3`** "Kimi K3", 1M context on
kimi.com), Llama 3.3/3.1/3.2, Nemotron 3/4, Gemma 3/4, GPT-OSS, GLM 5.2, MiniMax
M3, Mistral, and DeepSeek V4 flash/pro — the last two are labeled
**"DeepSeek V4 Flash (NVIDIA free)"** and **"DeepSeek V4 Pro (NVIDIA free)"** to
tell them apart from the official DeepSeek API models (the pay tier, provider
**DeepSeek**, models **DeepSeek-V4-Flash** / **DeepSeek-V4-Pro** / the vision
exp). NVIDIA free-tier runs on your `NVIDIA_API_KEY` against build.nvidia.com;
the official DeepSeek models run on `DEEPSEEK_API_KEY` against api.deepseek.com.
Embeddings/vision/safety/tool models are not listed — they cannot drive an
agent. Context windows for the added entries are conservative defaults; tune
`contextWindow`/`maxTokens` in `settings.yaml` per model if needed.

## Re-running (e.g. after a weekly swap, or after a harness upgrade)

`npm run dsh:setup` again — it detects what is already in place and only changes
what is missing or out of date. After any re-run: restart the GUI. The
subscription credential is per-machine: run `npm run dsh:kimi-login` (or `kimi
login` + `npm run dsh:bridge`) on a machine whenever you re-authenticate there.
Skills: `npm run skills:install` (idempotent) refreshes `~/.dsh/skills/` from
the repo's `.agents/skills/`.

## 5. Skills and agent orchestration

The repo ships starter skills (`.agents/skills/`) and an orchestration guide:

- **Skills** — poteto's pstack (30 skills: 20 principles + `poteto-mode` +
  workflow skills). Auto-discovered in this repo's sessions; available
  everywhere after `npm run skills:install`. Author new skills as
  `.agents/skills/<name>/SKILL.md` (frontmatter: `name`,
  `description`, optional `whenToUse`).
- **Orchestration** — see [`ORCHESTRATION.md`](ORCHESTRATION.md): subagents
  (`subagent`, `subagent_fork`), the Kimi CLI subagent (`subagent_kimi`),
  workflow scripts, and the Ralph loop, with copy-paste patterns.
