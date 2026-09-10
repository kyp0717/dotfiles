#!/usr/bin/env node
/**
 * import-skills.mjs — import third-party skill collections into the harness.
 *
 * Supports the common open-source skill layouts, all of which are standard
 * SKILL.md format (name/description frontmatter), so they are directly
 * compatible with the harness skill system (model-agnostic):
 *
 *   - <root>/skills/<name>/SKILL.md          (pstack, poteto/how, anthropics/skills, obra/superpowers)
 *   - <root>/.cursor/skills/<name>/SKILL.md  (Cursor-stored skills that are still SKILL.md-based)
 *   - <root>/.claude/skills/<name>/SKILL.md
 *   - <root>/<name>/SKILL.md
 *   - <root>/SKILL.md                        (single-skill repo)
 *   - <root>/<name>.md                       (flat markdown skills)
 *
 * Each skill's whole directory (SKILL.md + references/ + assets) is copied,
 * idempotently: identical content is skipped, a name collision with different
 * content is kept-and-warned unless --force.
 *
 * Usage:
 *   node dsh/scripts/import-skills.mjs [--dest <dir>] [--dry-run] [--force] <git-url-or-dir>...
 *
 * Default dest: $DSH_HOME/skills (the user root — available in every workspace).
 * After importing, restart the harness GUI so new sessions see the catalog.
 */

import { spawnSync } from 'node:child_process'
import {
  copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync,
} from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'
import { DSH_HOME, read } from './lib.mjs'

const flags = {
  dryRun: process.argv.includes('--dry-run'),
  force: process.argv.includes('--force'),
  dest: (() => {
    const i = process.argv.indexOf('--dest')
    return i >= 0 && process.argv[i + 1] ? resolve(process.argv[i + 1]) : join(DSH_HOME, 'skills')
  })(),
}
const sources = process.argv.slice(2).filter((a) => !a.startsWith('--') || a.includes('://'))

const SKILL_NAME = /^[a-z0-9]+(?:-[a-z0-9]+)*$/

const out = {
  ok: (msg) => console.log(`  ✓ ${msg}`),
  info: (msg) => console.log(`  · ${msg}`),
  warn: (msg) => console.log(`  ! ${msg}`),
}

/** Parse YAML frontmatter between leading `---` fences; minimal, tolerant. */
function parseFrontmatter(text) {
  if (!text.startsWith('---')) return undefined
  const end = text.indexOf('\n---', 3)
  if (end < 0) return undefined
  const block = text.slice(3, end)
  const data = {}
  for (const line of block.split('\n')) {
    const m = /^([a-zA-Z0-9-]+):\s*(.*)$/.exec(line.trim())
    if (!m) continue
    let value = m[2].trim()
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1)
    } else if (value.startsWith('>') || value.startsWith('|')) {
      // block scalar — collect following indented lines
      const rest = block.split('\n').slice(block.split('\n').findIndex((l) => l.trim() === line.trim()) + 1)
      const lines = []
      for (const r of rest) {
        if (/^\s{2,}/.test(r)) lines.push(r.trim())
        else break
      }
      value = lines.join(' ').trim()
    }
    data[m[1]] = value
  }
  return data
}

function validSkill(text, source) {
  const fm = parseFrontmatter(text)
  if (!fm) return { ok: false, reason: `${source}: missing YAML frontmatter` }
  if (typeof fm.name !== 'string' || !SKILL_NAME.test(fm.name)) {
    return { ok: false, reason: `${source}: frontmatter name "${fm.name}" must be kebab-case` }
  }
  if (typeof fm.description !== 'string' || fm.description.length === 0) {
    return { ok: false, reason: `${source}: frontmatter requires a description` }
  }
  return { ok: true, name: fm.name, description: fm.description }
}

/** Copy one directory recursively. */
function copyTree(from, to) {
  mkdirSync(to, { recursive: true })
  for (const entry of readdirSync(from, { withFileTypes: true })) {
    const s = join(from, entry.name)
    const d = join(to, entry.name)
    if (entry.isDirectory()) copyTree(s, d)
    else copyFileSync(s, d)
  }
}

