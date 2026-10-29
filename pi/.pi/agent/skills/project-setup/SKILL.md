---
name: project-setup
description: Initialize a new or existing project with a resource/ memory
  structure (lessons, bugs, handoff, plans, todos) and an AGENTS.md
  "Project Resource" section that instructs every agent session to use
  these folders. Use when starting a new project, adopting an existing
  one, or when the user asks to set up project memory, continuity
  folders, or the resource scaffold.
---

# Project setup

A project without a memory layout re-learns its own history every
session. This skill scaffolds the layout and writes the instructions
into the project's AGENTS.md so any agent on any machine or harness
follows it without this skill installed.

The scaffold is modeled on the layout proven in `~/work/ib-bracket-trading`
and this dotfiles repo: small dated files, one topic each, split by
kind. Building it is a ten-minute job. Maintaining it is the project's
own AGENTS.md's job from then on.

## Flow

### 1. Probe before asking anything

- Run `hostname`, `git rev-parse --is-inside-work-tree`, and list the
  project root.
- Check for an existing `AGENTS.md` and an existing `resource/`
  directory. Note what would merge and what would be created.

### 2. Ask the user these questions

Do not assume defaults silently. Ask, in one message:

1. **Subfolders** — standard set is `lessons`, `bugs`, `handoff`,
   `plans`, `todos`. Keep all, or drop some?
2. **AGENTS.md section** — add a `## Project Resource` section to the
   project's AGENTS.md? If no AGENTS.md exists, create one containing
   just that section?
3. **Two machines?** — if the user develops on more than one machine,
   the section adds the continuity rules (commit everything portable,
   per-machine state documented, identify the machine first). If not,
   the section stays single-machine.
4. **Commit?** — commit the scaffold right away, or leave it staged?

### 3. Scaffold resource/

For each chosen subfolder, create `resource/<name>/` with the matching
`README.md` from this skill's `templates/resource/<name>/README.md`
(resolve the template path against this skill's directory). Do not
overwrite an existing README; leave the human's text alone.

### 4. Write the AGENTS.md section

- If the user approved: append `## Project Resource` from
  `templates/AGENTS-section.md` to the existing AGENTS.md, or create
  AGENTS.md with that section as its body.
- If a `## Project Resource` section already exists, show the user the
  diff between it and the template and merge only what is missing.
- **Never clobber an existing AGENTS.md.** Append or merge only. A
  human-written instruction outranks the template.

### 5. Report and commit

List what was created and what was merged. Commit if the user said yes,
with a message naming this skill.

## Rules

- **Idempotent.** Running this skill twice on the same project must
  change nothing the second time. Probe first, create only what is
  missing.
- **Portable only.** Never write machine-specific paths, hostnames, or
  user names into the scaffold. Placeholders and probing language only,
  so the same files work on every machine the repo lands on.
- **The scaffold teaches, the skill does not linger.** After setup, the
  project's own AGENTS.md carries the conventions. Do not re-run this
  skill for routine lesson or bug filing; that is the job of the
  project's AGENTS.md and its lesson workflow.
- **README stubs are the contract.** Each subfolder's README states
  what belongs there and the naming convention. Keep them short.
