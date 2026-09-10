# POTETO-SKILLS-WORKFLOW.md — using poteto's pstack in this harness

How to use [poteto's pstack](https://github.com/cursor/plugins/tree/main/pstack)
— the plugin of engineering principles, evidence discipline, and playbook
routing — in this harness.

**The loaded set (vendored in `.agents/skills/`) is pstack-strict: 30 skills.**

- **20 engineering principles** (`principle-prove-it-works`,
  `principle-encode-lessons-in-structure`, …) — the design guardrails.
- **`poteto-mode`** — the style + playbook routing layer (22 playbooks:
  feature, bug-fix, investigation, perf, shipping, …).
- **Workflow skills** — `architect` (settle boundaries before code),
  `arena` (N parallel attempts, take the best), `interrogate` (several
  models try to break a diff), `tdd`, `why` / `how` (evidence-backed
  walkthroughs), `show-me-your-work` (decision trail), `unslop` (writing).
- **`setup-pstack`** — records per-role model choices as an always-applied
  rule (optional).

**Deliberately not installed (removed 2026-09-02):** the noodle stage
machinery (`plan`/`execute`/`review`/`todo`/`brain`-as-skill/…), all
third-party packs (`frontend-design`, best-practices collections, …),
harness-ops skills, and `verify-atlas` (a documentation-only sample). If a
`poteto-mode` playbook step names one of these, do the step inline or skip
it and note the gap.

**What pstack changes:** evidence is the deliverable, not claims
(`principle-prove-it-works` — verify the real artifact, script the check;
`show-me-your-work` — a decision trail a reviewer can audit), judgment-heavy
steps get multi-model challenge (`arena`, `interrogate`), and the principles
give you 20 names to steer an agent mid-task ("that's a
[[fix-root-causes]], not a band-aid").

---

## 1. The mental model

A skill is **an instruction file the agent loads on demand**. When your
request matches a skill's description, the agent loads it and **follows it
instead of improvising**. You trigger skills with ordinary language, or
explicitly with `/skill:<name>`.

## 2. One-time setup per project

1. **`brain/` directory** — seed the design guardrails the principles
   reference:
   ```bash
   mkdir -p brain/plans brain/principles && echo "# Principles" > brain/principles.md
   ```
   Then copy each `principle-*/SKILL.md` body into
   `brain/principles/<short-name>.md` (short name = minus the `principle-`
   prefix) and list them as `[[wikilinks]]` in `brain/principles.md`. Add
   project-specific principles the same way. (ls-trader has this already —
   see its `brain/`.)
2. **Plans** — there is no `plan` skill (pstack-strict). Write plans
   directly into `brain/plans/`, citing `[[principles]]` wikilinks for every
   design decision.
3. **`poteto-mode`** (optional style layer) — say *"use poteto-mode"*. It is
   user-invocable only; it stays on across turns, matching playbooks as
   tasks arrive.
4. **`setup-pstack`** (optional) — records the intended role→model mapping
   as an always-applied rule. The route in this harness is the session's
   model, so this is documentation only.

## 3. Cheat sheet (what you type)

| You say | Skill | What happens |
|---|---|---|
| "Use poteto-mode: …" | `poteto-mode` (user-invoked) | Style + playbook routing for the session |
| "Why does X work this way?" | `why` | Parallel evidence queries, cited read |
| "How does X work?" | `how` | Subsystem walkthrough |
| "Review this / try to break this diff" | `interrogate` / `arena` | Multi-model challenge, synthesized verdict |
| "Write a test for …" | `tdd` | Test-first workflow |
| "Prove it / show your work" | `show-me-your-work` | Decision trail (TSV log) |
| "Write X (docs, reply, commit msg)" | `unslop` | Cut AI tells from the prose |

## 4. Honest caveats

- Poteto's skills were written inside poteto's **Noodle** ecosystem
  (`noodle worktree`, stage events). Noodle is not installed here; pstack's
  judgment skills don't depend on it, but playbooks that fan out to `swarm`
  or reference `recall`/`blast-radius` will name skills this repo doesn't
  have — adapt inline.
- **`poteto-mode` is user-invocable only** (`disable-model-invocation`).
- The **`orchestrate` playbook** assumes Cursor cloud subagents (`Task` tool)
  which this harness does not have; multi-agent orchestration is a separate
  project (see `../dsh/docs/ORCHESTRATION.md`).
- Skills are discovered **per workspace**: this repo's sessions see them
  automatically; other projects can vendor the same folder (as ls-trader
  does) or install globally via `npm run skills:install`.
