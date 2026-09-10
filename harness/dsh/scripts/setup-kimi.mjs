#!/usr/bin/env node
/**
 * setup-kimi.mjs — one-command Kimi Code integration for a DeepSeek Harness
 * (dsh) deployment. Idempotent: safe to re-run on every machine (and every
 * week) — it only changes what is missing or out of date.
 *
 * Usage:
 *   node dsh/scripts/setup-kimi.mjs [--dry-run] [--no-default-preset] [--verbose]
 *
 * What it does (mirrors the manual steps in dsh/docs/KIMI-INTEGRATION.md):
 *   1. Locates the Kimi Code CLI binary (PATH, then ~/.kimi-code/bin/kimi).
 *   2. Locates the dsh harness install and reads its version.
 *   3. Installs the version-matched ACP bridge
 *      (@deepseek-ai/dsh-subagent-acp) and its ACP SDK dependency
 *      (@agentclientprotocol/sdk) into the web profile's node_modules —
 *      preferring the pinned tarballs in ./vendor, falling back to the npm
 *      registry (pinned to the harness version).
 *   4. Patches <DSH_HOME>/profiles/web/cordis.patch.yml: inserts the `kimi`
 *      provider row (in the loader's `- insert:` form) and sets the default
 *      agent preset to `kimi` (unless --no-default-preset).
 *   5. Creates <DSH_HOME>/.agent-presets/kimi/agent.cordis.yml — a copy of the
 *      shipped `standard` preset plus the `subagent_kimi` tool row.
 *   6. Prints next steps (restart the GUI, verify, per-machine secrets).
 *
 * Secrets are NEVER touched: Kimi credentials/oauth and provider API keys stay
 * machine-local (see dsh/docs/SETUP.md § "Per-machine items").
 *
 * Requires: node >= 18, tar (POSIX), and for the npm-registry fallback also
 * npm. POSIX paths are assumed (both of your machines run Linux).
 */

