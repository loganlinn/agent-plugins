#!/usr/bin/env bats

setup() {
	PKGCTL_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export PKGCTL_ROOT
	PM_DIR="$PKGCTL_ROOT/pkg-managers/nix"
	export PKGCTL_PM_DIR="$PM_DIR"
	export PKGCTL_PM_SLUG="nix"
	PKGCTL_PM_CMD="$(PKGCTL_PM_DIR="$PM_DIR" PKGCTL_PM_SLUG="nix" "$PM_DIR/bin/detect" 2>/dev/null)" || true
	export PKGCTL_PM_CMD
}

@test "nix/detect: exits 0 when nix is available" {
	command -v nix &>/dev/null || skip "nix not installed"
	run "$PM_DIR/bin/detect"
	[[ $status -eq 0 ]]
	[[ -n "$output" ]]
}

@test "nix/check-updates: fails without PKGCTL_NIX_FLAKE_REF" {
	command -v nix &>/dev/null || skip "nix not installed"
	unset PKGCTL_NIX_FLAKE_REF
	run "$PM_DIR/bin/check-updates"
	[[ $status -ne 0 ]]
	[[ "$output" == *"PKGCTL_NIX_FLAKE_REF"* ]]
}

@test "nix/check-updates: exits 0 with valid flake ref" {
	command -v nix &>/dev/null || skip "nix not installed"
	# Use the repo's own flake as test fixture
	repo_root="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
	[[ -f "$repo_root/flake.nix" ]] || skip "no flake.nix in repo root"
	PKGCTL_NIX_FLAKE_REF="$repo_root" run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
}

@test "nix/check-updates: output is tab-separated with 3 fields" {
	command -v nix &>/dev/null || skip "nix not installed"
	repo_root="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
	[[ -f "$repo_root/flake.nix" ]] || skip "no flake.nix in repo root"
	PKGCTL_NIX_FLAKE_REF="$repo_root" run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
	if [[ -n "$output" ]]; then
		while IFS= read -r line; do
			tab_count="$(tr -cd '\t' <<<"$line" | wc -c | tr -d ' ')"
			[[ "$tab_count" -eq 2 ]]
		done <<<"$output"
	fi
}
