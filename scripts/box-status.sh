#!/usr/bin/env bash
# box-status [--prompt] — which Semgrep dev boxes are reachable over tailscale.
#
# Probes both boxes' ssh port in parallel, each probe hard-killed after
# $BOX_STATUS_TIMEOUT, so the whole thing stays well under 1s even when a box
# is stopped (a stopped box's IP is unrouted, so the connect would otherwise
# hang). --prompt serves a cached answer instantly and refreshes in the
# background — safe to call on every shell prompt.
set -u

BOXES=(
  "172.16.1.23|claude-box|󰒋"
  "172.16.1.24|claude-box-mini|󰌢"
)
TIMEOUT="${BOX_STATUS_TIMEOUT:-0.5}"
CACHE="${TMPDIR:-/tmp}/box-status.${USER:-x}.cache"
TTL="${BOX_STATUS_TTL:-8}"

_probe() { # ip label -> prints label if port 22 answers; bounded by $TIMEOUT
  nc -z -w 1 "$1" 22 >/dev/null 2>&1 & local p=$!
  ( sleep "$TIMEOUT"; kill -9 "$p" 2>/dev/null ) >/dev/null 2>&1 & local k=$!
  if wait "$p" 2>/dev/null; then printf '%s\n' "$2"; fi
  kill "$k" 2>/dev/null; wait "$k" 2>/dev/null
}

_scan() { # $1 = long|short -> up labels, sorted, space-joined
  local e ip long short label
  for e in "${BOXES[@]}"; do
    IFS='|' read -r ip long short <<<"$e"
    [ "$1" = short ] && label="$short" || label="$long"
    _probe "$ip" "$label" &
  done
  wait
}

_refresh_if_stale() {
  local now mtime
  now=$(date +%s)
  mtime=$(stat -f %m "$CACHE" 2>/dev/null || echo 0)
  if [ ! -f "$CACHE" ] || [ "$((now - mtime))" -ge "$TTL" ]; then
    ( _scan short | sort | paste -sd' ' - >"$CACHE.tmp" 2>/dev/null \
        && mv "$CACHE.tmp" "$CACHE" ) >/dev/null 2>&1 </dev/null &
  fi
}

case "${1:-}" in
  --prompt)
    _refresh_if_stale
    out=$(cat "$CACHE" 2>/dev/null)
    [ -n "$out" ] && printf '%s' "$out"
    [ -n "$out" ]   # exit 0 if any box up, 1 if none (drives starship `when`)
    ;;
  *)
    up=$(_scan long | sort | paste -sd' ' -)
    [ -n "$up" ] && printf 'dev boxes up: %s\n' "$up" || printf 'dev boxes: none up\n'
    ;;
esac
