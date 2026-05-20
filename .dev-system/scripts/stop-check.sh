#!/usr/bin/env bash
# Stop hook: surface actionable reminders after Claude finishes responding.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
reminders=""

# Check if architecture index is stale
if [[ -f "$PROJECT_ROOT/.dev-system/generated/.stale" ]]; then
    reminders+="[Dev System] Architecture index is STALE. Run /index to rebuild.\n"
fi

# Check if project is not initialized
if [[ ! -f "$PROJECT_ROOT/.dev-system/config.json" ]]; then
    reminders+="[Dev System] Project not initialized. Run /init to set up.\n"
fi

# Count modified files in this session (uncommitted changes)
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    changed_count=$(git diff --name-only 2>/dev/null | wc -l)
    staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l)
    total=$(( changed_count + staged_count ))
    if [[ "$total" -gt 5 ]]; then
        reminders+="[Dev System] $total files changed. Consider running /revisit before committing.\n"
    fi
fi

if [[ -n "$reminders" ]]; then
    echo -e "$reminders"
fi
