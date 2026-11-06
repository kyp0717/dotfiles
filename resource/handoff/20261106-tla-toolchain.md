# 2026-11-06 — TLA+ toolchain for pstack's statechart skill

## Why

The new pstack (pstack-claude, see 20261106-pstack-source-switch.md)
ships `statechart`: write a TLA+ spec, TLC model-checks it, output is a
Mermaid statechart plus the shortest path to each broken rule. It needs
bun (runs the TypeScript pipeline) and mise (installs Java temurin-25 +
tla2tools on first run). Neither was on the machines.

## Done on woodlawn

- New `scripts/tla.requirements.txt`: `bun@1.4.4`, `mise@2026.11.3`.
- New `scripts/tla.install.sh`: official GitHub release binaries into
  `~/.local/bin` (no sudo), arch-mapped, `--check` support, idempotent.
- Wired into `scripts/bootstrap.sh` STEPS (after node.install.sh).
- `resource/machine-rotation/README.md` parity table gained bun + mise.
- Proven end to end: tiny TLA+ spec -> `scripts/statechart` -> mise
  installed Java+TLC (network) -> TLC ran -> `chart.mmd` + `report.md`.

## Next machine (linden)

1. `git pull` in `~/dotfiles`.
2. `scripts/tla.install.sh` (or full `scripts/bootstrap.sh`).
3. `scripts/tla.install.sh --check` must pass.
4. Java + TLC install themselves on statechart's first run (network).

## Usage

- After `/reload`: `/skill:statechart` with a flow or protocol to model.
- Or `/skill:create-formal-verification-skill` for a repo-local check;
  it defaults to TLA+ for event-ordering and race questions.
- Script path (no skill needed):
  `~/.pi/agent/git/github.com/michael-denyer/pstack-claude/plugins/pstack/skills/statechart/scripts/statechart SPEC.tla --config SPEC.cfg`
- Env overrides: `TLA2TOOLS=<jar path>`, `JAVA=<java bin>` skip mise.
