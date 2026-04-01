#!/usr/bin/env bats

setup() {
	PKGCTL_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export PKGCTL_ROOT
	PREFLIGHT="$PKGCTL_ROOT/scripts/preflight.sh"
}

@test "preflight: discovers brew when available" {
	if ! command -v brew &>/dev/null && ! [[ -x /opt/homebrew/bin/brew ]]; then
		skip "brew not installed"
	fi
	run "$PREFLIGHT" brew
	[[ $status -eq 0 ]]
	# Output is slug<TAB>command-path
	[[ "$output" =~ ^brew$'\t'.+ ]]
}

@test "preflight: wildcard discovers at least one PM" {
	run "$PREFLIGHT" '*'
	[[ $status -eq 0 ]]
	[[ -n "$output" ]]
}

@test "preflight: unknown PM is skipped gracefully" {
	run "$PREFLIGHT" nonexistent-pm-xyz
	[[ $status -ne 0 ]]
	[[ "$output" == *"no detect script"* || "$output" == *"none of the requested"* ]]
}

@test "preflight: fails without PKGCTL_ROOT" {
	unset PKGCTL_ROOT
	run "$PREFLIGHT" brew
	[[ $status -ne 0 ]]
}
