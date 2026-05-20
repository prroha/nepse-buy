#!/usr/bin/env bash
# PostToolUse hook: marks architecture index as stale after source file edits.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STALE_MARKER="$PROJECT_ROOT/.dev-system/generated/.stale"
GENERATED_DIR="$PROJECT_ROOT/.dev-system/generated"

mkdir -p "$GENERATED_DIR"

INPUT=$(cat)

# Extract file_path using grep+sed (no python dependency)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || echo "")

# Skip if we can't determine path
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Don't mark stale for generated files, config, or CLAUDE.md
if [[ "$FILE_PATH" == */.dev-system/* ]] || [[ "$FILE_PATH" == */CLAUDE.md ]]; then
    exit 0
fi

# Mark architecture index as stale for source file edits
touch "$STALE_MARKER"
exit 0
