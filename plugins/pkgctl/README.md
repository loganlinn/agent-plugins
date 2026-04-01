# pkgctl

Monitor installed software for available updates across package managers.

## Skills

| Skill | Description |
|-------|-------------|
| `/pkgctl:check-updates [pms]` | Check for outdated packages and notify. Argument is a comma-separated list of PM slugs (default: all detected). |

## Package Managers

Each package manager lives in `pkg-managers/<slug>/` and conforms to the contract in [`pkg-managers/API.md`](pkg-managers/API.md).

| Slug | Tool | Status |
|------|------|--------|
| `brew` | Homebrew | Implemented |
| `cargo` | cargo install | Implemented |
| `go` | go install | Implemented |
| `uv` | uv tool | Implemented |
| `npm` | npm -g | Implemented |
| `mise` | mise -g | Implemented |
| `nix` | nix flake | Implemented (requires `PKGCTL_FLAKE_REF`) |

## Notifications

Desktop notifications are delivered via `scripts/notify.sh`, which auto-detects the platform (macOS `osascript`, Linux `notify-send`). Override with `PKGCTL_NOTIFY_METHOD` environment variable.

Verify delivery works: `scripts/notify.sh doctor`

## Usage with /loop

```
/loop 30m /pkgctl:check-updates
/loop 1h /pkgctl:check-updates brew,cargo
```

## Contributing

- To add a package manager, see [`pkg-managers/API.md`](pkg-managers/API.md).
- For architecture and design rationale, see [`CLAUDE.md`](CLAUDE.md).
