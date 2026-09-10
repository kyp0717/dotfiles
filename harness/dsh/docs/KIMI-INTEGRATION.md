# Integrating Kimi Code into the DeepSeek Harness (dsh)

A step-by-step, reproducible guide for wiring Moonshot's **Kimi Code CLI** into a
[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) deployment, plus
how to use **Kimi K2/K3 models** as the harness's main agent model.

> **Prefer the automated setup.** The manual steps below are the reference
> implementation. For day-to-day work — especially keeping **two machines in
> parity** — use the one-command, idempotent script:
>
> ```bash
> npm run dsh:setup            # or: node dsh/scripts/setup-kimi.mjs
> npm run dsh:setup:dry        # preview without writing
> ```
>
> See [`SETUP.md`](SETUP.md) (one machine) and
> [`sync/README.md`](../../sync/README.md) (weekly swap routine).

This document was written against a verified setup:

| Component | Version / value verified |
|---|---|
| DeepSeek Harness (dsh) | `0.1.1-rc.2` (`dsh web` profile) |
| Kimi Code CLI | `0.38.0` at `~/.kimi-code/bin/kimi` |
| ACP bridge plugin | `@deepseek-ai/dsh-subagent-acp@0.1.1-rc.2` |
| ACP protocol | `protocolVersion: 1` (both sides) |
| Harness LLM layer | pi-ai `0.82.1` (ships Kimi model catalogs) |

> **Status note:** the protocol handshake between the harness's ACP client and
> `kimi acp` has been verified end-to-end. A full delegated-task run through a
> live session is the final acceptance test (Step 7).

---

## Table of contents

