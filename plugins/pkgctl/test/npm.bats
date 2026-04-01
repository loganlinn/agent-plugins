#!/usr/bin/env bats

setup() {
	PKGCTL_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export PKGCTL_ROOT
	PM_DIR="$PKGCTL_ROOT/pkg-managers/npm"
	export PKGCTL_PM_DIR="$PM_DIR"
	export PKGCTL_PM_SLUG="npm"
	PKGCTL_PM_CMD="$(PKGCTL_PM_DIR="$PM_DIR" PKGCTL_PM_SLUG="npm" "$PM_DIR/bin/detect" 2>/dev/null)" || true
	export PKGCTL_PM_CMD
}

@test "npm/detect: exits 0 when npm is available" {
	command -v npm &>/dev/null || skip "npm not installed"
	run "$PM_DIR/bin/detect"
	[[ $status -eq 0 ]]
	[[ -n "$output" ]]
}

@test "npm/check-updates: exits 0" {
	command -v npm &>/dev/null || skip "npm not installed"
	run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
}

@test "npm/check-updates: output is tab-separated with 3 fields" {
	command -v npm &>/dev/null || skip "npm not installed"
	run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
	if [[ -n "$output" ]]; then
		while IFS= read -r line; do
			tab_count="$(tr -cd '\t' <<<"$line" | wc -c | tr -d ' ')"
			[[ "$tab_count" -eq 2 ]]
		done <<<"$output"
	fi
}
