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

Scripts receive the following environment variables from the orchestrator:

| Variable | Provided to | Description |
|----------|-------------|-------------|
| `PKGCTL_ROOT` | all scripts | Absolute path to the `pkgctl` plugin root directory |
| `PKGCTL_PM_DIR` | all scripts | Absolute path to this package manager's directory |
| `PKGCTL_PM_SLUG` | all scripts | The package manager slug (directory name) |
| `PKGCTL_PM_CMD` | `check-updates`, `update` | Absolute path to the PM executable, as reported by `detect` |

### Per-PM variables

PM-specific configuration uses the naming convention `PKGCTL_<SLUG>_*` where `<SLUG>` is the uppercased slug. Examples:

| Variable | PM | Description |
|----------|-----|-------------|
| `PKGCTL_NIX_FLAKE_REF` | nix | Path or URL to the flake to check |
| `PKGCTL_CARGO_REGISTRY` | cargo | (future) Custom registry URL |

## Required Scripts

### `bin/detect`

Determine whether this package manager is available on the system.

- **Exit 0**: Package manager is available. Print the absolute path to its primary executable on stdout (one line). The orchestrator passes this path to downstream scripts as `PKGCTL_PM_CMD`.
- **Exit 1**: Package manager is not available. May print a reason to stderr.
- **Must not** install anything or modify system state.
- **Must not** produce output on stdout unless exiting 0.

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail
command -v brew || { [[ -x /opt/homebrew/bin/brew ]] && echo /opt/homebrew/bin/brew; } || exit 1
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
- **Must** use `$PKGCTL_PM_CMD` to invoke the package manager, not re-discover it.

Field rules:
- `name`: Package identifier as the PM knows it (e.g., `jq`, `ripgrep`). Must be unique within the output — do not emit duplicate names.
- `current-version`: Currently installed version string. Use `-` if unknown.
- `latest-version`: Latest available version string. Use `-` if unknown.
- Fields must not contain tab or newline characters.
- Follow the PM's default behavior for pre-release versions — do not filter or special-case them.

Example output:

```
jq	1.6	1.7.1
ripgrep	13.0.0	14.1.0
```

### Timeout

The orchestrator may wrap script invocations with `timeout(1)`. Scripts should not implement their own timeout logic. If killed by timeout, partial stdout is discarded — partial TSV is worse than no TSV.

Default timeout: 120 seconds. The orchestrator may adjust this via `PKGCTL_TIMEOUT`.

## Optional Scripts

### `bin/update`

Update one or more packages to their latest versions.

- **Arguments**: Package names to update. If no arguments, update all outdated packages.
- **Stdout**: One line per successfully updated package, tab-separated:
  ```
  <name>\t<old-version>\t<new-version>
  ```
- **Exit 0**: All requested updates succeeded.
- **Exit 1**: One or more updates failed. Stdout contains successfully updated packages. Stderr contains per-package error details.
- **Must** use `$PKGCTL_PM_CMD` to invoke the package manager.

## Rules

1. **No external dependencies.** Scripts must use only POSIX shell, bash, and the package manager's own runtime. For example, npm scripts may use `node` since it ships with npm; cargo scripts may use `cargo metadata`.
2. **No side effects in `detect` or `check-updates`.** These scripts are read-only operations.
3. **No calling other pkgctl scripts.** Each script is self-contained.
4. **Stderr for diagnostics.** Informational messages, warnings, and errors go to stderr. Stdout is reserved for structured output.
5. **Portable paths.** Use `$PKGCTL_ROOT` and `$PKGCTL_PM_DIR` instead of hardcoded paths.
6. **Fail fast.** Use `set -euo pipefail` at the top of every script.
7. **Use `$PKGCTL_PM_CMD`.** Do not re-discover the PM executable in `check-updates` or `update`.

## Adding a New Package Manager

1. Create `pkg-managers/<slug>/bin/detect` and `bin/check-updates` following the schemas above.
2. Make scripts executable: `chmod +x pkg-managers/<slug>/bin/*`.
3. Add tests in `test/<slug>.bats`.
4. Follow the maintenance checklist in [`../CLAUDE.md`](../CLAUDE.md) to update docs and metadata.
