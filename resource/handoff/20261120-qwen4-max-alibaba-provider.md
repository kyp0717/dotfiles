# 2026-11-20 — Qwen4-Max via direct Alibaba Model Studio provider in pi

## Why

Qwen4-Max (Alibaba's new flagship: 2.4T params, 1M context, native
vision/video, reasoning) launched 2026-11-16. A 5-day free promo ran on
Nous Portal (`qwen/qwen4-max:free`), but the user chose direct Alibaba
access (portable past the promo, no third party in the payload path).

## Done on linden

- New repo file `pi/.pi/agent/models.json`: custom provider `alibaba`
  (Alibaba Cloud Model Studio / DashScope, OpenAI-compatible).
  - baseUrl `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`
    (international; the Beijing-region equivalent is
    `https://dashscope.aliyuncs.com/compatible-mode/v1`).
  - apiKey `"$DASHSCOPE_API_KEY"` env interpolation, `authHeader: true`,
    `api: openai-completions`, `supportsStore: false`,
    `supportsReasoningEffort: true`.
  - Model `qwen4-max`: 1M context, 131072 max output (262144 in thinking
    mode, not modeled), input text+image, reasoning on, cost 1.50/4.50
    per M tokens. `cost.cacheRead/cacheWrite` are placeholders set to the
    input price; correct them once real cache pricing is known.
- `stow pi` links it to `~/.pi/agent/models.json`.
- Verified: `DASHSCOPE_API_KEY=sk-dummy pi auth check --provider alibaba`
  -> `ready`, and `pi --list-models` lists `alibaba qwen4-max`.
- Not verified end to end: no real key on the machine yet (user action).

## Per-machine state to re-establish (both machines)

1. Create an API key in the Alibaba Cloud Model Studio console
   (alibabacloud.com -> Model Studio -> API keys). New accounts
   typically get a free per-model token quota; check the console.
2. Add `export DASHSCOPE_API_KEY=sk-...` to the shell profile
   (~/.profile / ~/.zprofile). Never commit the key.
3. Check the base URL matches the key's region: international keys use
   `dashscope-intl.aliyuncs.com`, Beijing keys use
   `dashscope.aliyuncs.com`. If woodlawn's account differs, either use a
   second provider block or switch the baseUrl before stowing there.

## Next machine (woodlawn)

1. `git pull` in `~/dotfiles`.
2. `stow pi` from the repo root (links `~/.pi/agent/models.json`).
3. Export `DASHSCOPE_API_KEY` in the shell profile, open a new shell.
4. Verify: `pi auth check --provider alibaba --json` -> `ready`;
   `pi --list-models | grep alibaba`.

## Caveats

- pi's agent directory on 1.4.0/1.5.0 defaults to `~/.pi/agent`, so
  models.json lives in `pi/.pi/agent/`, NOT `pi/.pi/`. A models.json at
  `~/.pi/models.json` is silently ignored (`provider_not_found`). See
  `resource/lessons/edge.20261120.pi-models-json-location.md`.
- linden's managed pi is still 1.4.0 while `scripts/pi.requirements.txt`
  pins 1.5.0. Run `scripts/pi.install.sh` to catch up (also pulls in
  pi-session-move, harness 1.5.0).