import { existsSync, mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import {
  DSH_HOME, HOME, NPM_CACHE_DIR, PROFILE_DIR, PROFILE_NODE_MODULES, VENDOR_DIR,
  findDsh, installFromTarball, jsYaml, locateKimi, pkgVersion, read, run, sha256, yamlQuote,
} from './lib.mjs'

// ── constants ───────────────────────────────────────────────────────────────

const PATCH_FILE = join(PROFILE_DIR, 'cordis.patch.yml')
const PRESET_DIR = join(DSH_HOME, '.agent-presets', 'kimi')
const PRESET_FILE = join(PRESET_DIR, 'agent.cordis.yml')

const BRIDGE = '@deepseek-ai/dsh-subagent-acp'
const SDK = '@agentclientprotocol/sdk'
const BRIDGE_PKG = join(PROFILE_NODE_MODULES, BRIDGE, 'package.json')
const SDK_PKG = join(PROFILE_NODE_MODULES, SDK, 'package.json')

/** Marker section boundaries the script owns inside cordis.patch.yml. */
const SECTION_START = '# === KIMI SETUP (managed by setup-kimi.mjs) ==='
const SECTION_END = '# === END KIMI SETUP ==='

// ── tiny helpers ────────────────────────────────────────────────────────────

const flags = {
  dryRun: process.argv.includes('--dry-run'),
  defaultPreset: !process.argv.includes('--no-default-preset'),
  defaultModel: !process.argv.includes('--no-default-model'),
  verbose: process.argv.includes('--verbose'),
}

const out = {
  step: (msg) => console.log(`\n▸ ${msg}`),
  ok: (msg) => console.log(`  ✓ ${msg}`),
  info: (msg) => console.log(`  · ${msg}`),
  warn: (msg) => console.log(`  ! ${msg}`),
  fail: (msg) => { console.error(`  ✗ ${msg}`); process.exitCode = 1 },
}

// Shared helpers (constants, dsh/kimi discovery, tarball install, yamlQuote)
// live in ./lib.mjs.

// ── step 3: package install ────────────────────────────────────────────────

function vendoredTarball(packageName, version) {
  const norm = packageName.replace('@', '').replace('/', '-')
  const exact = join(VENDOR_DIR, `${norm}-${version}.tgz`)
  if (existsSync(exact)) return exact
  if (!existsSync(VENDOR_DIR)) return undefined
  // Fallback: any vendor tarball of this package (version must still match).
  for (const f of readdirSync(VENDOR_DIR)) {
    if (f.startsWith(norm) && f.endsWith('.tgz')) {
      const p = join(VENDOR_DIR, f)
      out.warn(`vendored ${f} does not match requested version ${version} — using it anyway`)
      return p
    }
  }
  return undefined
}

function npmPackTo(packageSpec, destDir) {
  mkdirSync(destDir, { recursive: true })
  const r = run('npm', ['--cache', NPM_CACHE_DIR, 'pack', packageSpec, '--pack-destination', destDir],
    { stdio: ['ignore', 'pipe', 'pipe'] })
  if (r.status !== 0) throw new Error(`npm pack failed for ${packageSpec}: ${r.stderr}`)
  const name = r.stdout.split('\n').map((s) => s.trim()).filter(Boolean).pop()
  if (!name) throw new Error(`npm pack produced no tarball name for ${packageSpec}`)
  return join(destDir, name)
}

function ensurePackage(packageName, version, pkgFile) {
  const current = pkgVersion(pkgFile)
  if (current === version) {
    out.ok(`${packageName} ${version} already installed`)
    return
  }
  if (current !== undefined) out.warn(`${packageName}: installed ${current}, need ${version} — reinstalling`)
  const targetDir = dirname(pkgFile)
  const tgz = vendoredTarball(packageName, version)
  if (tgz) {
    out.info(`using vendored tarball ${tgz} (sha256 ${sha256(tgz).slice(0, 12)}…)`)
  } else {
    out.info(`fetching ${packageName}@${version} from the npm registry`)
    if (flags.dryRun) { out.info(`(dry-run) would npm pack ${packageName}@${version}`); return }
    const fetched = npmPackTo(`${packageName}@${version}`, NPM_CACHE_DIR)
    installFromTarball(fetched, targetDir)
    rmSync(fetched, { force: true })
    out.ok(`${packageName} ${version} installed → ${targetDir}`)
    return
  }
  if (flags.dryRun) { out.info(`(dry-run) would extract ${tgz} → ${targetDir}`); return }
  installFromTarball(tgz, targetDir)
  out.ok(`${packageName} ${version} installed → ${targetDir}`)
}

/**
 * Verify the bridge actually imports from the profile's resolution path.
 * A fresh profile's node_modules mirror must already contain the harness's
 * base packages (peers like @deepseek-ai/schemastery); if the harness was
 * started at least once, they are there. This check turns the most common
 * fresh-machine failure (forgot to boot the harness once) into a clear
 * message instead of a boot-time crash.
 */
function verifyBridge() {
  if (flags.dryRun) { out.info('(dry-run) verification skipped'); return }
  const r = run(process.execPath, ['--input-type=module', '--eval',
    "const m = await import('@deepseek-ai/dsh-subagent-acp'); console.log(Object.keys(m).join(','))"],
    { cwd: PROFILE_DIR, stdio: ['ignore', 'pipe', 'pipe'] })
  if (r.status === 0) {
    out.ok(`bridge imports from the profile (exports: ${r.stdout.trim()})`)
  } else {
    out.warn(`bridge failed to import from ${PROFILE_DIR}: ${(r.stderr ?? '').trim().split('\n')[0]}`)
    out.warn('if this is a fresh machine, start the harness once (`dsh --profile web`) so its base packages populate the profile node_modules, then re-run this script')
  }
}

// ── step 4: cordis.patch.yml ───────────────────────────────────────────────

function patchSection(command, includeDefault) {
  const lines = [
    SECTION_START,
    '# Kimi Code CLI as an ACP subagent provider (host plane).',
    '# - insert: form is REQUIRED for new rows — a bare `- id:` row only',
    '#   overrides an existing entry (the loader warns "entry not found").',
    '- insert:',
    '    - id: subagent-kimi',
    "      name: '@deepseek-ai/dsh-subagent-acp'",
    '      config:',
    '        providerName: kimi',
    `        command: ${yamlQuote(command)}`,
    '        args:',
    '          - acp',
    "        permission: allow   # auto-approve the child's permission prompts",
  ]
  if (includeDefault) {
    lines.push('', '# Make the `kimi` preset the default for new agents/sessions.', '- id: agent-presets', '  config:', '    default: kimi')
  }
  lines.push(SECTION_END)
  return lines.join('\n') + '\n'
}

function writePatch(command) {
  const existing = read(PATCH_FILE) ?? ''
  if (/insert:\s*\n\s*- id: subagent-kimi/.test(existing)) {
    out.ok('cordis.patch.yml already mounts the `kimi` provider (insert form)')
    return
  }
  if (/^\s*- id: subagent-kimi\s*$/m.test(existing)) {
    out.warn('cordis.patch.yml contains a BARE `- id: subagent-kimi` row, which the loader treats as an override of a missing entry — it will NOT mount. Remove it and re-run this script.')
    return
  }

  const section = patchSection(command, flags.defaultPreset)
  const body = existing.split('\n').filter((l) => l.trim() !== '' && !l.trim().startsWith('#')).join('\n').trim()
  const stockTemplate = body === '' || body === '[]'
  let next
  if (stockTemplate) {
    next = `# Your patch layer for this dsh profile, applied after every bundle layer:\n# a top-level YAML array of loader patch entries (id-targeted config\n# overrides, disables, and insert lists; \`!!js\` expressions allowed).\n\n${section}`
  } else {
    next = existing.replace(/\s*$/, '') + '\n\n' + section
  }
  if (flags.dryRun) { out.info(`(dry-run) would write ${PATCH_FILE}`); return }
  writeFileSync(PATCH_FILE, next)
  out.ok(`patched ${PATCH_FILE}`)
}

// ── step 5: kimi agent preset ──────────────────────────────────────────────

const TOOL_ROW = `
    # Kimi Code CLI delegation via the \`kimi\` ACP provider (registered by the
    # \`subagent-kimi\` host row in the profile patch). \`maxDepth\` is
    # provider-managed because the ACP provider cannot enforce a depth limit
    # inside the out-of-process child.
    - id: tool-subagent-kimi
      name: '@deepseek-ai/dsh-tool-subagent'
      config:
        provider: kimi
        toolName: subagent_kimi
        backgroundMode: one-shot
        maxDepth: provider-managed
`

function standardPresetSource(dshDir) {
  const p = join(dshDir, 'config', 'agent-presets', 'standard', 'agent.cordis.yml')
  return existsSync(p) ? p : undefined
}

function writePreset(dshDir) {
  const src = standardPresetSource(dshDir)
  if (!src) {
    out.fail(`cannot find the shipped standard preset under ${dshDir}/config/agent-presets — unexpected harness layout; see dsh/docs/KIMI-INTEGRATION.md for the manual steps`)
    return
  }
  if (read(PRESET_FILE)?.includes('tool-subagent-kimi')) {
    out.ok(`preset already contains the subagent_kimi tool (${PRESET_FILE})`)
    return
  }
  const marker = '\n    - id: workflow-worker-thread'
  const base = read(src)
  if (!base.includes(marker)) {
    out.fail(`the standard preset ${src} lacks the delegation-group marker "- id: workflow-worker-thread" — cannot auto-insert the tool row; see dsh/docs/KIMI-INTEGRATION.md`)
    return
  }
  if (flags.dryRun) { out.info(`(dry-run) would write ${PRESET_FILE} (from ${src})`); return }
  mkdirSync(PRESET_DIR, { recursive: true })
  writeFileSync(PRESET_FILE, base.replace(marker, TOOL_ROW + marker, 1))
  out.ok(`created ${PRESET_FILE} (copy of the standard preset + subagent_kimi tool)`)
}

// ── step 6: harness settings (default model + provider profiles) ───────────

/**
 * The NVIDIA (build.nvidia.com, free tier) provider profile: the 18 models
 * from the installed pi-ai catalog plus the useful free chat models from the
 * live NVIDIA API, incl. `moonshotai/kimi-k3` (NVIDIA's free Kimi K3 — kept
 * distinct from the subscription `kimi-coding/k3`). Metadata for the extra
 * entries is conservative; tune contextWindow/maxTokens per model if needed.
 */
const NVIDIA_PROFILE = {
  displayName: 'NVIDIA (free tier)',
  api: 'openai-completions',
  baseURL: 'https://integrate.api.nvidia.com/v1',
  apiKeyEnv: 'NVIDIA_API_KEY',
  models: [
    { id: 'meta/llama-3.1-70b-instruct', name: 'Llama 3.1 70B', contextWindow: 128000, maxTokens: 4096, input: ['text'] },
    { id: 'meta/llama-3.1-8b-instruct', name: 'Llama 3.1 8B', contextWindow: 16000, maxTokens: 4096, input: ['text'] },
    { id: 'meta/llama-3.2-11b-vision-instruct', name: 'Llama 3.2 11B Vision', contextWindow: 128000, maxTokens: 4096, input: ['text', 'image'] },
    { id: 'meta/llama-3.2-90b-vision-instruct', name: 'Llama 3.2 90B Vision', contextWindow: 128000, maxTokens: 8192, input: ['text', 'image'] },
    { id: 'meta/llama-3.3-70b-instruct', name: 'Llama 3.3 70B', contextWindow: 128000, maxTokens: 4096, input: ['text'] },
    { id: 'minimaxai/minimax-m3', name: 'MiniMax M3', contextWindow: 1000000, maxTokens: 16384, input: ['text'] },
    { id: 'mistralai/mistral-small-4-119b-2603', name: 'Mistral Small 4 119B', contextWindow: 128000, maxTokens: 8192, input: ['text'] },
    { id: 'moonshotai/kimi-k2.6', name: 'Kimi K2.6 (NVIDIA free)', contextWindow: 262144, maxTokens: 262144, input: ['text'] },
    { id: 'nvidia/nemotron-3-nano-30b-a3b', name: 'Nemotron 3 Nano 30B', contextWindow: 131072, maxTokens: 131072, input: ['text'] },
    { id: 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning', name: 'Nemotron 3 Nano Omni 30B', contextWindow: 256000, maxTokens: 65536, input: ['text'] },
    { id: 'nvidia/nemotron-3-super-120b-a12b', name: 'Nemotron 3 Super 120B', contextWindow: 262144, maxTokens: 262144, input: ['text'] },
    { id: 'nvidia/nemotron-3-ultra-550b-a55b', name: 'Nemotron 3 Ultra 550B', contextWindow: 1000000, maxTokens: 65536, input: ['text'] },
    { id: 'nvidia/nvidia-nemotron-nano-9b-v2', name: 'Nemotron Nano 9B v2', contextWindow: 131072, maxTokens: 131072, input: ['text'] },
    { id: 'openai/gpt-oss-120b', name: 'GPT-OSS 120B', contextWindow: 128000, maxTokens: 8192, input: ['text'] },
    { id: 'openai/gpt-oss-20b', name: 'GPT-OSS 20B', contextWindow: 131072, maxTokens: 32768, input: ['text'] },
    { id: 'stepfun-ai/step-3.5-flash', name: 'Step 3.5 Flash', contextWindow: 256000, maxTokens: 16384, input: ['text'] },
    { id: 'stepfun-ai/step-3.7-flash', name: 'Step 3.7 Flash', contextWindow: 256000, maxTokens: 16384, input: ['text'] },
    { id: 'z-ai/glm-5.2', name: 'GLM 5.2', contextWindow: 1000000, maxTokens: 131072, input: ['text'] },
    { id: 'moonshotai/kimi-k3', name: 'Kimi K3 (NVIDIA free)', contextWindow: 262144, maxTokens: 131072, input: ['text'] },
    { id: 'deepseek-ai/deepseek-v4-flash-0731', name: 'DeepSeek V4 Flash (NVIDIA free)', contextWindow: 131072, maxTokens: 16384, input: ['text'] },
    { id: 'deepseek-ai/deepseek-v4-pro-0813', name: 'DeepSeek V4 Pro (NVIDIA free)', contextWindow: 131072, maxTokens: 32768, input: ['text'] },
    { id: 'google/gemma-3-12b-it', name: 'Gemma 3 12B', contextWindow: 131072, maxTokens: 8192, input: ['text'] },
    { id: 'google/gemma-3-4b-it', name: 'Gemma 3 4B', contextWindow: 131072, maxTokens: 8192, input: ['text'] },
    { id: 'google/gemma-4-31b-it', name: 'Gemma 4 31B', contextWindow: 131072, maxTokens: 16384, input: ['text'] },
    { id: 'nvidia/llama-3.1-nemotron-70b-instruct', name: 'Llama 3.1 Nemotron 70B', contextWindow: 131072, maxTokens: 16384, input: ['text'] },
    { id: 'nvidia/nemotron-4-340b-instruct', name: 'Nemotron 4 340B', contextWindow: 131072, maxTokens: 8192, input: ['text'] },
    { id: 'nvidia/nemotron-3.5-lightning-30b-a3b', name: 'Nemotron 3.5 Lightning 30B', contextWindow: 131072, maxTokens: 16384, input: ['text'] },
    { id: 'mistralai/mistral-large', name: 'Mistral Large', contextWindow: 131072, maxTokens: 8192, input: ['text'] },
    { id: 'mistralai/mistral-large-2-instruct', name: 'Mistral Large 2', contextWindow: 131072, maxTokens: 8192, input: ['text'] },
    { id: 'mistralai/mistral-nemotron', name: 'Mistral Nemotron', contextWindow: 131072, maxTokens: 8192, input: ['text'] },
  ],
}

/**
 * Ensure the harness settings make this machine behave like the known-good
 * configuration: the `kimi-coding` provider profile exists, the `nvidia`
 * free-tier profile exists, and the default agent model is
 * `kimi-coding / k3` (Kimi K3, 1M context). Idempotent — preserves every
 * other key in settings.yaml.
 */
function writeSettings() {
  const settingsFile = join(DSH_HOME, 'settings.yaml')
  const yaml = jsYaml()
  const text = read(settingsFile)
  let doc = text === undefined ? {} : yaml.load(text)
  if (typeof doc !== 'object' || doc === null || Array.isArray(doc)) {
    out.fail(`${settingsFile} is not a mapping — refusing to touch it`)
    return
  }
  const next = structuredClone(doc)

  // provider profiles for the pi-ai routes
  next['llm-pi-ai'] ??= {}
  next['llm-pi-ai'].providers ??= {}
  if (!next['llm-pi-ai'].providers['kimi-coding']) {
    next['llm-pi-ai'].providers['kimi-coding'] = {}
  }
  if (JSON.stringify(next['llm-pi-ai'].providers['nvidia']) !== JSON.stringify(NVIDIA_PROFILE)) {
    next['llm-pi-ai'].providers['nvidia'] = NVIDIA_PROFILE
  }

  // default agent model
  const currentModel = next['agent-default-model']
  const desiredModel = { provider: 'kimi-coding', model: 'k3' }
  const sameModel = currentModel !== undefined &&
    currentModel.provider === desiredModel.provider &&
    currentModel.model === desiredModel.model
  if (!sameModel && flags.defaultModel) {
    next['agent-default-model'] = desiredModel
  }

  const changed = JSON.stringify(next) !== JSON.stringify(doc)
  if (!changed) {
    out.ok(`settings already match the known-good config (${settingsFile})`)
    return
  }
  if (flags.dryRun) {
    out.info('(dry-run) would write settings.yaml: ' + JSON.stringify(next))
    return
  }
  writeFileSync(settingsFile, yaml.dump(next))
  out.ok(`wrote ${settingsFile} (default model kimi-coding/k3, provider profile kimi-coding)`)
}

// ── main ───────────────────────────────────────────────────────────────────

function main() {
  console.log('Kimi Code integration — DeepSeek Harness setup')
  console.log(`  DSH_HOME : ${DSH_HOME}`)
  console.log(`  profile  : ${PROFILE_DIR}`)
  console.log(`  mode     : ${flags.dryRun ? 'DRY-RUN (no writes)' : 'apply'}${flags.defaultPreset ? '' : ' (default preset NOT changed)'}`)

  if (!existsSync(PROFILE_DIR)) {
    out.fail(`profile ${PROFILE_DIR} does not exist — start the harness once first (e.g. \`dsh --profile ${PROFILE}\`) so it initializes`)
    return
  }

  // 1. Kimi binary
  out.step('1/6  Kimi Code CLI')
  const kimi = locateKimi()
  if (!kimi) {
    out.fail('kimi not found on PATH or in ~/.kimi-code/bin — install it first (https://github.com/MoonshotAI/kimi-code), then run `kimi login`')
  } else {
    out.ok(`kimi at ${kimi}`)
    const v = run(kimi, ['--version'], { stdio: ['ignore', 'pipe', 'ignore'] })
    if (v.status === 0) out.info(`version: ${v.stdout.trim()}`)
    if (!existsSync(join(HOME, '.kimi-code', 'config.toml'))) {
      out.warn('no ~/.kimi-code/config.toml found — run `kimi login` (or start `kimi` once) so the ACP child can authenticate')
    }
  }

  // 2. Harness install + version
  out.step('2/6  Harness install')
  const dshDir = findDsh()
  const harnessVersion = dshDir ? pkgVersion(join(dshDir, 'package.json')) : undefined
  if (dshDir) out.ok(`dsh at ${dshDir} (version ${harnessVersion ?? 'unknown'})`)
  else out.warn('could not locate the @deepseek-ai/dsh install — package install still attempted')
  if (harnessVersion && harnessVersion !== '0.1.1-rc.2') {
    out.warn(`harness version ${harnessVersion} — the bridge is version-matched; the script will try ${harnessVersion} and fail loudly if it is not published`)
  }

  // 3. Packages
  out.step('3/6  ACP bridge packages')
  const bridgeVersion = harnessVersion ?? '0.1.1-rc.2'
  ensurePackage(BRIDGE, bridgeVersion, BRIDGE_PKG)
  ensurePackage(SDK, '0.25.1', SDK_PKG)
  verifyBridge()

  // 4. Profile patch
  out.step('4/6  Profile patch (cordis.patch.yml)')
  if (!kimi) out.fail('skipping patch — kimi binary not resolved')
  else writePatch(kimi)

  // 5. Preset
  out.step('5/6  Agent preset')
  if (dshDir) writePreset(dshDir)
  else out.fail('skipping preset — dsh install not located')

  // 6. Harness settings (default model + provider profile)
  out.step('6/6  Harness settings (default model)')
  writeSettings()

  // Next steps
  console.log('\n────────────────────────────────────────────────────')
  console.log('Next steps:')
  console.log('  1. Restart the harness GUI (stop `dsh web`, start it again).')
  console.log('  2. Start a NEW session (it uses the `kimi` preset, default model')
  console.log('     kimi-coding/k3) and confirm `subagent_kimi` is in the tool catalog.')
  console.log('  3. Per-machine secrets (never committed): run `npm run dsh:kimi-login`')
  console.log('     (subscription credential) and set any API keys in the GUI.')
}

try {
  main()
} catch (error) {
  console.error(`setup failed: ${error.stack ?? error}`)
  process.exitCode = 1
}
