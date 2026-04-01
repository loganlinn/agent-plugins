---
name: check-updates
description: >-
  Check installed software for available updates across package managers (brew, cargo, go, uv, npm, mise, nix).
  Use when the user asks to "check for updates", "check outdated packages", "are my packages up to date".
  Pairs with /loop and /cron. Does not handle OS-level updates (softwareupdate, apt dist-upgrade).
model: haiku
argument-hint: "[brew,cargo,go,uv,npm,mise,nix]"
allowed-tools: ["Bash", "Read"]
---

# pkgctl: check-updates

Check installed software across package managers for available updates and notify the user.

## Workflow

### 1. Pre-flight

Run the preflight script to discover available package managers.
The argument is a comma-separated list of package manager slugs, or `*` (default) for all detected.

```bash
PKGCTL_ROOT="${CLAUDE_PLUGIN_ROOT}" "${CLAUDE_PLUGIN_ROOT}/scripts/preflight.sh" "<requested-pms>"
```

Preflight outputs one line per detected PM as `slug\tcommand-path`. If it exits non-zero, report the error and stop.

Parse this output to build the list of PMs and their command paths.

### 2. Check each package manager

For each `slug\tcommand-path` pair from preflight, run the checker with a timeout of 120 seconds:

```bash
PKGCTL_ROOT="${CLAUDE_PLUGIN_ROOT}" \
PKGCTL_PM_DIR="${CLAUDE_PLUGIN_ROOT}/pkg-managers/<slug>" \
PKGCTL_PM_SLUG="<slug>" \
PKGCTL_PM_CMD="<command-path>" \
  timeout 120 "${CLAUDE_PLUGIN_ROOT}/pkg-managers/<slug>/bin/check-updates"
```

Each checker outputs tab-separated lines: `name\tcurrent\tlatest`. Empty output means up to date.
If a checker times out or fails, discard its partial output and report the error, then continue.

Collect all successful output, prefixed by PM slug, into a combined result.

### 3. Summarize

If no updates were found across any PM, stop — no notification needed.

Otherwise, compose a concise single-line summary suitable for a desktop notification. Format:

```
N updates available (brew: 3, cargo: 2)
```

### 4. Notify

First, verify notifications will work:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh" doctor
```

If doctor fails, skip the notification but still print results in conversation.

If doctor succeeds, send the summary:

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
PKGCTL_PM_CMD="<command-path>" \
  "${CLAUDE_PLUGIN_ROOT}/pkg-managers/<slug>/bin/update" [package-names...]
```

Never update automatically without confirmation. When the user declines or does not respond, stop.

## Package Manager Contract

Each PM lives in `pkg-managers/<slug>/bin/` with scripts conforming to the contract defined in
`${CLAUDE_PLUGIN_ROOT}/pkg-managers/API.md`. Read that file for the full specification when
adding new package managers or debugging checker output.

## Available Package Managers

Discover installed PMs by listing directories under `${CLAUDE_PLUGIN_ROOT}/pkg-managers/`.
Currently implemented: `brew`, `cargo`, `go`, `uv`, `npm`, `mise`, `nix`. See API.md for how to add more.

**Note:** The `nix` PM requires `PKGCTL_NIX_FLAKE_REF` to be set (path or URL to a flake). When the
user requests nix without this variable set, ask for the flake reference before proceeding.

## Error Handling

- If a PM's `bin/detect` fails, skip it silently (it's simply not installed).
- If a PM's `bin/check-updates` times out or fails, discard its output, report the error, continue with others.
- If `notify.sh doctor` fails, skip notification but still print results in conversation.
- Never let a single PM failure prevent checking the rest.
