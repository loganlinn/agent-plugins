#!/usr/bin/env bats

setup() {
	PKGCTL_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	NOTIFY="$PKGCTL_ROOT/scripts/notify.sh"
}

@test "notify.sh: usage on no args" {
	run "$NOTIFY"
	[[ $status -eq 1 ]]
	[[ "$output" == *"Usage:"* ]]
}

@test "notify.sh: --help shows usage" {
	run "$NOTIFY" --help
	[[ $status -eq 0 ]]
	[[ "$output" == *"Usage:"* ]]
}

@test "notify.sh: doctor detects a method" {
	run "$NOTIFY" doctor
	[[ $status -eq 0 ]]
	[[ "$output" == ok:* ]]
}

@test "notify.sh: doctor respects PKGCTL_NOTIFY_METHOD" {
	PKGCTL_NOTIFY_METHOD=bogus run "$NOTIFY" doctor
	[[ $status -eq 1 ]]
	[[ "$output" == *"unknown method"* ]]
}

@test "notify.sh: send requires title" {
	run "$NOTIFY" send
	[[ $status -ne 0 ]]
}

@test "notify.sh: unknown subcommand fails" {
	run "$NOTIFY" bogus
	[[ $status -eq 1 ]]
	[[ "$output" == *"Usage:"* ]]
}
