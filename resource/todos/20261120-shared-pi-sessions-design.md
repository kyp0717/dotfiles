# 2026-11-20 — Shared pi sessions across woodlawn/linden: design pending

## Open question

Share pi session history (`~/.pi/agent/sessions`, JSONL per session)
between the two machines so `/resume` works on whichever machine is
local that week. User asked about Syncthing and Google storage; no
decision made yet.

## Hard constraints (user-stated 2026-11-20, now in AGENTS.md)

- linden is in CT, woodlawn is in Boston. User alternates weekly.
- Machines are never online at the same time and never share a LAN.
- Therefore any peer-to-peer sync (bare Syncthing, SSHFS, rsync over
  SSH) cannot work without an always-on third point.

## Options ranked

1. **rclone + crypt remote on Google Drive (recommended, $0).**
   Consumer Drive gives 15 GB; sessions are ~76M. Crypt remote encrypts
   transcripts before upload (sessions can contain pasted secrets).
   Flow: pull at session start, push at session end. Needs nothing
   always-on. Caveat: rclone uses Drive's unofficial API, fine at
   personal scale. Per-machine state: `~/.config/rclone` (Drive remote +
   crypt remote + OAuth token + crypt passphrase), never in git.
   Script `pi-sessions-sync push|pull` wrapping `rclone sync`.
   rclone sync is last-writer-wins: never run the same pi session on
   both machines between a push and the next pull.
2. **Leave both desktops powered/online + Syncthing over the internet.**
   No cloud, files stay on own hardware, but depends on residential
   power/internet holding for two weeks in an empty apartment.
3. **Always-on VPS (~$5/mo) as a Syncthing node.** Always works, files
   at rest on someone else's server (unless untrusted-encrypted nodes
   are configured).
4. **GCS (enterprise object storage):** needs GCP project + billing,
   no benefit at this volume. Rejected.
5. **Bare Syncthing between the two machines: does NOT work** (devices
   never overlap in time). Rejected.

## Facts already established

- pi has no built-in sync. Sessions are plain JSONL under
  `~/.pi/agent/sessions/<cwd-bucket>/`.
- Storage location is configurable (`sessionDir` in settings.json,
  `PI_CODING_AGENT_SESSION_DIR`, `--session-dir`), but the sync design
  does not require moving it.
- Never put sessions in git, even a private repo (secrets in
  transcripts).

## When picked up

- Get user's choice (Drive/rclone vs always-on options).
- Implement on both machines with recreate steps in
  `resource/machine-rotation/`.
- Handoff unit per convention; capture lessons learned.
