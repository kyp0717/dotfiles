/**
 * lib.mjs — shared helpers for the dsh deployment scripts in this repo
 * (setup-kimi.mjs, bridge-kimi-token.mjs). Node-only, no external deps;
 * js-yaml is resolved from the installed harness when needed.
 */

import { spawnSync } from 'node:child_process'
import { createHash } from 'node:crypto'
import {
  copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync,
  renameSync, rmSync,
} from 'node:fs'
import { createRequire } from 'node:module'
import { homedir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

// ── constants ───────────────────────────────────────────────────────────────

export const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url))
// dsh-specific files live under <repo>/dsh/; the repo root is one level up.
export const DSH_DIR = resolve(SCRIPT_DIR, '..')
export const REPO_ROOT = resolve(DSH_DIR, '..')
export const VENDOR_DIR = join(DSH_DIR, 'vendor')
export const NPM_CACHE_DIR = join(DSH_DIR, '.npm-cache')

export const HOME = homedir()
export const DSH_HOME = process.env.DSH_HOME || join(HOME, '.dsh')
export const PROFILE = 'web'
export const PROFILE_DIR = join(DSH_HOME, 'profiles', PROFILE)
export const PROFILE_NODE_MODULES = join(DSH_HOME, 'profiles', 'node_modules')
export const CREDENTIALS_FILE = join(DSH_HOME, '.credentials.yaml')

/** The credential record key the harness's pi-ai adapter reads for kimi-coding. */
export const KIMI_RECORD_KEY = 'llm-pi-ai/kimi-coding'

// ── tiny helpers ────────────────────────────────────────────────────────────

export const expanded = (p) => (p.startsWith('~') ? join(HOME, p.slice(1)) : p)

export function read(p) {
  try { return readFileSync(p, 'utf8') } catch { return undefined }
}

export function run(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { encoding: 'utf8', ...opts })
  if (r.error) throw r.error
  return r
}

export function sha256(file) {
  return createHash('sha256').update(readFileSync(file)).digest('hex')
}

export function pkgVersion(pkgFile) {
  const raw = read(pkgFile)
  if (!raw) return undefined
  try { return JSON.parse(raw).version } catch { return undefined }
}

export function yamlQuote(s) {
  // Double-quoted YAML scalar with minimal escaping — safe for file paths.
  return `"${s.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`
}

export function copyDir(from, to) {
  mkdirSync(to, { recursive: true })
  for (const entry of readdirSync(from, { withFileTypes: true })) {
    const s = join(from, entry.name)
    const d = join(to, entry.name)
    if (entry.isDirectory()) copyDir(s, d)
    else copyFileSync(s, d)
  }
}

/** Extract an npm tarball (single top-level `package/` dir) into `targetDir`. */
export function installFromTarball(tgz, targetDir) {
  const tmp = join(dirname(targetDir), `.tmp-${process.pid}-${Date.now()}`)
  mkdirSync(tmp, { recursive: true })
  try {
    const r = run('tar', ['xzf', tgz, '-C', tmp])
    if (r.status !== 0) throw new Error(`tar extraction failed for ${tgz}: ${r.stderr}`)
    const pkgDir = join(tmp, 'package')
    if (!existsSync(pkgDir)) throw new Error(`tarball ${tgz} has no package/ dir`)
    rmSync(targetDir, { recursive: true, force: true })
    mkdirSync(dirname(targetDir), { recursive: true })
    try { renameSync(pkgDir, targetDir) } catch {
      copyDir(pkgDir, targetDir) // cross-device fallback
      rmSync(pkgDir, { recursive: true, force: true })
    }
  } finally {
    rmSync(tmp, { recursive: true, force: true })
  }
}

// ── discovery ───────────────────────────────────────────────────────────────

