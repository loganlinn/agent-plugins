#!/usr/bin/env bats

setup() {
	PKGCTL_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export PKGCTL_ROOT
	PM_DIR="$PKGCTL_ROOT/pkg-managers/brew"
	export PKGCTL_PM_DIR="$PM_DIR"
	export PKGCTL_PM_SLUG="brew"
}

@test "brew/detect: exits 0 when brew is available" {
	if ! command -v brew &>/dev/null && ! [[ -x /opt/homebrew/bin/brew ]]; then
		skip "brew not installed"
	fi
	run "$PM_DIR/bin/detect"
	[[ $status -eq 0 ]]
	[[ -n "$output" ]]
}

@test "brew/detect: output is a valid executable path" {
	if ! command -v brew &>/dev/null && ! [[ -x /opt/homebrew/bin/brew ]]; then
		skip "brew not installed"
	fi
	run "$PM_DIR/bin/detect"
	[[ $status -eq 0 ]]
	[[ -x "$output" ]]
}

@test "brew/check-updates: exits 0" {
	if ! command -v brew &>/dev/null && ! [[ -x /opt/homebrew/bin/brew ]]; then
		skip "brew not installed"
	fi
	run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
}

@test "brew/check-updates: output is tab-separated with 3 fields" {
	if ! command -v brew &>/dev/null && ! [[ -x /opt/homebrew/bin/brew ]]; then
		skip "brew not installed"
	fi
	run "$PM_DIR/bin/check-updates"
	[[ $status -eq 0 ]]
	# If there's output, each line should have exactly 2 tabs (3 fields)
	if [[ -n "$output" ]]; then
		while IFS= read -r line; do
			tab_count="$(tr -cd '\t' <<<"$line" | wc -c | tr -d ' ')"
			[[ "$tab_count" -eq 2 ]]
		done <<<"$output"
	fi
}
