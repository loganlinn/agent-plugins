---
name: pkgctl check-updates
description: >-
  This skill should be used when the user asks to "check for updates",
  "check for outdated packages", "check homebrew updates", "check brew updates",
  "are my packages up to date", "what needs updating",
  or mentions checking installed software for available upgrades.
  Currently supports brew; additional package managers (cargo, go, uv, npm, mise, nix)
  can be added via the PM contract in pkg-managers/API.md.
  Does not handle OS-level updates (macOS softwareupdate, apt dist-upgrade).
  Pairs with /loop and /cron for periodic update checking.
model: haiku
argument-hint: "[brew,...]"
allowed-tools: ["Bash", "Read"]
---

# pkgctl: check-updates

Check installed software across package managers for available updates and notify the user.

## Workflow

### 1. Pre-flight

Run the preflight script to discover available package managers and validate notification delivery.
The argument is a comma-separated list of package manager slugs, or `*` (default) for all detected.

```bash
PKGCTL_ROOT="${CLAUDE_PLUGIN_ROOT}" "${CLAUDE_PLUGIN_ROOT}/scripts/preflight.sh" "<requested-pms>"
```

Preflight outputs one actionable PM slug per line to stdout. If it exits non-zero, report the error and stop.

### 2. Check each package manager

For each slug returned by preflight, run the corresponding checker:

```bash
PKGCTL_ROOT="${CLAUDE_PLUGIN_ROOT}" \
PKGCTL_PM_DIR="${CLAUDE_PLUGIN_ROOT}/pkg-managers/<slug>" \
PKGCTL_PM_SLUG="<slug>" \
  "${CLAUDE_PLUGIN_ROOT}/pkg-managers/<slug>/bin/check-updates"
```

Each checker outputs tab-separated lines: `name\tcurrent\tlatest`. Empty output means everything is up to date.

Collect all output, prefixed by PM slug, into a combined result.

### 3. Summarize

If no updates were found across any PM, stop — no notification needed.

Otherwise, compose a concise single-line summary suitable for a desktop notification. Format:

```
N updates available (brew: 3, cargo: 2)
```

### 4. Notify

Send the summary as a desktop notification:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh" send "pkgctl" "<summary>"
```

Also print the full details (per-package breakdown) in the conversation for the user to review.

### 5. Offer to update

If updates were found, offer to apply them. For each PM that has a `bin/update` script,
list the available updates and ask whether to update all or specific packages:

```bash
PKGCTL_ROOT="${CLAUDE_PLUGIN_ROOT}" \
PKGCTL_PM_DIR="${CLAUDE_PLUGIN_ROOT}/pkg-managers/<slug>" \
PKGCTL_PM_SLUG="<slug>" \
  "${CLAUDE_PLUGIN_ROOT}/pkg-managers/<slug>/bin/update" [package-names...]
```

Never update automatically without confirmation. When the user declines or does not respond, stop.

## Package Manager Contract

Each PM lives in `pkg-managers/<slug>/bin/` with scripts conforming to the contract defined in
`${CLAUDE_PLUGIN_ROOT}/pkg-managers/API.md`. Read that file for the full specification when
adding new package managers or debugging checker output.

## Available Package Managers

Discover installed PMs by listing directories under `${CLAUDE_PLUGIN_ROOT}/pkg-managers/`.
Currently implemented: `brew`. See API.md for how to add more.

## Error Handling

- If a PM's `bin/detect` fails, skip it silently (it's simply not installed).
- If a PM's `bin/check-updates` fails (non-zero exit), report the error for that PM but continue checking others.
- If `notify.sh` fails, report the error but still print results in conversation.
- Never let a single PM failure prevent checking the rest.
