#!/usr/bin/env node
/**
 * install-skills.mjs — make this repo's skills available everywhere.
 *
 * Repo skills live in `.agents/skills/<name>/SKILL.md` (and optionally
 * `.dsh/skills/`). Sessions whose workspace IS this repo discover them
 * automatically (project roots). This script copies them into the harness
 * USER root (`$DSH_HOME/skills`) so they are also available in every other
 * workspace/project on the machine.
 *
 * Idempotent: only rewrites a skill whose content changed.
 *
 * Usage:
 *   node dsh/scripts/install-skills.mjs [--dry-run]
 */

import { copyFileSync, existsSync, mkdirSync, readdirSync, rmSync } from 'node:fs'
import { join } from 'node:path'
import { DSH_HOME, read } from './lib.mjs'

const flags = { dryRun: process.argv.includes('--dry-run') }

const REPO_ROOT = new URL('../..', import.meta.url).pathname
const SOURCE_ROOTS = [join(REPO_ROOT, '.agents', 'skills'), join(REPO_ROOT, '.dsh', 'skills')]
const USER_SKILL_DIR = join(DSH_HOME, 'skills')

const out = {
  ok: (msg) => console.log(`  ✓ ${msg}`),
  info: (msg) => console.log(`  · ${msg}`),
  warn: (msg) => console.log(`  ! ${msg}`),
}

function listSkills(root) {
  if (!existsSync(root)) return []
  return readdirSync(root, { withFileTypes: true })
    .filter((e) => e.isDirectory() && existsSync(join(root, e.name, 'SKILL.md')))
    .map((e) => e.name)
}

function main() {
  console.log('Skill installer — DeepSeek Harness')
  console.log(`  user skill dir : ${USER_SKILL_DIR}`)
  console.log(`  mode           : ${flags.dryRun ? 'DRY-RUN (no writes)' : 'apply'}`)

  const names = new Set()
  for (const root of SOURCE_ROOTS) for (const name of listSkills(root)) names.add(name)
  if (names.size === 0) {
    out.warn('no skills found under .agents/skills or .dsh/skills')
    return
  }

  if (flags.dryRun) {
    for (const name of [...names].sort()) out.info(`(dry-run) would copy ${name} → ${join(USER_SKILL_DIR, name, 'SKILL.md')}`)
  } else {
    mkdirSync(USER_SKILL_DIR, { recursive: true })
    for (const name of [...names].sort()) {
      const src = (() => {
        for (const root of SOURCE_ROOTS) {
          const p = join(root, name, 'SKILL.md')
          if (existsSync(p)) return p
        }
      })()
      const destDir = join(USER_SKILL_DIR, name)
      const dest = join(destDir, 'SKILL.md')
      if (read(src) === read(dest)) {
        out.info(`${name}: up to date`)
        continue
      }
      mkdirSync(destDir, { recursive: true })
      copyFileSync(src, dest)
      out.ok(`installed ${name} → ${dest}`)
    }
  }

  console.log('\nNext: skills are available via the `skill` tool in any new session (restart the GUI to refresh the catalog).')
  if (flags.dryRun) console.log('(dry-run — nothing was written)')
}

try {
  main()
} catch (error) {
  console.error(`install-skills failed: ${error.stack ?? error}`)
  process.exitCode = 1
}
