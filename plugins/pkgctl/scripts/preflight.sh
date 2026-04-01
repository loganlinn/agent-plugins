#!/usr/bin/env bash
set -euo pipefail

# Pre-flight checks for pkgctl.
# Discovers available package managers.
#
# Usage: preflight.sh [pm1,pm2,...|*]
#
# Outputs one detected PM per line as: slug\tcommand-path
# Exits non-zero if no PMs are actionable.

PROG="${0##*/}"
PKGCTL_ROOT="${PKGCTL_ROOT:?PKGCTL_ROOT must be set}"
PM_DIR="$PKGCTL_ROOT/pkg-managers"

requested="${1:-*}"

# Resolve PM list
if [[ "$requested" == "*" ]]; then
	slugs=()
	for d in "$PM_DIR"/*/; do
		[[ -d "$d" ]] || continue
		slugs+=("$(basename "$d")")
	done
else
	IFS=',' read -ra slugs <<<"$requested"
fi

if [[ ${#slugs[@]} -eq 0 ]]; then
	echo >&2 "$PROG: no package managers found"
	exit 1
fi

# Detect each PM
found=0
for slug in "${slugs[@]}"; do
	detect="$PM_DIR/$slug/bin/detect"
	if [[ ! -x "$detect" ]]; then
		echo >&2 "$PROG: $slug: no detect script at $detect"
		continue
	fi
	cmd_path="$(PKGCTL_PM_DIR="$PM_DIR/$slug" PKGCTL_PM_SLUG="$slug" "$detect" 2>/dev/null)" || {
		echo >&2 "$PROG: $slug: not detected, skipping"
		continue
	}
	if [[ -z "$cmd_path" ]]; then
		echo >&2 "$PROG: $slug: detect exited 0 but produced no path"
		continue
	fi
	printf '%s\t%s\n' "$slug" "$cmd_path"
	found=$((found + 1))
done

if [[ $found -eq 0 ]]; then
	echo >&2 "$PROG: none of the requested package managers are available"
	exit 1
fi
