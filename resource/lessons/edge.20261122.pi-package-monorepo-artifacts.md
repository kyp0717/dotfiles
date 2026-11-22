# Lesson: third-party pi packages can ship monorepo artifacts; check the git source and pin by commit hash

Date: 2026-11-22. Machine: woodlawn. Surfaced installing the
pi-acp-agents extension: `pi install npm:pi-acp-agents@0.3.0` failed
with `EUNSUPPORTEDPROTOCOL workspace:*`, and the git main version then
failed to load with `Cannot find module 'zod/v4'`.

## What happened

Two separate upstream packaging bugs, both invisible until install/load:

1. The published npm tarball (0.3.0, latest; also tag v0.5.0) declares
   `"pi-acp-types": "workspace:*"` in dependencies. pi installs package
   deps with npm, which cannot resolve the pnpm workspace protocol ->
   install fails with EUNSUPPORTEDPROTOCOL.
2. On git main (v0.5.1, where bug 1 is fixed), the extension loads
   `zod/v4` from `src/tui/persona-resolver.ts`, but zod is in neither
   dependencies nor peerDependencies. It resolves only because pnpm
   hoists it in the author's monorepo -> pi startup fails with
   "Cannot find module 'zod/v4'".

## Why it happened

Monorepo-published packages where `pnpm publish` rewriting did not run
(or CI published from the wrong step) leak `workspace:*` specs, and
hoisted monorepo node_modules hide undeclared dependencies from the
author. Nothing in pi's package flow lints for either.

## The fix

- Pin the git source at main HEAD by commit hash:
  `git:github.com/buihongduc132/pi-acp-agents@1d3ba9...`. Commit-hash
  refs are never refetched/reset by pi, which also makes a local
  node_modules patch durable.
- Patched per-machine: `npm install zod@^4 --no-save` inside
  `~/.pi/agent/git/github.com/buihongduc132/pi-acp-agents`.
  `--no-save` keeps upstream files pristine; the recreate step is
  documented in `resource/handoff/20261122-pi-acp-agents-extension.md`.

## Rules that fall out

- A pi package failing with `workspace:` in the error is a broken
  upstream publish; go to the git repo, check whether main's
  package.json fixed it, and pin a commit hash rather than a branch.
- After any extension install, run `pi --help` (or any pi command) and
  read stderr: module-resolution failures surface there at startup.
- "Cannot find module X/vN" from an extension usually means an
  undeclared dependency, not a pi problem; check the extension's
  manifests before blaming the harness.
- Per-machine patches inside `~/.pi/agent/git/` survive only on
  commit-hash pins; branch/tag pins get reset. Record the patch as a
  recreate step in handoff/todos, never in git.
