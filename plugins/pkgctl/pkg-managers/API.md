# Package Manager Contract

This document defines the interface that each package manager integration must implement. Adding support for a new package manager means creating a new directory under `pkg-managers/` that conforms to this contract.

For architecture and design rationale behind this contract, see [`../CLAUDE.md`](../CLAUDE.md).

## Directory Structure

```
pkg-managers/<slug>/
└── bin/
    ├── detect           # required
    ├── check-updates    # required
    └── update           # optional
```

`<slug>` is a short, lowercase identifier for the package manager (e.g., `brew`, `cargo`, `nix`).

## Environment Variables

Scripts receive the following environment variables:

| Variable | Description |
|----------|-------------|
| `PKGCTL_ROOT` | Absolute path to the `pkgctl` plugin root directory |
| `PKGCTL_PM_DIR` | Absolute path to this package manager's directory (`pkg-managers/<slug>`) |
| `PKGCTL_PM_SLUG` | The package manager slug (directory name) |

Additional per-PM variables may be set by the user (e.g., `PKGCTL_FLAKE_REF` for nix).

## Required Scripts

### `bin/detect`

Determine whether this package manager is available on the system.

- **Exit 0**: Package manager is available. Print the absolute path to its primary executable on stdout (one line).
- **Exit 1**: Package manager is not available. May print a reason to stderr.
- **Must not** install anything or modify system state.
- **Must not** produce output on stdout unless exiting 0.

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail
command -v brew || { [ -x /opt/homebrew/bin/brew ] && echo /opt/homebrew/bin/brew; } || exit 1
```

### `bin/check-updates`

List installed packages that have a newer version available.

- **Stdin**: None.
- **Stdout**: One outdated package per line, tab-separated fields:
  ```
  <name>\t<current-version>\t<latest-version>
  ```
  If no updates are available, produce no output (empty stdout).
- **Exit 0**: Check completed successfully (even if no updates found).
- **Exit 1**: Check failed. Print error details to stderr.
- **Must not** modify installed packages or system state.

Field rules:
- `name`: Package identifier as the PM knows it (e.g., `jq`, `ripgrep`).
- `current-version`: Currently installed version string. Use `-` if unknown.
- `latest-version`: Latest available version string. Use `-` if unknown.

Example output:

```
jq	1.6	1.7.1
ripgrep	13.0.0	14.1.0
```

## Optional Scripts

### `bin/update`

Update one or more packages to their latest versions.

- **Arguments**: Package names to update. If no arguments, update all outdated packages.
- **Stdout**: One line per updated package, tab-separated:
  ```
  <name>\t<old-version>\t<new-version>
  ```
- **Exit 0**: All requested updates succeeded.
- **Exit 1**: One or more updates failed. Print details to stderr.

## Rules

1. **No external dependencies.** Scripts must use only POSIX shell, bash, and the package manager's own CLI. No Python, Ruby, Node, etc.
2. **No side effects in `detect` or `check-updates`.** These scripts are read-only operations.
3. **No calling other pkgctl scripts.** Each script is self-contained.
4. **Stderr for diagnostics.** Informational messages, warnings, and errors go to stderr. Stdout is reserved for structured output.
5. **Portable paths.** Use `$PKGCTL_ROOT` and `$PKGCTL_PM_DIR` instead of hardcoded paths.
6. **Fail fast.** Use `set -euo pipefail` at the top of every script.

## Adding a New Package Manager

1. Create `pkg-managers/<slug>/bin/detect` and `pkg-managers/<slug>/bin/check-updates`.
2. Make both scripts executable: `chmod +x pkg-managers/<slug>/bin/*`.
3. Follow the output schemas above exactly — the orchestrator parses them.
4. Test locally:
   ```bash
   PKGCTL_ROOT=/path/to/pkgctl PKGCTL_PM_DIR=/path/to/pkgctl/pkg-managers/<slug> PKGCTL_PM_SLUG=<slug> ./pkg-managers/<slug>/bin/detect
   PKGCTL_ROOT=/path/to/pkgctl PKGCTL_PM_DIR=/path/to/pkgctl/pkg-managers/<slug> PKGCTL_PM_SLUG=<slug> ./pkg-managers/<slug>/bin/check-updates
   ```
5. Optionally add `bin/update` for update support.
