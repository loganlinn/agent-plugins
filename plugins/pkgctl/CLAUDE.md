# pkgctl Design

## Purpose

pkgctl monitors software installed through various package manager channels for available updates. It is a Claude Code plugin designed for periodic, unattended use via `/loop` or `/cron`, with interactive use as a secondary mode.

## Key files

| File | Purpose |
|------|---------|
| [`pkg-managers/API.md`](pkg-managers/API.md) | **Package manager contract specification.** The authoritative reference for script interfaces, output schemas, environment variables, and rules. Read this first when adding or debugging a PM. |
| `skills/check-updates/SKILL.md` | Orchestration instructions for Claude (haiku). |
| `scripts/notify.sh` | Cross-platform desktop notification delivery (`send`, `doctor` subcommands). |
| `scripts/preflight.sh` | PM discovery and notification validation. |

## Architecture

### Plugin-as-contract (asdf-inspired)

The core design is a **pluggable package manager contract**, inspired by [asdf's plugin system](https://asdf-vm.com/plugins/create.html). Each package manager is a directory under `pkg-managers/` containing executable scripts with a uniform interface. The plugin orchestrates these scripts without knowing their internals.

```
pkg-managers/
├── API.md              ← the contract specification
├── brew/
│   └── bin/
│       ├── detect
│       └── check-updates
├── cargo/              ← future
│   └── bin/ ...
```

**Why this over a monolithic skill?**
- Adding a new PM is a self-contained change: drop a directory, implement 2 scripts.
- Each PM's logic is independently testable.
- No orchestration code needs to change when PMs are added or removed.
- Contributors can work on different PMs in parallel without conflicts.

**Why not individual skills per PM?**
- Overly general skill names (`/go`, `/npm`) would collide with other plugins.
- A single `/pkgctl:check-updates [pms]` entry point is simpler for the user.
- Cross-PM aggregation (combined notification) requires a single orchestration point.

### Orchestration layers

```
User invokes /pkgctl:check-updates brew,cargo
        │
        ▼
┌─────────────────┐
│  SKILL.md       │  Claude (haiku) interprets args, runs scripts
│  (orchestrator) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  preflight.sh   │  Resolves PM list, validates notify channel
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│ brew/  │ │ cargo/ │  Per-PM check-updates scripts
│ detect │ │ detect │
│ check  │ │ check  │
└────┬───┘ └────┬───┘
     └────┬─────┘
          ▼
┌─────────────────┐
│  notify.sh      │  Delivers desktop notification
└─────────────────┘
```

Three distinct layers:
1. **SKILL.md** — orchestration logic, expressed as instructions for Claude. Stays lean; no shell logic embedded in markdown.
2. **Shared scripts** (`preflight.sh`, `notify.sh`) — cross-cutting concerns reused by all PMs.
3. **PM scripts** (`pkg-managers/<slug>/bin/*`) — PM-specific logic behind the contract interface defined in [`pkg-managers/API.md`](pkg-managers/API.md).

## Key decisions

### Model: haiku

The skill runs on haiku because the work is mechanical: run scripts, parse output, format summary. No complex reasoning required. This keeps cost and latency low, which matters for periodic `/loop` usage.

### Notification as a shared utility

`scripts/notify.sh` is a dependency-free shell script separate from any PM-specific logic so all current and future skills can share it.

Auto-detects the best available method; users override via `PKGCTL_NOTIFY_METHOD` env var. No config files — environment variables are the simplest portable configuration mechanism for shell scripts.

### Pre-flight diagnostics

`preflight.sh` runs before any PM check. It validates notification delivery (`notify.sh doctor`), resolves the PM list (`*` → detected PMs), and runs each PM's `bin/detect`. Only actionable PM slugs reach stdout.

This ensures graceful failure: missing PMs are skipped silently; if none are found, the skill stops with a clear message.

### Failure isolation

A failure in one PM must not prevent checking others. The SKILL.md instructs Claude to continue checking remaining PMs when one fails, collect all errors, and report them alongside successful results. Critical for unattended `/loop` usage where partial results beat no results.

### No automatic updates

The `update` script is optional and never runs without explicit user confirmation. Unattended package updates can break systems — the skill always notifies first and asks before acting.

### Environment variables over arguments

Scripts receive context via environment variables (`PKGCTL_ROOT`, `PKGCTL_PM_DIR`, `PKGCTL_PM_SLUG`) rather than positional arguments. This keeps the calling convention uniform and extensible — new context can be added without changing existing scripts' argument parsing. See [`pkg-managers/API.md`](pkg-managers/API.md) for the full variable list.

## Extending pkgctl

### Adding a package manager

See [`pkg-managers/API.md`](pkg-managers/API.md) for the full contract. Add tests in `test/<slug>.bats`. The orchestrator discovers new PMs automatically — no registration needed.

### Adding capabilities

New capabilities (e.g., `list-installed`, `pin-version`) are new scripts in `bin/`. Add them to `API.md` as optional scripts, implement in PMs that support them, and update the SKILL.md orchestration instructions.

### Adding notification methods

Add a new case to `notify.sh`'s `detect_method` and dispatch functions. The `PKGCTL_NOTIFY_METHOD` override already supports arbitrary method names.

## Testing

Tests use [bats](https://github.com/bats-core/bats-core) and live in `test/`. Run via `mise run test`.

- **Unit tests per script:** Each script has its own `.bats` file.
- **Skip when PM absent:** Tests that require a specific PM skip gracefully on systems where it's not installed.
- **Contract compliance:** Tests verify output format (tab-separated, correct field count) rather than specific package names.