1. [How the harness is put together](#1-how-the-harness-is-put-together)
2. [Install and log in to Kimi Code CLI](#2-install-and-log-in-to-kimi-code-cli)
3. [Add the official ACP bridge plugin to the profile](#3-add-the-official-acp-bridge-plugin-to-the-profile)
4. [Mount the provider (host plane)](#4-mount-the-provider-host-plane)
5. [Expose the tool via an agent preset (agent plane)](#5-expose-the-tool-via-an-agent-preset-agent-plane)
6. [Make `kimi` the default preset (optional)](#6-make-kimi-the-default-preset-optional)
7. [Restart the GUI](#7-restart-the-gui)
8. [Verify the integration](#8-verify-the-integration)
9. [Bonus: Kimi K2/K3 as the harness's main model](#9-bonus-kimi-k2k3-as-the-harnesss-main-model)
10. [Appendix: version matching and troubleshooting](#10-appendix-version-matching-and-troubleshooting)

---

## 1. How the harness is put together

The harness is a Cordis plugin framework. A running GUI is a **profile**. On this
machine the `web` profile lives at `~/.dsh/profiles/web`. A profile is assembled
from ordered **layers**:

1. **Bundle layers** — `package.json` → `dsh.profile.bundles`. The `web` profile
   ships with `@deepseek-ai/dsh-base` + `@deepseek-ai/dsh-web-app`. Each bundle
   contributes a `cordis.patch.yml`.
2. **Your patch layer** — `~/.dsh/profiles/web/cordis.patch.yml` (a top-level YAML
   list of id-targeted config overrides, disables, and inserts). This is where a
   deployment adds or overrides plugin rows. It starts as `[]`.
3. **Agent presets** — *agent-plane* compositions that define what tools an agent
   sees. Shipped presets (`standard`, `code`, `minimal`, `cordis`) live read-only
   inside the install at `config/agent-presets/`. **User-authored presets go in
   `~/.dsh/.agent-presets/<preset-id>/agent.cordis.yml`** and are discovered
   automatically.

Two planes matter for this integration:

- **Host composition** — process-global services, including the **subagent
  provider registry** (`ctx.subagents`). Providers register here under unique
  names (`spawn`, `fork`, and optional product bridges such as `codex`,
  `claude-code`, or our `kimi`).
- **Agent presets** — per-agent tools. The shipped `standard` preset contains
  *disabled* rows for `subagent-codex` and `subagent-claude-code`, with the
  comment: *"Install the matching Bundle in this Profile and restart the Host,
  then copy this preset and remove `disabled` from the matching tool row."*

That comment is the blueprint for the Kimi integration: install a provider bundle
(host plane), then add a tool row in a preset (agent plane).

**Why ACP?** Kimi Code ships an official automation entry point that speaks the
Agent Client Protocol over stdio:

```bash
kimi acp --help
# "Run kimi-code as an Agent Client Protocol (ACP) server over stdio."
```

The harness ships a generic ACP subagent provider that spawns an external ACP
agent and drives it over stdio — so no product-specific protocol code is needed.

---

## 2. Install and log in to Kimi Code CLI

Already done on this machine, but for a fresh deployment:

```bash
# Install (see https://github.com/MoonshotAI/kimi-code)
curl -fsSL https://kimi.moonshot.cn/install/install.sh | bash

# Authenticate and check
kimi login                 # device-code login, or configure providers in ~/.kimi-code/config.toml
kimi --version
```

The CLI stores its state under `~/.kimi-code/` (config, credentials, OAuth). A
working install has a configured provider/model, e.g.:

```toml
# ~/.kimi-code/config.toml (excerpt, secrets redacted)
default_model = "kimi-code/k3-256k"

[providers.moonshot-ai]
base_url = "https://api.moonshot.ai/v1"
type = "kimi"
api_key = "..."   # or use OAuth via [providers."managed:kimi-code"]
```

**Compatibility probe (do this before wiring the harness):** pipe an ACP
`initialize` handshake into `kimi acp` and confirm it answers
`protocolVersion: 1`:

```bash
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{}},"meta":{}}' \
  | timeout 25 ~/.kimi-code/bin/kimi acp
# → {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":1,"agentCapabilities":{...}}}
```

The harness's ACP client SDK (`@agentclientprotocol/sdk` 0.25.1, used by
`dsh-subagent-acp` 0.1.1-rc.2) also uses `PROTOCOL_VERSION = 1`, so the two sides
negotiate cleanly.

---

## 3. Add the official ACP bridge plugin to the profile

Install the harness's generic ACP subagent provider into the profile as an
out-of-tree plugin:

```bash
dsh plugin --profile web add @deepseek-ai/dsh-subagent-acp@0.1.1-rc.2
```

This edits `~/.dsh/profiles/web/package.json` (adds the dependency) and installs
it into the profile's `node_modules`.

> **Version matching is critical.** The bridge's peer dependencies must match the
> installed harness. Check with:
> `npm view @deepseek-ai/dsh-subagent-acp@<version> peerDependencies`
> and compare against the harness version in `~/.npm/_npx/*/node_modules/@deepseek-ai/dsh/package.json`.
> `0.1.1-rc.2` matches a `0.1.1-rc.2` harness exactly.

---

## 4. Mount the provider (host plane)

Append an **insert block** to the profile's patch layer. This registers a
provider named `kimi` on the harness's subagent registry.

> **Patch syntax gotcha (verified live):** a bare `- id: <new-id>` row in a
> patch file is an *override* of an existing row — if the id does not already
> exist in the composed tree, the loader warns `patch: entry "<id>" not found`
> and the row is **not** mounted. New rows must be wrapped in an `- insert:`
> block (the same form the shipped `dsh-web-app` patch uses):

```yaml
# ~/.dsh/profiles/web/cordis.patch.yml
- insert:
    - id: subagent-kimi
      name: '@deepseek-ai/dsh-subagent-acp'
      config:
        providerName: kimi                     # the name agents reference
        command: /home/phage/.kimi-code/bin/kimi   # absolute path (or "kimi" if on PATH)
        args: [acp]                            # run Kimi Code as an ACP server over stdio
        permission: allow                      # 'allow' auto-approves the child's permission prompts (like --yolo);
                                               # 'reject' declines every prompt
        env: {}                                # optional extra env; parent env is forwarded credential-scrubbed
```

Config fields supported by the bridge (`dsh-subagent-acp` 0.1.1-rc.2):

| Field | Meaning |
|---|---|
| `providerName` | Provider name on `ctx.subagents` (default `acp`) |
| `command` | Executable to spawn for each run (**required**) |
| `args` | Arguments to `command` (default `[]`) |
| `cwd` | Optional working-directory override; omitted = inherit the delegating session's cwd |
| `permission` | `allow` or `reject` (default `reject`); how to auto-answer the child's `session/request_permission` prompts |
| `env` | Extra env vars for the child (default `{}`) |
| `disposeEofGraceMs` / `disposeGraceMs` | Process teardown grace periods (ms) |

---

## 5. Expose the tool via an agent preset (agent plane)

Providers live in the host registry; **tools** live in presets. Since shipped
presets are read-only, author a **user preset** — a copy of `standard` plus one
extra tool row:

```bash
mkdir -p ~/.dsh/.agent-presets/kimi
cp ~/.npm/_npx/*/node_modules/@deepseek-ai/dsh/config/agent-presets/standard/agent.cordis.yml \
   ~/.dsh/.agent-presets/kimi/agent.cordis.yml
```

Then append the tool row (same shape as the disabled `subagent-codex` row in the
shipped preset, but enabled):

```yaml
# ~/.dsh/.agent-presets/kimi/agent.cordis.yml  (added row)
- id: tool-subagent-kimi
  name: '@deepseek-ai/dsh-tool-subagent'
  config:
    provider: kimi
    toolName: subagent_kimi
    backgroundMode: one-shot
    maxDepth: provider-managed
```

Why `maxDepth: provider-managed`: the ACP provider advertises **no start-time
capabilities** — it cannot enforce depth limits, output schemas, tool filters, or
personas inside an out-of-process child, and the tool layer rejects
`maxDepth: <number>` for providers without the `depthLimit` capability.
`provider-managed` leaves the recursion budget to Kimi itself.

---

## 6. Make `kimi` the default preset (optional)

Agents default to the preset named in the `agent-presets` row (shipped value:
`standard`). Switch the default from your patch layer:

```yaml
# ~/.dsh/profiles/web/cordis.patch.yml (in addition to Step 4)
- id: agent-presets
  config:
    default: kimi
```

Alternatively keep `standard` and select the `kimi` preset per session in the
GUI's preset picker.

---

## 7. Restart the GUI

The profile is loaded at boot; a newly added plugin requires a restart of the
`dsh web` server. Stop the running instance and start it again from the same
launch directory (the invoking directory is the default workspace root):

```bash
dsh web            # or: npx dsh --profile web
```

---

## 8. Verify the integration

1. **Config sanity** — confirm the composed tree mounts without errors:
   ```bash
   dsh --profile web --dump-config
   ```
   Look for the `subagent-kimi` row and the `tool-subagent-kimi` preset row.
2. **Tool catalog** — in a session on the `kimi` preset, confirm the agent's tool
   list contains `subagent_kimi`.
3. **End-to-end run (the definitive test)** — ask the main agent to *"delegate
   this task to the kimi subagent"*. Watch for a `kimi` process spawning with its
   own model (default `kimi-code/k3-256k`), running the task, and returning a
   result. The child runs in the delegating session's workspace.

---

## 9. Bonus: Kimi K2/K3 as the harness's main model

The harness's LLM layer (pi-ai) **already ships Kimi model catalogs**, so using
Kimi as the main agent model is configuration, not code:

| Provider id | Models | Endpoint |
|---|---|---|
| `moonshotai` | `kimi-k2.5`, `kimi-k2.6`, `kimi-k2.7-code`, `kimi-k2.7-code-highspeed`, `kimi-k3`, ... | `https://api.moonshot.ai/v1` |
| `moonshotai-cn` | (mainland China mirror) | — |
| `kimi-coding` | `k3`, `k3-256k`, `kimi-for-coding`, `kimi-for-coding-highspeed` | `https://api.kimi.com/coding` |

To use it:

1. **Settings → API keys**: add `MOONSHOT_API_KEY` (for `moonshotai`) or
   `KIMI_API_KEY` (for `kimi-coding`).
2. **Settings → Models**: pick provider `moonshotai`, model `kimi-k2.7-code` (or
   `kimi-k3`), and optionally set it as the default agent model.

The provider directory the Settings UI renders is data-driven from the installed
pi-ai catalog — no code changes required.

### Using your Kimi Code *subscription* (no API key)

The `kimi-coding` provider also ships the subscription OAuth flow ("Sign in with
Kimi Code" — the same `auth.kimi.com` device login and client id the CLI uses),
but this dsh build exposes no GUI button or command to start it. `npm run dsh:bridge`
(`dsh/scripts/bridge-kimi-token.mjs`) imports the OAuth tokens your CLI already
holds (from `kimi login`) into the harness credential store under
`llm-pi-ai/kimi-coding` (kind `grant`), so the harness authenticates to
`api.kimi.com/coding` with your **monthly subscription** — verified end-to-end
with a real request through the harness's pi-ai stack. See `SETUP.md` § 4.

---

## 10. Appendix: version matching and troubleshooting

### Why version matching matters

`dsh-subagent-acp` declares `peerDependencies` on the harness's core packages
(`dsh-agent`, `dsh-subagent`, `dsh-subprocess`, `dsh-llm`, `cordis`, ...). A
mismatched bridge can fail to load or misbehave. Always install the bridge
version whose peer range matches the harness version (both `0.1.1-rc.2` here).

### Common failure points

| Symptom | Likely cause / fix |
|---|---|
| `dsh: [.../cordis.patch.yml] patch: entry "subagent-kimi" not found` | You wrote the new row as a bare `- id:` entry; new rows must be wrapped in `- insert:` (see Step 4). |
| `subagent-acp: child start failed` | `command` not found or not executable; use the absolute path (`~/.kimi-code/bin/kimi`). |
| Provider not found when the tool is called | The host-plane provider row is missing or the GUI was not restarted after adding it. |
| `tool-subagent: provider "kimi" cannot enforce maxDepth` | You set `maxDepth: <number>`; use `maxDepth: provider-managed`. |
| Child declines every tool call | `permission: reject` is set; use `permission: allow` for autonomous delegated runs. |
| Kimi asks for login mid-run | Run `kimi login` once on the machine; the CLI stores credentials under `~/.kimi-code/`. |

### How the pieces fit

```
dsh web profile (host plane)                    agent preset "kimi" (agent plane)
┌─────────────────────────────────────┐         ┌──────────────────────────────┐
│ cordis.patch.yml                    │         │ ~/.dsh/.agent-presets/kimi/  │
│  - subagent-kimi                    │         │   agent.cordis.yml           │
│    name: dsh-subagent-acp           │  spawn  │  - tool-subagent-kimi        │
│    command: kimi acp  ──────────────┼────────►│    provider: kimi            │
│    providerName: kimi               │  stdio  │    toolName: subagent_kimi   │
│                                     │  ACP    └──────────────────────────────┘
│  ctx.subagents registry:            │
│    spawn, fork, kimi                │
└─────────────────────────────────────┘
```

### References

- DeepSeek Harness: <https://github.com/deepseek-ai/deepseek-harness>
- Kimi Code CLI: <https://github.com/MoonshotAI/kimi-code>
- Agent Client Protocol: <https://agentclientprotocol.com>
- dsh subagent subsystem doc: `docs/subsystems/subagent.md` in the harness repo
