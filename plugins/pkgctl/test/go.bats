#!/usr/bin/env bats

setup() {
	PKGCTL_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export PKGCTL_ROOT
	PM_DIR="$PKGCTL_ROOT/pkg-managers/go"
	export PKGCTL_PM_DIR="$PM_DIR"
	export PKGCTL_PM_SLUG="go"
	PKGCTL_PM_CMD="$(PKGCTL_PM_DIR="$PM_DIR" PKGCTL_PM_SLUG="go" "$PM_DIR/bin/detect" 2>/dev/null)" || true
	export PKGCTL_PM_CMD
}

@test "go/detect: exits 0 when go is available" {
	command -v go &>/dev/null || skip "go not installed"
	run "$PM_DIR/bin/detect"
	[[ $status -eq 0 ]]
	[[ -n "$output" ]]
}

@test "go/check-updates: exits 0" {
	command -v go &>/dev/null || skip "go not installed"
	run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
}

@test "go/check-updates: output is tab-separated with 3 fields" {
	command -v go &>/dev/null || skip "go not installed"
	run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
	if [[ -n "$output" ]]; then
		while IFS= read -r line; do
			tab_count="$(tr -cd '\t' <<<"$line" | wc -c | tr -d ' ')"
			[[ "$tab_count" -eq 2 ]]
		done <<<"$output"
	fi
}
