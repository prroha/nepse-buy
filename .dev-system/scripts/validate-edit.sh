#!/usr/bin/env bash
# PreToolUse hook: validates file edits before they happen.
# Receives tool input as JSON on stdin.
# Exit 0 = allow, Exit 2 = block with message to Claude.

set -euo pipefail

INPUT=$(cat)

# Extract file_path — try tool_input.file_path first, then top-level file_path
# Uses grep+sed for portability (no python dependency)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || echo "")

if [[ -z "$FILE_PATH" ]]; then
    exit 0  # Can't determine path, allow
fi

# Block edits to build artifacts and package directories
BLOCKED_DIRS="node_modules .git dist build .next __pycache__ .venv venv target out .gradle .turbo"
for dir in $BLOCKED_DIRS; do
    if [[ "$FILE_PATH" == */"$dir"/* ]]; then
        echo "BLOCKED: Editing files inside $dir/ is not allowed. These are generated/managed by tools."
        exit 2
    fi
done

# Warn about .env files (don't block)
basename_file=$(basename "$FILE_PATH")
if [[ "$basename_file" == .env* ]] && [[ "$basename_file" != ".env.example" ]] && [[ "$basename_file" != ".env.template" ]]; then
    echo "WARNING: Editing environment file ($FILE_PATH). Ensure no secrets are hardcoded."
fi

# Warn about large file creation (500+ line writes)
# This is informational only — doesn't block
exit 0
