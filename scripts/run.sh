#!/usr/bin/env bash
set -euo pipefail

# link-check: main entry point

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=""
OUTPUT_FORMAT="text"
TIMEOUT="${LINK_CHECK_TIMEOUT:-10}"

usage() {
  cat <<'EOF'
Usage: link-check [OPTIONS] <path>

Check markdown files for dead links.

Options:
  --json              Output as JSON array
  --timeout <secs>    HTTP timeout per request (default: 10)
  --help              Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)    OUTPUT_FORMAT="json"; shift ;;
    --timeout) export LINK_CHECK_TIMEOUT="$2"; shift 2 ;;
    --help)    usage; exit 0 ;;
    -*)        echo "Error: unknown option '$1'" >&2; exit 1 ;;
    *)         TARGET="$1"; shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Error: no path specified" >&2
  usage >&2
  exit 1
fi

if [ ! -e "$TARGET" ]; then
  echo "Error: '$TARGET' does not exist" >&2
  exit 1
fi

# Pipeline: extract | check
RESULTS=$("$SCRIPT_DIR/extract.sh" "$TARGET" | "$SCRIPT_DIR/check.sh")

if [ -z "$RESULTS" ]; then
  if [ "$OUTPUT_FORMAT" = "json" ]; then
    echo "[]"
  else
    echo "No links found"
  fi
  exit 0
fi

DEAD=$(echo "$RESULTS" | grep "^DEAD" || true)
TOTAL=$(echo "$RESULTS" | wc -l | tr -d ' ')
DEAD_COUNT=0
if [ -n "$DEAD" ]; then
  DEAD_COUNT=$(echo "$DEAD" | wc -l | tr -d ' ')
fi
OK_COUNT=$((TOTAL - DEAD_COUNT))

if [ "$OUTPUT_FORMAT" = "json" ]; then
  echo "["
  first=true
  while IFS='|' read -r status location url; do
    [ -z "$status" ] && continue
    file=$(echo "$location" | cut -d: -f1)
    lineno=$(echo "$location" | cut -d: -f2)
    is_dead="false"
    if [ "$status" = "DEAD" ]; then is_dead="true"; fi
    if $first; then first=false; else echo ","; fi
    url_escaped=$(echo "$url" | sed 's/"/\\"/g')
    printf '  {"dead": %s, "file": "%s", "line": %s, "url": "%s"}' \
      "$is_dead" "$file" "$lineno" "$url_escaped"
  done <<< "$RESULTS"
  echo ""
  echo "]"
else
  if [ -n "$DEAD" ]; then
    printf "%-6s %-30s %s\n" "STATUS" "LOCATION" "URL"
    while IFS='|' read -r status location url; do
      printf "%-6s %-30s %s\n" "$status" "$location" "$url"
    done <<< "$DEAD"
    echo ""
  fi
  echo "Checked $TOTAL links: $OK_COUNT alive, $DEAD_COUNT dead"
fi

# Exit 1 if any dead links
if [ "$DEAD_COUNT" -gt 0 ]; then
  exit 1
fi
