#!/usr/bin/env node
/**
 * kimi-login.mjs — sign the harness into Kimi For Coding with your
 * SUBSCRIPTION, using its own independent device-code OAuth credential.
 *
 * Why this exists: the harness's `kimi-coding` provider supports the Kimi Code
 * subscription OAuth flow ("Sign in with Kimi Code"), but no dsh build exposes
 * a GUI button or command to start it. This script runs that flow directly
 * (RFC 8628 against auth.kimi.com, same official client id as the CLI) and
 * stores the resulting credential in the harness store under
 * `llm-pi-ai/kimi-coding` — the record the harness reads.
 *
 * Crucially this gives the harness an INDEPENDENT token lineage: the harness
 * refreshing its own tokens can no longer invalidate your CLI's login
 * (sharing one lineage between the CLI and the harness is what broke the
 * previous bridge setup — see the OAuth refresh troubleshooting in SETUP.md).
 *
 * Usage:
 *   node dsh/scripts/kimi-login.mjs
 *
 * It prints a URL + code; open the URL in your browser (signed in with your
 * Kimi subscription account) and enter the code. The script polls until the
 * login completes, then writes the credential and exits. Tokens are never
 * printed.
 */

import { writeFileSync } from 'node:fs'
import { CREDENTIALS_FILE, KIMI_RECORD_KEY, jsYaml, read } from './lib.mjs'

const CLIENT_ID = '17e5f671-d194-4dfb-9706-5516cb48c098'
const OAUTH_HOST = process.env.KIMI_OAUTH_HOST || 'https://auth.kimi.com'
const DEVICE_TIMEOUT_MS = 15 * 60 * 1000

const out = {
  ok: (msg) => console.log(`  ✓ ${msg}`),
  info: (msg) => console.log(`  · ${msg}`),
  fail: (msg) => { console.error(`  ✗ ${msg}`); process.exitCode = 1 },
}

async function postForm(path, body) {
  const response = await fetch(`${OAUTH_HOST}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json' },
    body: new URLSearchParams(body).toString(),
    signal: AbortSignal.timeout(30_000),
  })
  const text = await response.text()
  let json = null
  try { json = JSON.parse(text) } catch { /* non-JSON body */ }
  return { status: response.status, json, text }
}

async function startDeviceAuthorization() {
  const { status, json } = await postForm('/api/oauth/device_authorization', { client_id: CLIENT_ID })
  if (status !== 200 || !json?.device_code || !json?.user_code || !json?.verification_uri) {
    throw new Error(`device authorization failed (HTTP ${status}): ${json ? JSON.stringify(json).slice(0, 200) : 'no JSON'}`)
  }
  return {
    deviceCode: json.device_code,
    userCode: json.user_code,
    verificationUri: json.verification_uri,
    verificationUriComplete: json.verification_uri_complete,
    intervalSeconds: Number.isFinite(json.interval) && json.interval > 0 ? json.interval : 5,
  }
}

async function pollForToken(device) {
  const started = Date.now()
  let intervalMs = device.intervalSeconds * 1000
  while (Date.now() - started < DEVICE_TIMEOUT_MS) {
    await new Promise((resolve) => setTimeout(resolve, intervalMs))
    const { status, json } = await postForm('/api/oauth/token', {
      client_id: CLIENT_ID,
      device_code: device.deviceCode,
      grant_type: 'urn:ietf:params:oauth:grant-type:device_code',
    })
    if (status >= 500) continue
    if (status === 200 && json?.access_token && json?.refresh_token && Number.isFinite(json.expires_in)) {
      return {
        access: json.access_token,
        refresh: json.refresh_token,
        expires: Date.now() + json.expires_in * 1000,
      }
    }
    const error = json?.error
    if (error === 'authorization_pending') continue
    if (error === 'slow_down') {
      intervalMs += 5_000
      continue
    }
    if (error === 'expired_token') throw new Error('the login link expired — run the script again')
    if (error === 'access_denied') throw new Error('login was denied in the browser')
    throw new Error(`token polling failed (HTTP ${status}): ${json ? JSON.stringify(json).slice(0, 200) : 'no JSON'}`)
  }
  throw new Error('timed out waiting for you to complete the login — run the script again')
}

function loadDocument(yaml) {
  const text = read(CREDENTIALS_FILE)
  if (text === undefined) return { version: 1, refs: {}, records: {} }
  const doc = yaml.load(text)
  if (typeof doc !== 'object' || doc === null || Array.isArray(doc)) {
    throw new Error(`${CREDENTIALS_FILE} is not a mapping — refusing to touch it`)
  }
  return { ...doc, version: 1, refs: doc.refs ?? {}, records: doc.records ?? {} }
}

async function main() {
  console.log('Kimi For Coding subscription login — DeepSeek Harness')
  console.log('  This creates an INDEPENDENT harness credential (does not touch your CLI login).')

  const yaml = jsYaml()
  const device = await startDeviceAuthorization()
  console.log('\n──────────────────────────────────────────────')
  console.log('  1. Open this URL in your browser:')
  console.log(`     ${device.verificationUriComplete ?? device.verificationUri}`)
  console.log(`  2. Enter this code:  ${device.userCode}`)
  console.log('     (Sign in with the account that has your Kimi subscription.)')
  console.log('──────────────────────────────────────────────\n')
  out.info('waiting for you to authorize… (expires in 15 minutes)')

  const credential = await pollForToken(device)
  const doc = loadDocument(yaml)
  doc.records[KIMI_RECORD_KEY] = { kind: 'grant', payload: { type: 'oauth', ...credential } }
  writeFileSync(CREDENTIALS_FILE, yaml.dump(doc))
  out.ok(`signed in — stored ${KIMI_RECORD_KEY} in ${CREDENTIALS_FILE}`)
  console.log('\nNext: restart the harness GUI, then Settings → Models → kimi-coding / k3.')
  console.log('The harness now refreshes its OWN tokens — your CLI login is unaffected.')
}

main().catch((error) => {
  console.error(`login failed: ${error.message ?? error}`)
  process.exitCode = 1
})
