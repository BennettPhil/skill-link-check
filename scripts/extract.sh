#!/usr/bin/env bash
set -euo pipefail

# extract.sh: Extract URLs from markdown files
# Output format: file:line:url

if [ "${1:-}" = "--help" ]; then
  echo "Usage: extract.sh <file-or-directory>"
  echo "Extract all URLs from markdown files. Output: file:line:url"
  exit 0
fi

TARGET="${1:-.}"

if [ ! -e "$TARGET" ]; then
  echo "Error: '$TARGET' does not exist" >&2
  exit 1
fi

extract_from_file() {
  local file="$1"
  # Use grep -n to get line numbers, then extract URLs
  # First: markdown links [text](url)
  grep -nE '\[([^]]*)\]\(https?://[^)]+\)' "$file" 2>/dev/null | while IFS= read -r match; do
    local lineno content
    lineno=$(echo "$match" | cut -d: -f1)
    content=$(echo "$match" | cut -d: -f2-)
    # Extract all URLs from this line
    echo "$content" | grep -oE 'https?://[^)]+' | while IFS= read -r url; do
      # Clean trailing parens or brackets
      url="${url%)}"
      echo "${file}:${lineno}:${url}"
    done
  done || true

  # Second: bare URLs not in markdown link syntax
  grep -nE 'https?://[^ <>)"]+' "$file" 2>/dev/null | while IFS= read -r match; do
    local lineno content
    lineno=$(echo "$match" | cut -d: -f1)
    content=$(echo "$match" | cut -d: -f2-)
    echo "$content" | grep -oE 'https?://[^ <>)"]+' | while IFS= read -r url; do
      echo "${file}:${lineno}:${url}"
    done
  done || true
}

# Deduplicate (same file:line:url may appear from both passes)
collect_urls() {
  if [ -f "$TARGET" ]; then
    extract_from_file "$TARGET"
  elif [ -d "$TARGET" ]; then
    find "$TARGET" -name "*.md" -type f | sort | while IFS= read -r file; do
      extract_from_file "$file"
    done
  fi
}

collect_urls | sort -u
