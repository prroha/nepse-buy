#!/usr/bin/env bash
# PreCompact hook: re-inject critical context before compaction.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/.dev-system/config.json"

echo "[Dev System] Context compacting. Preserving critical state:"

# Re-inject project profile (optimized context) or fallback to config
PROFILE="$PROJECT_ROOT/.dev-system/generated/PROJECT_PROFILE.md"
if [[ -f "$PROFILE" ]]; then
    echo ""
    cat "$PROFILE"
elif [[ -f "$CONFIG_FILE" ]]; then
    echo ""
    echo "[Config] $(cat "$CONFIG_FILE")"
fi

# Show modified files
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    changed=$(git diff --name-only 2>/dev/null)
    staged=$(git diff --cached --name-only 2>/dev/null)
    if [[ -n "$changed" || -n "$staged" ]]; then
        echo ""
        echo "[Modified files]"
        [[ -n "$staged" ]] && echo "$staged" | sed 's/^/  staged: /'
        [[ -n "$changed" ]] && echo "$changed" | sed 's/^/  unstaged: /'
    fi
fi

# Show stale status
if [[ -f "$PROJECT_ROOT/.dev-system/generated/.stale" ]]; then
    echo ""
    echo "[Warning] Architecture index is STALE."
fi

# Preserve plan context
PLAN="$PROJECT_ROOT/.dev-system/generated/PLAN.md"
if [[ -f "$PLAN" ]]; then
    in_progress=$(grep '\[IN PROGRESS\]' "$PLAN" 2>/dev/null | head -1)
    if [[ -n "$in_progress" ]]; then
        echo ""
        echo "[Plan] Current: $in_progress"
        echo "(Read .dev-system/generated/PLAN.md for full plan)"
    fi
fi

# Preserve recent activity context
ACTIVITY="$PROJECT_ROOT/.dev-system/generated/ACTIVITY.md"
if [[ -f "$ACTIVITY" ]] && grep -q '^## ' "$ACTIVITY" 2>/dev/null; then
    echo ""
    echo "[Recent Activity — read .dev-system/generated/ACTIVITY.md for full context]"
    grep '^## ' "$ACTIVITY" | head -3
fi
