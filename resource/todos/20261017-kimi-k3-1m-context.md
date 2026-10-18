# 2026-10-17: Kimi K3 shows 256k in pi, not 1M

## Symptom

/model picker shows Kimi K3 at 256k context; no 1M option. Pi's built-in
catalog (`~/.pi/agent/models-store.json`) knows k3 = 1048576, but the
`pi-provider-kimi-code` extension (npm, 0.6.13) re-registers provider
`kimi-coding` and its models win.

## Root cause

- Extension builds kimi-coding models from
  `~/.pi/providers/kimi-coding/config.json` (stowed from
  `pi/.pi/providers/kimi-coding/config.json`), where
  `model.contextWindow = 262144` (the extension fallback default).
- The real per-account window arrives only via model discovery: GET to the
  Kimi `/models` catalog with a bearer token from `getKimiUsageToken()`,
  which reads the stored **OAuth** credential (`type: "oauth"` in
  `~/.pi/agent/auth.json`) or the `KIMI_API_KEY` env var. It never uses the
  api_key credential stored in auth.json.
- Live state: auth.json has kimi-coding as `type: "api_key"` (`sk-kimi-...`),
  and `KIMI_API_KEY` is not in the shell env. Discovery never runs, extras
  stay empty, every kimi-coding model publishes at 256k.

## Fix (user action, needs browser)

Run `/login kimi-coding` inside pi and complete the device flow. Account is
on the global side (`KIMI_CODE_OAUTH_HOST=https://auth.kimi.ai`, config
`region: "global"`), so the kimi.ai endpoints apply. After login, discovery
publishes K3 with the account's real window (1M) and `oauth.modifyModels`
keeps it fresh on token refresh.

## Alternatives (not recommended as primary)

- `export KIMI_API_KEY=sk-kimi-...` in shell env: discovery uses it, but it
  is a CI fallback path and the key must be valid for the /models endpoint.
- Edit stowed config.json `model.contextWindow` to 1048576: works offline
  but applies to ALL kimi-coding models and overrides the authoritative
  per-account catalog values.

## Verified facts (linden, 2026-10-17)

- Extension version 0.6.13 at `~/.pi/agent/npm/node_modules/pi-provider-kimi-code`.
- `settings.json`: defaultProvider kimi-coding, defaultModel kimi-for-coding.
- Env: `PI_PROVIDER=kimi-coding`, `PI_MODEL=kimi-for-coding`,
  `KIMI_CODE_OAUTH_HOST=https://auth.kimi.ai`, no `KIMI_API_KEY`.
- Code paths checked: `src/config.ts` (defaults), `src/models.ts`
  (`buildKimiModelFromConfig`, `applyKimiOAuthExtrasToModel`,
  `discoverKimiModelMetadata`), `src/usage.ts` (`getKimiUsageToken`),
  `index.ts` (`registerKimiProvider`, `oauth.modifyModels`).
