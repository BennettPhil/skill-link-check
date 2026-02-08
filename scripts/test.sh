#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0

check() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc -- expected '$expected', got '$actual'"
  fi
}

echo "Testing link-check"
echo "==================="

# Create test fixture
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/test.md" << 'EOF'
# Test Doc

A link to [Google](https://www.google.com) and a [bad link](https://httpstat.us/404).

Also [another good one](https://httpstat.us/200).
EOF

# Test extract
echo ""
echo "Extract tests:"
EXTRACTED=$("$SCRIPT_DIR/extract.sh" "$TMPDIR/test.md")
EXTRACT_COUNT=$(echo "$EXTRACTED" | wc -l | tr -d ' ')
check "extracts 3 links" "3" "$EXTRACT_COUNT"

echo "$EXTRACTED" | grep -qF "google.com" && check "finds google link" "found" "found" || check "finds google link" "found" "not found"

# Test help flags
echo ""
echo "Help tests:"
"$SCRIPT_DIR/run.sh" --help >/dev/null 2>&1 && check "run.sh --help" "0" "0" || check "run.sh --help" "0" "1"
"$SCRIPT_DIR/extract.sh" --help >/dev/null 2>&1 && check "extract.sh --help" "0" "0" || check "extract.sh --help" "0" "1"
"$SCRIPT_DIR/check.sh" --help >/dev/null 2>&1 && check "check.sh --help" "0" "0" || check "check.sh --help" "0" "1"

echo ""
echo "==================="
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
