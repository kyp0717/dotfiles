#!/usr/bin/env node
/**
 * bridge-kimi-token.mjs — use your Kimi Code CLI *subscription* inside the
 * harness's main agent loop.
 *
 * The harness's `kimi-coding` provider (api.kimi.com/coding — the same backend
 * the Kimi Code CLI uses) supports the OAuth subscription flow ("Sign in with
 * Kimi Code"), but this dsh build has no GUI button or command that starts it.
 * This script bridges the OAuth tokens your CLI already holds (from
 * `kimi login`, stored in ~/.kimi-code/credentials/kimi-code.json) into the
 * harness credential store (~/.dsh/.credentials.yaml) under the record the
 * harness's pi-ai adapter reads: `llm-pi-ai/kimi-coding`, kind "grant".
 *
 * Result: the harness's `kimi-coding` provider authenticates with your
 * subscription — no pay-as-you-go KIMI_API_KEY.
 *
 * Usage:
 *   node dsh/scripts/bridge-kimi-token.mjs [--dry-run] [--verify] [--kimi-credentials <path>]
 *
 * Safety notes (verified against auth.kimi.com):
 *   - The refresh-token reuse test passed, so the harness refreshing tokens in
 *     the background does NOT invalidate the CLI's own stored tokens.
 *   - Tokens are never printed. The CLI token file is never modified.
 */

import { existsSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import {
  CREDENTIALS_FILE, DSH_HOME, KIMI_RECORD_KEY, expanded, findDsh,
  importFromDsh, jsYaml, pkgVersion, read,
} from './lib.mjs'

const flags = {
  dryRun: process.argv.includes('--dry-run'),
  verify: process.argv.includes('--verify'),
  model: (() => {
    const i = process.argv.indexOf('--model')
    return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : 'kimi-for-coding'
  })(),
  kimiCredentials: (() => {
    const i = process.argv.indexOf('--kimi-credentials')
    return i >= 0 && process.argv[i + 1] ? expanded(process.argv[i + 1]) : undefined
  })(),
}

const out = {
  ok: (msg) => console.log(`  ✓ ${msg}`),
  info: (msg) => console.log(`  · ${msg}`),
  warn: (msg) => console.log(`  ! ${msg}`),
  fail: (msg) => { console.error(`  ✗ ${msg}`); process.exitCode = 1 },
}

const DEFAULT_KIMI_CREDENTIALS = join(process.env.HOME ?? process.env.USERPROFILE, '.kimi-code', 'credentials', 'kimi-code.json')

/** Read the CLI's stored OAuth tokens (structure only — never printed). */
function readKimiTokens(file) {
  const raw = read(file)
  if (raw === undefined) {
    throw new Error(`cannot read ${file} — run \`kimi login\` once on this machine first`)
  }
  const d = JSON.parse(raw)
  for (const key of ['access_token', 'refresh_token', 'expires_at']) {
    if (typeof d[key] !== 'string' && typeof d[key] !== 'number') {
      throw new Error(`${file} is missing "${key}" — unexpected format (was this created by a newer kimi?)`)
    }
  }
  const expiresAt = Number(d.expires_at)
  if (!Number.isFinite(expiresAt)) throw new Error(`${file} has a non-numeric expires_at`)
  // CLI stores expires_at in seconds; pi-ai expects epoch milliseconds.
  const expires = expiresAt < 1e11 ? expiresAt * 1000 : expiresAt
  return {
    access: String(d.access_token),
    refresh: String(d.refresh_token),
    expires,
  }
}

/**
 * Fail loudly if the CLI's refresh token is already dead, instead of storing
 * a credential the harness would reject on first use. One refresh call is
 * harmless: kimi's auth server tolerates refresh-token reuse (verified), and
 * if it is already invalid nothing is lost.
 */
async function assertKimiTokenUsable(refreshToken) {
  const response = await fetch('https://auth.kimi.com/api/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json' },
    body: new URLSearchParams({
      client_id: '17e5f671-d194-4dfb-9706-5516cb48c098',
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
    }).toString(),
    signal: AbortSignal.timeout(30_000),
  })
  if (response.ok) return
  let detail = ''
  try {
    const json = await response.json()
    detail = json.error_description ?? json.error ?? ''
  } catch { /* keep generic detail */ }
  throw new Error(
    `the CLI's refresh token is rejected by auth.kimi.com (HTTP ${response.status}${detail ? `: ${detail}` : ''}) — ` +
    'run `kimi login` once on this machine first, then re-run this script',
  )
}

/** The pi-ai OAuth credential record the harness store holds verbatim. */
function oauthPayload(tokens) {
  return { type: 'oauth', access: tokens.access, refresh: tokens.refresh, expires: tokens.expires }
}

/** Load the harness credentials document, or an empty v1 skeleton. */
function loadDocument(yaml) {
  const text = read(CREDENTIALS_FILE)
  if (text === undefined) return { version: 1, refs: {}, records: {} }
  const doc = yaml.load(text)
  if (typeof doc !== 'object' || doc === null || Array.isArray(doc)) {
    throw new Error(`${CREDENTIALS_FILE} is not a mapping — refusing to touch it`)
  }
  const next = { ...doc }
  next.version = 1
  next.refs = doc.refs ?? {}
  next.records = doc.records ?? {}
  return next
}

/**
 * A minimal pi-ai CredentialStore backed by the harness credentials file —
 * used only for the --verify request. Reads and (on refresh) writes the same
 * record the harness reads, so the verification exercises the real path.
 */
