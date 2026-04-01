#!/usr/bin/env bash
set -euo pipefail

# Cross-platform desktop notification delivery.
# Usage:
#   notify.sh send "title" "body"
#   notify.sh doctor

PROG="${0##*/}"

usage() {
	cat >&2 <<-EOF
		Usage: $PROG <command> [args...]

		Commands:
		  send "title" "body"   Send a desktop notification
		  doctor                Verify notification delivery is possible
	EOF
}

# Detect the best available notification method.
# Respects PKGCTL_NOTIFY_METHOD if set.
detect_method() {
	if [[ -n "${PKGCTL_NOTIFY_METHOD:-}" ]]; then
		echo "$PKGCTL_NOTIFY_METHOD"
		return
	fi
	case "$(uname -s)" in
	Darwin)
		echo osascript
		;;
	Linux)
		if command -v notify-send &>/dev/null; then
			echo notify-send
		else
			echo >&2 "$PROG: no notification method available (install notify-send)"
			return 1
		fi
		;;
	*)
		echo >&2 "$PROG: unsupported platform: $(uname -s)"
		return 1
		;;
	esac
}

cmd_send() {
	local title="${1:?missing title}"
	local body="${2:-}"
	local method
	method="$(detect_method)"

	case "$method" in
	osascript)
		# Escape double quotes for AppleScript
		local escaped_title="${title//\"/\\\"}"
		local escaped_body="${body//\"/\\\"}"
		if [[ -n "$body" ]]; then
			osascript -e "display notification \"$escaped_body\" with title \"$escaped_title\""
		else
			osascript -e "display notification \"$escaped_title\" with title \"pkgctl\""
		fi
		;;
	notify-send)
		if [[ -n "$body" ]]; then
			notify-send "$title" "$body"
		else
			notify-send "$title"
		fi
		;;
	*)
		echo >&2 "$PROG: unknown notification method: $method"
		return 1
		;;
	esac
}

cmd_doctor() {
	local method
	if ! method="$(detect_method)"; then
		echo >&2 "$PROG: doctor: no notification method available"
		return 1
	fi

	case "$method" in
	osascript)
		if ! command -v osascript &>/dev/null; then
			echo >&2 "$PROG: doctor: osascript not found"
			return 1
		fi
		echo "ok: osascript"
		;;
	notify-send)
		if ! command -v notify-send &>/dev/null; then
			echo >&2 "$PROG: doctor: notify-send not found"
			return 1
		fi
		echo "ok: notify-send"
		;;
	*)
		echo >&2 "$PROG: doctor: unknown method '$method'"
		return 1
		;;
	esac
}

case "${1:-}" in
send)
	shift
	cmd_send "$@"
	;;
doctor) cmd_doctor ;;
-h | --help)
	usage
	exit 0
	;;
*)
	usage
	exit 1
	;;
esac
