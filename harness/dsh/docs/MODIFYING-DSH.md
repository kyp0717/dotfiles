# Modifying the DeepSeek Harness (DSH)

Reference notes on how to change DSH yourself — the plugin architecture, the
four ways to modify it (ranked by durability), and the mechanics of how a
change actually reaches the running GUI. Written after the "show provider next
to model in the composer seat" discussion.

## 1. How DSH is structured

DSH isn't one app — it's a **monorepo of ~200 tiny npm packages**, each a
**cordis plugin**. Cordis is the DI/lifecycle framework: every plugin declares
what it `provides` and what it `inject`s, and the loader wires them into a
graph.

- **Host plane** (Node): runs agents, tools, credentials, the HTTP server.
  Packages like `dsh-llm-*`, `dsh-host-apiproxy`, `dsh-session-*`.
- **Client plane** (browser React): packages named `dsh-client-ui-*`. Each
  ships a **compiled bundle** at `lib/client.js`.

UI is composed through **slots**. A component "owns" a named slot
(`conversation.input.model`) and other plugins register renderers into it. The
composer model seat is the `ModelSelect` component in
`@deepseek-ai/dsh-client-ui-model-selection`, registered via:

```js
scope.slots.inject("conversation.input.model", () =>
  scope.slots.register({ name: "conversation.input.model", ... }, ModelSelect))
```

The source of truth lives on GitHub (`github.com/deepseek-ai/deepseek-harness`);
the installed packages are compiled output. In the installed bundle,
`//#region` comments preserve the original source path (e.g.
`packages/client/ui-model-selection/src/client/ModelSelect.tsx`) — that's your
map back to the repo.

## 2. The exact change for "provider next to model"

In `ModelSelect` the trigger label is computed here:

```js
const modelLabel = currentChoice?.model.name ?? t("trigger.fallback");
const triggerLabel = effortLabel === void 0 ? modelLabel : `${modelLabel} · ${effortLabel}`;
```

The provider name is already in hand: `currentChoice` is `{ group, model,
selection }`, and `group.name` is the provider display name (`"DeepSeek"` vs
`"NVIDIA (free tier)"`). The component simply never renders it. So the change
is a two-liner:

```js
const modelLabel = currentChoice == null
  ? t("trigger.fallback")
  : `${currentChoice.group.name} · ${currentChoice.model.name}`;
```

Mirror it in `trigger.aria` / `title` if you want the accessible name to match.
No new data flow, no host change.

## 3. The four ways to modify DSH, ranked by durability

### Level 0 — settings (`~/.dsh/settings.yaml`)

No code, survives upgrades, but only touches what a plugin already makes
configurable (model names/catalogs, endpoints, defaults, API-key env). Cannot
change rendering.

### Level 1 — profile patch (`~/.dsh/profiles/web/cordis.patch.yml`)

The intended extension seam. A YAML array of loader operations applied on top
of the shipped bundles: `- insert:` new plugin rows, `- id:` overrides config,
disables. This is exactly how `dsh/scripts/setup-kimi.mjs` mounts the Kimi ACP
bridge. Powerful for *adding/overriding plugins and config*, but it still can't
reach inside a plugin's React render.

### Level 2 — write your own plugin package

The "proper" durable path for new behavior. Create a `dsh-client-ui-*` package
that `slots.inject("conversation.input.model", ...)` with your own component,
install it into `~/.dsh/profiles/node_modules`, and add an `- insert:` row in
the patch. Upgrade-safe (you own it), but means reimplementing/copying
`ModelSelect` (~300 lines) or wrapping the slot — the most work.

### Level 3 — patch the installed bundle

Edit
`~/.dsh/profiles/node_modules/@deepseek-ai/dsh-client-ui-model-selection/lib/client.js`
directly. The bundle is **not minified** — readable compiled JS with `//#region`
markers — so a surgical edit is straightforward. Fast and pragmatic for a
one-off change, with one big caveat: it's outside version control and **gets
wiped the next time `npx @deepseek-ai/dsh@…` reinstalls/upgrades**, so you
re-apply it manually (or keep a patch file).

### Level 4 — fork the source

Clone `deepseek-harness`, edit the real TSX, and run `pnpm run dev:web`
(Vite + HMR) during development, or build and point at your fork. The right
long-term answer if you expect to keep hacking on it; needs the pnpm/Vite/TS
toolchain.

## 4. How "taking effect" actually works

The non-obvious bit:

- The browser loads each client plugin from
  `/plugins/<package-id>/client.js?rev=<hash>`.
- The host resolves that file **from the profile directory's `node_modules`**,
  not the `npx` cache. `ctx.baseUrl` is the profile dir
  (`~/.dsh/profiles/web`), and `require.resolve` walks
  `~/.dsh/profiles/node_modules` from there.
- So the file you edit is
  `~/.dsh/profiles/node_modules/@deepseek-ai/dsh-client-ui-model-selection/lib/client.js`
  — **not** `/home/phage/.npm/_npx/…` (that's a throwaway mirror; editing it
  does nothing to the running GUI).
- The `?rev=` is a content hash computed at boot. In a dev checkout with
  `dev:web` running, a watcher re-hashes and pushes the new bundle over HMR
  (no refresh). In a plain npm install there's no watcher, so after editing you
  **restart `dsh web` and hard-refresh** the page.

Sanity check after an edit that shows no change: DevTools → Network → find the
`/plugins/…/client.js` request and confirm its `rev=` changed after restart. If
it didn't, the host is still serving the old file.

## 5. Finding "where does X live" on your own

1. In the browser, inspect the element and note its CSS class hash (the model
   trigger is `._7KE1Ra_trigger`).
2. `grep -r "_7KE1Ra_trigger" ~/.dsh/profiles/node_modules/@deepseek-ai/`
   → lands on the owning package.
3. Open that package's `lib/client.js`, read the `//#region …/src/…` header for
   the source path, and find the GitHub monorepo file.
4. For UI strings, grep the `en`/`zh` locale objects in the same package — that's
   where display text lives.

## 6. Recommendation for the composer-seat change

**Level 3 (bundle patch) now** — two-line edit, immediately correct; keep a
`.patch` file or a note to re-apply after a harness upgrade. If it must survive
upgrades cleanly, the Level 2 plugin (or Level 4 fork) is the durable route but
a bigger lift.

---

## Context note (previous change, same session)

Two "DeepSeek" providers exist and their display names collided:

| Provider (route) | Display name | Endpoint / key | DeepSeek models |
|---|---|---|---|
| `deepseek-official` | **DeepSeek** | `api.deepseek.com` / `DEEPSEEK_API_KEY` (pay tier) | `DeepSeek-V4-Flash`, `DeepSeek-V4-Pro`, `DeepSeek-V4-Flash-Vision-Exp` |
| `nvidia` | **NVIDIA (free tier)** | `integrate.api.nvidia.com` / `NVIDIA_API_KEY` (free) | `deepseek-ai/deepseek-v4-flash-0731`, `deepseek-ai/deepseek-v4-pro-0813`, … |

Fix applied (settings-only): renamed the NVIDIA free-tier DeepSeek models to
`DeepSeek V4 Flash (NVIDIA free)` and `DeepSeek V4 Pro (NVIDIA free)` in both
`dsh/scripts/setup-kimi.mjs` and `~/.dsh/settings.yaml`, and documented the
free-vs-paid distinction in `SETUP.md`. Default model at the time:
`deepseek-official / deepseek-v4-pro` (pay tier).
