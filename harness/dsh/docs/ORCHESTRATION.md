# ORCHESTRATION.md — building skills and orchestrating agents in the harness

This guide covers the harness's agent-orchestration primitives and the skills
system, with concrete patterns you can copy. Everything here runs on the
current deployment (dsh 0.1.1-rc.2, `kimi` preset, default model
`kimi-coding/k3`).

---

## 1. The primitives

| Primitive | Tool(s) | What it does | When to use |
|---|---|---|---|
| **Subagent (spawn)** | `subagent` | One-shot child agent in-process; fresh context, gets a standalone prompt, returns a result | Delegate a self-contained task; run in background by default |
| **Subagent fork** | `subagent_fork` | Child seeded with the parent conversation (sees your completed turns) | Follow-up analysis / continuation that builds on this conversation |
| **Subagent control** | `send_message`, `interrupt_agent`, `list_agents` | Message a running child, interrupt it, list live children | Drive long-running delegations |
| **Kimi Code CLI** | `subagent_kimi` | Delegates to the real Kimi Code CLI via ACP (own model, own tools) | Coding tasks where you want kimi-code's own agent loop |
| **Workflow** | `workflow` | A script that fans work out across many subagents with phases and structured results | Large fan-out: audits, migrations, multi-angle research, adversarial verification |
| **Ralph** | `ralph` | Fresh-agent iterative loop: each round a new child, shared workspace as memory | Long-running objectives the user explicitly wants as iterative fresh-agent loops |
| **Skills** | `skill` | Load a task-specific instruction set (SKILL.md) into context before acting | Any repeatable procedure — see §3 |

Key rule: the harness discourages over-nesting. Delegate at depth; use
workflows for fan-out; keep the main conversation as the orchestrator.

---

## 2. Patterns

### 2.1 Simple delegation (one child)

> "Delegate this to a subagent: summarize the READMEs in this repo into a table."

The agent calls `subagent` (background by default). You get a notice when it
settles; the result includes its final answer. Use `run_in_background: false`
only when the next step depends on the answer immediately.

### 2.2 Fork (continuation with context)

> "Use a subagent fork to review the setup script I just wrote and list
> failure modes."

`subagent_fork` seeds the child with this conversation so it understands the
context without re-explaining it.

### 2.3 Kimi Code as a specialist

> "Delegate this refactor to the kimi subagent: <task>"

Spawns `kimi acp` in the session workspace. The child runs kimi-code's own
model (`kimi-code/k3-256k` by default) and tools; the result returns to the
main agent. One-shot by design — for interactive kimi-code, use the `kimi`
TUI or `kimi web` in a terminal, or set the session model to `kimi-coding/k3`.

### 2.4 Fan-out with a workflow script

For work that spreads across many independent pieces (audit N files, research
N angles), write a workflow. Shape (see the `workflow` tool for the full
contract):

```js
// meta: { name, description, phases? }  — the script body only:
const files = args.files
const results = await parallel(files.map((file) => async () => {
  return await agent(`Analyze ${file} and return a one-paragraph summary.`, { label: file })
}))
return results.filter(Boolean)
```

Stages: `agent(prompt, {schema?, label?, phase?, provider?, model?})`,
`pipeline(items, ...stages)` (no barrier between stages), `parallel(thunks)`
(barrier), `phase(title)`, `log(message)`. Misused hooks throw and kill the
script — keep schemas to the supported subset.

### 2.5 Ralph loop (explicitly requested)

Only when the user asks for a Ralph loop / fresh-agent iteration. Each round
starts a fresh child with no conversation seed; the shared workspace is the
durable memory; completion is the worker's report.

---

## 3. Skills

A skill is a reusable instruction set: a directory `SKILL.md` with YAML
frontmatter (`name`, `description`, optional `whenToUse`) plus a Markdown
body. Agents discover them automatically and load them via the `skill` tool
before acting.

### Discovery roots (where skills live)

| Root | Scope | Synced via repo? |
|---|---|---|
| `<project>/.agents/skills/` | Sessions whose workspace is that project | ✅ (this repo uses it) |
| `<project>/.dsh/skills/` | Same | ✅ |
| `~/.dsh/skills/` (user root) | Every workspace on the machine | ❌ per machine — install via `npm run skills:install` |
| `~/.agents/skills/` | Every workspace on the machine | ❌ per machine |

