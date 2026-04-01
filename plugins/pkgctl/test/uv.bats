#!/usr/bin/env bats

setup() {
	PKGCTL_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export PKGCTL_ROOT
	PM_DIR="$PKGCTL_ROOT/pkg-managers/uv"
	export PKGCTL_PM_DIR="$PM_DIR"
	export PKGCTL_PM_SLUG="uv"
	PKGCTL_PM_CMD="$(PKGCTL_PM_DIR="$PM_DIR" PKGCTL_PM_SLUG="uv" "$PM_DIR/bin/detect" 2>/dev/null)" || true
	export PKGCTL_PM_CMD
}

@test "uv/detect: exits 0 when uv is available" {
	command -v uv &>/dev/null || skip "uv not installed"
	run "$PM_DIR/bin/detect"
	[[ $status -eq 0 ]]
	[[ -n "$output" ]]
}

@test "uv/check-updates: exits 0" {
	command -v uv &>/dev/null || skip "uv not installed"
	run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
}

@test "uv/check-updates: output is tab-separated with 3 fields" {
	command -v uv &>/dev/null || skip "uv not installed"
	run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
	if [[ -n "$output" ]]; then
		while IFS= read -r line; do
			tab_count="$(tr -cd '\t' <<<"$line" | wc -c | tr -d ' ')"
			[[ "$tab_count" -eq 2 ]]
		done <<<"$output"
	fi
}