function fileCredentialStore(yaml) {
  return {
    async read(providerId) {
      if (providerId !== 'kimi-coding') return undefined
      const doc = loadDocument(yaml)
      const record = doc.records[KIMI_RECORD_KEY]
      return record?.kind === 'grant' ? record.payload : undefined
    },
    async list() {
      const doc = loadDocument(yaml)
      return Object.entries(doc.records ?? {})
        .filter(([, record]) => record?.kind === 'grant')
        .map(([key]) => ({ providerId: key.split('/').pop(), type: 'oauth' }))
    },
    async modify(providerId, mutate) {
      if (providerId !== 'kimi-coding') return undefined
      const current = await this.read(providerId)
      const next = await mutate(current)
      if (next === undefined) return undefined
      const doc = loadDocument(yaml)
      doc.records[KIMI_RECORD_KEY] = { kind: 'grant', payload: next }
      writeFileSync(CREDENTIALS_FILE, yaml.dump(doc))
      return next
    },
    async delete(providerId) {
      if (providerId !== 'kimi-coding') return
      const doc = loadDocument(yaml)
      delete doc.records[KIMI_RECORD_KEY]
      writeFileSync(CREDENTIALS_FILE, yaml.dump(doc))
    },
  }
}

/**
 * Real request through pi-ai's own stack (the exact code path the harness
 * uses: anthropic-messages API + OAuth resolution/refresh) against
 * kimi-coding/kimi-for-coding. Costs a few tokens of subscription quota.
 */
async function verifyWithPiAi() {
  const yaml = jsYaml()
  let piAi
  try {
    piAi = await importFromDsh('@earendil-works/pi-ai')
  } catch {
    throw new Error('cannot resolve @earendil-works/pi-ai from the harness install')
  }
  const models = piAi.createModels({
    credentials: fileCredentialStore(yaml),
    authContext: { env: async () => undefined, fileExists: () => false },
  })
  try {
    const all = await importFromDsh('@earendil-works/pi-ai/providers/all')
    const provider = all.builtinProviders().find((p) => p.id === 'kimi-coding')
    if (provider) models.setProvider(provider)
  } catch { /* provider set below via getModel fallback */ }

  const model = models.getModel('kimi-coding', flags.model)
  if (!model) throw new Error(`kimi-coding/${flags.model} not found in the pi-ai catalog`)
  const message = await models.completeSimple(model, {
    messages: [{ role: 'user', content: [{ type: 'text', text: 'Reply with exactly: OK' }] }],
  }, { maxTokens: 32 })
  const text = message.content
    .filter((block) => block.type === 'text')
    .map((block) => block.text)
    .join('')
    .trim()
  out.ok(`pi-ai request succeeded on kimi-coding/${flags.model} — model replied: ${JSON.stringify(text.slice(0, 80))}`)
}

async function main() {
  console.log('Kimi subscription token bridge — DeepSeek Harness')
  console.log(`  credentials file : ${CREDENTIALS_FILE}`)
  console.log(`  record key       : ${KIMI_RECORD_KEY}`)
  console.log(`  mode             : ${flags.dryRun ? 'DRY-RUN (no writes)' : 'apply'}`)

  const yaml = jsYaml()
  const kimiFile = flags.kimiCredentials ?? DEFAULT_KIMI_CREDENTIALS
  let tokens
  try {
    tokens = readKimiTokens(kimiFile)
    out.ok(`read CLI tokens from ${kimiFile}`)
  } catch (error) {
    out.fail(error.message)
    return
  }

  out.info('checking the CLI token is still accepted by auth.kimi.com…')
  try {
    await assertKimiTokenUsable(tokens.refresh)
    out.ok('CLI token is valid')
  } catch (error) {
    out.fail(error.message)
    out.info('recommended: use `npm run dsh:kimi-login` instead — it signs the harness in with its own independent subscription credential (does not depend on the CLI login)')
    return
  }

  const payload = oauthPayload(tokens)
  out.info(`access token expires ${new Date(payload.expires).toISOString()} — the harness refreshes automatically after that`)
  out.warn('the harness and the CLI now SHARE one token lineage — if either refreshes and the server rotates, the other can break. Prefer `npm run dsh:kimi-login` for an independent harness credential.')

  const doc = loadDocument(yaml)
  const current = doc.records[KIMI_RECORD_KEY]
  if (current?.kind === 'grant' && JSON.stringify(current.payload) === JSON.stringify(payload)) {
    out.ok(`record ${KIMI_RECORD_KEY} already matches — nothing to write`)
  } else {
    if (current) out.info(`replacing existing ${KIMI_RECORD_KEY} record`)
    if (flags.dryRun) {
      out.info('(dry-run) would write the grant record into the harness credential store')
    } else {
      doc.records[KIMI_RECORD_KEY] = { kind: 'grant', payload }
      writeFileSync(CREDENTIALS_FILE, yaml.dump(doc))
      out.ok(`wrote ${KIMI_RECORD_KEY} into ${CREDENTIALS_FILE}`)
    }
  }

  if (flags.verify) {
    console.log('\n▸ Verifying through the harness\'s pi-ai stack…')
    try {
      await verifyWithPiAi()
      if (process.exitCode === undefined) process.exitCode = 0
    } catch (error) {
      out.fail(`verification failed: ${error.message}`)
      process.exitCode = 1
    }
  } else {
    console.log('\nNext steps:')
    console.log('  1. Restart the harness GUI.')
    console.log('  2. Settings → Models → pick provider `kimi-coding`, model')
    console.log('     `kimi-for-coding` (K2.7 Code) or `k3-256k`, set as default.')
    console.log('  3. Re-run with --verify (or just start a session) to confirm.')
  }
}

try {
  await main()
} catch (error) {
  console.error(`bridge failed: ${error.stack ?? error}`)
  process.exitCode = 1
}
