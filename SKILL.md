---
name: link-check
description: Checks markdown files for dead links, reporting broken URLs and their locations
version: 0.1.0
license: Apache-2.0
---

# link-check

Scans markdown files for links and checks if they're still alive. Dead links in docs are the worst — this tool finds them.

## Purpose

Checks all URLs in markdown files (or a folder of them) and reports which ones are broken. Composable scripts let you extract links, check them, and format results independently.

## Scripts Overview

| Script | Description |
|--------|-------------|
| `scripts/run.sh` | Main entry point — scan files and report dead links |
| `scripts/extract.sh` | Extract all URLs from markdown files to stdout |
| `scripts/check.sh` | Check a single URL and report status |
| `scripts/test.sh` | Run validation tests |

## Pipeline Examples

Extract links only:
```bash
./scripts/extract.sh docs/
```

Check a single URL:
```bash
echo "https://example.com" | ./scripts/check.sh
```

Full pipeline:
```bash
./scripts/extract.sh docs/ | ./scripts/check.sh | grep "DEAD"
```

## Instructions

When a user wants to check for dead links in markdown:

1. Run `./scripts/run.sh <path>` where path is a file or directory
2. The tool extracts all markdown links, checks each URL, and reports dead ones
3. Use `--json` for machine-readable output
4. Use `--timeout <seconds>` to adjust the request timeout (default: 10)
5. Exit code is 1 if any dead links found, 0 if all links are alive

## Inputs and Outputs

**run.sh**: Takes a file/directory path. Outputs a table of dead links with file, line, URL, and HTTP status.

**extract.sh**: Takes a file/directory path. Outputs `file:line:url` per line to stdout.

**check.sh**: Reads `file:line:url` lines from stdin. Outputs `status|file:line|url` to stdout.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LINK_CHECK_TIMEOUT` | `10` | HTTP request timeout in seconds |
| `LINK_CHECK_CONCURRENCY` | `5` | Max parallel checks |