/** Locate the Kimi Code CLI binary (PATH first, then common install dirs). */
export function locateKimi() {
  const which = run('bash', ['-lc', 'command -v kimi 2>/dev/null || true'], { stdio: ['ignore', 'pipe', 'ignore'] })
  const onPath = which.stdout?.trim()
  if (onPath) return onPath
  for (const cand of ['~/.kimi-code/bin/kimi', '~/.kimi/bin/kimi']) {
    const p = expanded(cand)
    if (existsSync(p)) return p
  }
  return undefined
}

/** Candidate locations of the @deepseek-ai/dsh install (first match wins). */
export function candidateDshDirs() {
  const list = []
  list.push(join(PROFILE_NODE_MODULES, 'dsh'))
  const npxRoot = join(HOME, '.npm', '_npx')
  if (existsSync(npxRoot)) {
    for (const entry of readdirSync(npxRoot)) {
      list.push(join(npxRoot, entry, 'node_modules', '@deepseek-ai', 'dsh'))
    }
  }
  const g = run('npm', ['root', '-g'], { stdio: ['ignore', 'pipe', 'ignore'] })
  if (g.status === 0 && g.stdout?.trim()) {
    list.push(join(g.stdout.trim(), '@deepseek-ai', 'dsh'))
  }
  return list
}

/** First candidate that is really the @deepseek-ai/dsh package. */
export function findDsh() {
  for (const dir of candidateDshDirs()) {
    const pkg = join(dir, 'package.json')
    if (!existsSync(pkg)) continue
    try {
      if (JSON.parse(readFileSync(pkg, 'utf8')).name === '@deepseek-ai/dsh') return dir
    } catch { /* keep searching */ }
  }
  return undefined
}

/**
 * Resolve a bare module from the harness install (e.g. js-yaml, pi-ai).
 * Tries each candidate dsh dir as the resolution anchor.
 */
export function requireFromDsh(name) {
  for (const dir of candidateDshDirs()) {
    if (!existsSync(join(dir, 'package.json'))) continue
    try {
      return createRequire(join(dir, 'package.json'))(name)
    } catch { /* try the next anchor */ }
  }
  throw new Error(`cannot resolve "${name}" from any @deepseek-ai/dsh install`)
}

/** The js-yaml module from the harness install. */
export function jsYaml() {
  return requireFromDsh('js-yaml')
}

/**
 * Dynamic-import a module from the harness install. Some harness deps (e.g.
 * pi-ai) are ESM-only and expose their entry only under the "import"
 * condition, so CJS `require` fails with ERR_PACKAGE_PATH_NOT_EXPORTED — this
 * finds the package directory (Node's own node_modules walk, same as
 * dsh-app-boot) and imports its entry file directly.
 * @param spec - a package name, optionally with a subpath (e.g.
 *   "@earendil-works/pi-ai/providers/all").
 */
export async function importFromDsh(spec) {
  const { pathToFileURL } = await import('node:url')
  const segments = spec.split('/')
  const packageName = spec.startsWith('@') ? segments.slice(0, 2).join('/') : segments[0]
  const subpath = segments.slice(spec.startsWith('@') ? 2 : 1).join('/')
  for (const dir of candidateDshDirs()) {
    if (!existsSync(join(dir, 'package.json'))) continue
    const req = createRequire(join(dir, 'package.json'))
    for (const searchPath of req.resolve.paths(packageName) ?? []) {
      const pkgDir = join(searchPath, packageName)
      if (!existsSync(join(pkgDir, 'package.json'))) continue
      let entry
      try {
        const pkg = JSON.parse(readFileSync(join(pkgDir, 'package.json'), 'utf8'))
        if (subpath === '') {
          entry = pkg.module ?? pkg.main ?? 'index.js'
        } else {
          const candidates = [
            join('dist', `${subpath}.js`),
            join('dist', subpath, 'index.js'),
          ]
          entry = candidates.find((c) => existsSync(join(pkgDir, c))) ?? subpath
        }
      } catch {
        entry = subpath === '' ? 'index.js' : subpath
      }
      return import(pathToFileURL(join(pkgDir, entry)).href)
    }
  }
  throw new Error(`cannot import "${spec}" from any @deepseek-ai/dsh install`)
}