/** Scan one root for skill dirs (dir holding SKILL.md) and flat skills. */
function scanRoot(root, found) {
  if (!existsSync(root)) return
  const scanDir = (dir) => {
    if (!existsSync(dir)) return
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue
      const skillFile = join(dir, entry.name, 'SKILL.md')
      if (existsSync(skillFile)) {
        found.push({ dir: join(dir, entry.name), skillFile })
      }
    }
  }
  for (const rel of ['', 'skills', '.cursor/skills', '.claude/skills', '.agents/skills']) {
    scanDir(join(root, rel))
  }
  const single = join(root, 'SKILL.md')
  if (existsSync(single) && !found.some((f) => f.skillFile === single)) {
    found.push({ dir: root, skillFile: single })
  }
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    if (entry.isFile() && entry.name.endsWith('.md') && !/^README/i.test(entry.name)) {
      found.push({ dir: undefined, skillFile: join(root, entry.name) })
    }
  }
}

function main() {
  console.log('Skill importer — DeepSeek Harness')
  console.log(`  dest   : ${flags.dest}`)
  console.log(`  mode   : ${flags.dryRun ? 'DRY-RUN (no writes)' : 'apply'}${flags.force ? ' (--force)' : ''}`)
  console.log(`  sources: ${sources.length ? sources.join(', ') : '(none — nothing to do)'}`)
  if (sources.length === 0) {
    out.warn('pass one or more git URLs or directories')
    return
  }

  const tempDirs = []
  let installed = 0
  let skipped = 0
  let warned = 0

  for (const source of sources) {
    let root = source
    // Support `https://github.com/org/repo#subdir` to import one subtree of a repo.
    let url = source
    let subdir = ''
    if (source.includes('#') && /^(https?|git@|ssh)/.test(source)) {
      ;[url, subdir] = source.split('#')
    }
    if (/^(https?|git@|ssh):\/\//.test(url) || url.startsWith('git@') || /\.git$/.test(url)) {
      const tmp = join(tmpdir(), `skills-import-${process.pid}-${Date.now()}-${installed + skipped}`)
      mkdirSync(tmp, { recursive: true })
      tempDirs.push(tmp)
      out.info(`cloning ${url} …`)
      const r = spawnSync('git', ['clone', '--depth', '1', '--quiet', url, tmp], { stdio: ['ignore', 'pipe', 'pipe'] })
      if (r.status !== 0) {
        out.warn(`clone failed for ${url}: ${(r.stderr ?? '').toString().trim().split('\n')[0]}`)
        continue
      }
      root = subdir ? join(tmp, subdir) : tmp
      if (subdir && !existsSync(root)) {
        out.warn(`subpath "${subdir}" not found in ${url}`)
        continue
      }
    }

    const found = []
    scanRoot(root, found)
    if (found.length === 0) {
      out.warn(`no SKILL.md skills found in ${source}`)
      continue
    }

    for (const skill of found) {
      const text = read(skill.skillFile)
      const check = validSkill(text ?? '', skill.skillFile)
      if (!check.ok) {
        out.warn(`skipped: ${check.reason}`)
        warned++
        continue
      }
      const name = check.name
      const destDir = join(flags.dest, name)
      const destFile = join(destDir, 'SKILL.md')
      if (skill.dir === undefined) {
        // flat skill → keep flat form in dest
        const flatDest = join(flags.dest, `${name}.md`)
        if (read(flatDest) === text) { out.info(`${name}: up to date`); skipped++; continue }
        if (existsSync(flatDest) && !flags.force) { out.warn(`collision: ${name}.md exists with different content — keeping existing (--force to overwrite)`); warned++; continue }
        if (flags.dryRun) { out.info(`(dry-run) would write ${flatDest}`); continue }
        mkdirSync(flags.dest, { recursive: true })
        copyFileSync(skill.skillFile, flatDest)
        out.ok(`imported ${name} → ${flatDest}`)
        installed++
        continue
      }
      if (read(destFile) === text) { out.info(`${name}: up to date`); skipped++; continue }
      if (existsSync(destFile) && !flags.force) { out.warn(`collision: ${name} exists with different content — keeping existing (--force to overwrite)`); warned++; continue }
      if (flags.dryRun) { out.info(`(dry-run) would import ${name} → ${destDir}`); continue }
      rmSync(destDir, { recursive: true, force: true })
      copyTree(skill.dir, destDir)
      out.ok(`imported ${name} → ${destDir}`)
      installed++
    }
  }

  for (const tmp of tempDirs) rmSync(tmp, { recursive: true, force: true })

  console.log(`\nResult: ${installed} imported, ${skipped} up to date, ${warned} skipped/warned`)
  console.log('Next: restart the harness GUI so new sessions pick up the new skills.')
  if (flags.dryRun) console.log('(dry-run — nothing was written)')
}

try {
  main()
} catch (error) {
  console.error(`import-skills failed: ${error.stack ?? error}`)
  process.exitCode = 1
}
