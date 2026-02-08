#!/usr/bin/env bash
set -euo pipefail

# check.sh: Check URLs for liveness
# Input:  file:line:url (from stdin)
# Output: status|file:line|url

TIMEOUT="${LINK_CHECK_TIMEOUT:-10}"

if [ "${1:-}" = "--help" ]; then
  echo "Usage: extract.sh ... | check.sh"
  echo "Check URLs from stdin. Input: file:line:url. Output: status|file:line|url"
  echo "Set LINK_CHECK_TIMEOUT (default: 10) to adjust timeout."
  exit 0
fi

check_url() {
  local url="$1"
  local status
  status=$(curl -sL -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" "$url" 2>/dev/null || echo "000")
  echo "$status"
}

while IFS= read -r line; do
  [ -z "$line" ] && continue

  # Parse file:line:url — URL starts after second colon (file:lineno:https://...)
  local_file=$(echo "$line" | cut -d: -f1)
  local_lineno=$(echo "$line" | cut -d: -f2)
  # URL is everything after file:lineno: — rejoin remaining fields
  url=$(echo "$line" | sed "s/^[^:]*:[^:]*://")

  if [ -z "$url" ]; then
    continue
  fi

  status=$(check_url "$url")

  if [ "$status" -ge 200 ] 2>/dev/null && [ "$status" -lt 400 ] 2>/dev/null; then
    echo "OK|${local_file}:${local_lineno}|${url}"
  elif [ "$status" = "000" ]; then
    echo "DEAD|${local_file}:${local_lineno}|${url} (timeout/unreachable)"
  else
    echo "DEAD|${local_file}:${local_lineno}|${url} (HTTP ${status})"
  fi
done