### Anatomy of a skill

```markdown
---
name: my-skill
description: One sentence on what it does and when to run it.
whenToUse: Optional — more detail on matching conditions.
---

# My skill

Procedure, checklists, commands… Anything an agent needs to execute the task
repeatably. Keep it decisive: the agent follows it directly.
```

Rules observed in this harness: kebab-case `name`; `name` + `description`
required; invalid frontmatter → skill ignored (logged). Skills are loaded per
session; a loaded skill's instructions override generic guidance for that task.

### Skills in this repo (vendored, git-synced)

`.agents/skills/` holds **30 skills** — poteto's pstack, trimmed to strict (2026-09-02):
the 20 engineering principles + `poteto-mode` (style + playbook routing) + the
workflow skills (`architect`, `arena`, `interrogate`, `tdd`, `why`, `how`,
`show-me-your-work`, `unslop`, `setup-pstack`). The noodle stage machinery,
third-party packs, harness-ops skills, and `verify-atlas` were removed; see
`../../docs/POTETO-SKILLS-WORKFLOW.md`.

| Skill group | Purpose |
|---|---|
| pstack principles (20) | Engineering guardrails (`principle-prove-it-works`, …) — seed a project's `brain/principles/` from these |
| `poteto-mode` | Poteto's agent style + 22-playbook routing layer |
| `architect`, `arena`, `interrogate`, `tdd`, `why`, `how` | Boundary-first design, parallel attempts, multi-model challenge, TDD, evidence-backed walkthroughs |
| `show-me-your-work`, `unslop` | Auditable decision trail; prose cleanup |

Available in this repo's sessions automatically (`.agents/skills/`); install
globally on a machine with `npm run skills:install`.

### Importing third-party collections

Skills are **model-agnostic** — any SKILL.md-based collection works unchanged
on Kimi, DeepSeek, or any provider, and is universal across workspaces.

This deployment's vendored set is **poteto's pstack plugin** (pstack-strict):

```bash
# Re-import poteto's pstack from upstream into the repo (git-synced)
npm run skills:import -- --dest .agents/skills <url>
```

| Collection | Format | Compatible? |
|---|---|---|
| [poteto/noodle](https://github.com/poteto/noodle) (36 skills: execute, plan, review, debugging, worktree, …) | `.agents/skills/<name>/SKILL.md` | ✅ direct |
| [poteto/how](https://github.com/poteto/how) | `skills/how/SKILL.md` | ✅ direct |
| [poteto/verification-skill-example](https://github.com/poteto/verification-skill-example) | `.cursor/skills/<name>/SKILL.md` | ✅ direct |
| Any other SKILL.md collection (anthropics/skills, obra/superpowers…) | `SKILL.md` | ✅ direct |
| Cursor rules (`.mdc` — `globs`/`alwaysApply` schema) | different schema | ⚠️ needs conversion (e.g. [conforme](https://github.com/maxgfr/conforme)); not yet in `import-skills.mjs` |

The importer copies each skill's whole directory (SKILL.md + `references/` +
assets), is idempotent, validates the frontmatter exactly like the harness
(`name` kebab-case + `description`), and warns on name collisions
(`--force` overwrites). It scans `skills/`, `.cursor/skills/`,
`.claude/skills/`, `.agents/skills/`, `<name>/`, single-skill roots, and flat
`*.md` files.

### Authoring workflow (recommended)

1. Put the skill in `.agents/skills/<name>/SKILL.md` in this repo (synced).
2. Test it in a session whose workspace is the repo.
3. `npm run skills:install` on each machine to make it global.

---

## 4. Suggested next steps for your projects

- Pick a repeatable procedure from your actual work (build, test, release,
  trading-data ETL, voice pipeline…) and encode it as a skill; then delegate
  runs of it to subagents.
- For multi-repo work (e.g. `kadenx-trading` + `ls-trader`), write a workflow
  that fans out per repo and returns a consolidated report.
- Use `subagent_fork` for "review what we just did" loops so the child has
  context without re-pasting.

See `SETUP.md` (per machine), `../../sync/README.md` (weekly swap), and
`KIMI-INTEGRATION.md` (deep dive) for the deployment side.
