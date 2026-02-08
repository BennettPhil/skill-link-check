# link-check

Checks markdown files for dead links.

## Quick Start

```bash
./scripts/run.sh docs/
```

## Composable Scripts

```bash
# Extract links only
./scripts/extract.sh README.md

# Check a single URL
echo "file:1:https://example.com" | ./scripts/check.sh

# Full pipeline
./scripts/extract.sh docs/ | ./scripts/check.sh | grep DEAD
```

## JSON Output

```bash
./scripts/run.sh --json docs/
```

## Prerequisites

- curl
- grep, sed (standard Unix tools)

## Testing

```bash
./scripts/test.sh
```
