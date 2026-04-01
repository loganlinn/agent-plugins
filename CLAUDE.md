# agent-plugins

Claude Code plugin marketplace. Each plugin lives in `plugins/<name>/` as an independent, self-contained unit.

## Structure

```
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json      # required manifest
├── CLAUDE.md             # architecture and design rationale
├── README.md             # usage and installation
├── skills/               # auto-discovered skills
├── scripts/              # shared utilities
└── test/                 # bats tests
```

## Conventions

- **Plugin names**: kebab-case, descriptive (`pkgctl`, not `package-controller`).
- **Shell scripts**: `set -euo pipefail`, stderr for diagnostics, stdout for structured output. Format with `shfmt`, lint with `shellcheck`.
- **No external dependencies** in scripts. POSIX shell + bash + the tool's own CLI.
- **Tests**: bats, colocated in `test/` within each plugin. Run all with `mise run test`.
- **Docs**: Each plugin has its own `README.md` (usage) and `CLAUDE.md` (design). Plugin-specific contracts or specs live alongside the code they govern (e.g., `pkg-managers/API.md`).

## Tooling

Managed via `mise.toml` at repo root. Key tasks:

- `mise run test` — run all bats tests across plugins
- `mise run lint` — run hk checks
- `mise run fmt` — auto-fix formatting

## Adding a plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json` with at minimum `{"name": "<name>"}`.
2. Add skills, scripts, hooks, agents as needed.
3. Add tests in `plugins/<name>/test/`.
4. Add a `README.md` and `CLAUDE.md` to the plugin.
