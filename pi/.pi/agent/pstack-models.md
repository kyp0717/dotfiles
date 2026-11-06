# pstack model configuration

Per-role model overrides for pstack skills. Each pstack SKILL.md names its defaults in a Models section; the values here override those defaults. Delete a line to fall back to the skill default. A value of `inherit-parent` or `auto` runs that role on the parent session's model (the `Agent` call omits `model`); an alias entry in a panel list still counts toward that panel's fan-out. A model may carry a reasoning effort, as in `opus @xhigh` (levels: low, medium, high, xhigh, max); the role's subagent then runs at that level, each entry of a panel list on its own. `default effort` sets the level for a value without one; `session` uses the runtime's platform mapping to start from the parent session's effort. `session hook: off` stops the supported runtime's pstack routing hook from injecting the poteto-mode mandate; any other value, or no line, leaves it on.

This setup has no anthropic credentials. Without the `pi models:` remap below, every alias resolves to an `anthropic/*` ID and each subagent dies with `No API key found for anthropic`. The remap keeps panels on two families (kimi-coding, deepseek); with only two reachable families, panel diversity is reduced — treat agreement accordingly. Every alias uses one of the two preferred models. Arena, architect, and interrogate panels have exactly two entries.

pi models: opus=kimi-coding/k3.1-pro, fable=deepseek/deepseek-v4-pro, sonnet=kimi-coding/k3.1-pro, haiku=deepseek/deepseek-v4-pro

feature, refactoring: sonnet
bug-fix: opus
perf-issue: opus
hillclimb: opus
judgment and prose: opus
strongest judgment: fable
how explorer: opus
how explainer: opus
why investigators: opus
why synthesizer: opus
reflect tooling: opus
reflect judgment, divergent, synthesizer: opus
arena runners: opus, fable
arena cross-judge pool: fable, opus
swarm workers: opus
architect runners: opus, fable
interrogate reviewers: opus, fable
thermos reviewers: opus
no-comments reviewer: opus

default effort: session
session hook: on
