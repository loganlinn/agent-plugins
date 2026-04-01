#!/usr/bin/env bash
set -euo pipefail

# Pre-flight checks for pkgctl.
# Discovers available package managers and validates notification delivery.
#
# Usage: preflight.sh [pm1,pm2,...|*]
#
# Outputs one detected PM slug per line to stdout.
# Exits non-zero if no PMs are actionable or notifications are broken.

PROG="${0##*/}"
PKGCTL_ROOT="${PKGCTL_ROOT:?PKGCTL_ROOT must be set}"
PM_DIR="$PKGCTL_ROOT/pkg-managers"

requested="${1:-*}"

# Validate notification channel
if ! "$PKGCTL_ROOT/scripts/notify.sh" doctor >/dev/null; then
	echo >&2 "$PROG: notification delivery check failed"
	exit 1
fi

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
	if PKGCTL_PM_DIR="$PM_DIR/$slug" PKGCTL_PM_SLUG="$slug" "$detect" >/dev/null 2>&1; then
		echo "$slug"
		found=$((found + 1))
	else
		echo >&2 "$PROG: $slug: not detected, skipping"
	fi
done

if [[ $found -eq 0 ]]; then
	echo >&2 "$PROG: none of the requested package managers are available"
	exit 1
fi
