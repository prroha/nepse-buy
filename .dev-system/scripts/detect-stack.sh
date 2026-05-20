#!/usr/bin/env bash
# SessionStart hook: Detect project stack or check initialization status.
# Outputs context for Claude to understand the project.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/.dev-system/config.json"

# --- Initialized project: load optimized profile ---
if [[ -f "$CONFIG_FILE" ]]; then
    if grep -q '"initialized":\s*true' "$CONFIG_FILE" 2>/dev/null; then
        PROFILE="$PROJECT_ROOT/.dev-system/generated/PROJECT_PROFILE.md"
        if [[ -f "$PROFILE" ]]; then
            echo "[Dev System] Loading project profile:"
            cat "$PROFILE"
        else
            echo "[Dev System] Project initialized but no profile found. Run /init to generate."
            echo "[Config]"
            cat "$CONFIG_FILE"
        fi
        if [[ -f "$PROJECT_ROOT/.dev-system/generated/.stale" ]]; then
            echo ""
            echo "[Dev System] Architecture index is STALE. Consider running /index."
        fi

        # Show project plan status for cross-session continuity
        PLAN="$PROJECT_ROOT/.dev-system/generated/PLAN.md"
        if [[ -f "$PLAN" ]]; then
            in_progress=$(grep -n '\[IN PROGRESS\]' "$PLAN" 2>/dev/null | head -1)
            if [[ -n "$in_progress" ]]; then
                phase_name=$(echo "$in_progress" | sed 's/^[0-9]*:## //' | sed 's/ \[IN PROGRESS\]//')
                # Count done and total items in current phase
                phase_line=$(echo "$in_progress" | cut -d: -f1)
                # Get items between this phase header and the next phase header (or EOF)
                total=$(awk "NR>$phase_line && /^- \[/ {count++} NR>$phase_line && /^## / {exit} END {print count+0}" "$PLAN")
                done=$(awk "NR>$phase_line && /^- \[x\]/ {count++} NR>$phase_line && /^## / {exit} END {print count+0}" "$PLAN")
                echo ""
                echo "[Plan] $phase_name — IN PROGRESS ($done/$total done)"
            fi
        fi

        # Show recent activity for cross-session continuity
        ACTIVITY="$PROJECT_ROOT/.dev-system/generated/ACTIVITY.md"
        if [[ -f "$ACTIVITY" ]] && grep -q '^## ' "$ACTIVITY" 2>/dev/null; then
            echo "[Recent Activity]"
            grep '^## ' "$ACTIVITY" | head -3
            echo "(Full log: .dev-system/generated/ACTIVITY.md)"
        fi

        exit 0
    fi
fi

# --- Not initialized: auto-detect stack ---
echo "[Dev System] Project not initialized. Auto-detecting stack..."

detected=""
lang=""

# Node.js ecosystem
if [[ -f "$PROJECT_ROOT/package.json" ]]; then
    echo "[Detected] package.json — Node.js project"
    detected="nodejs"

    # Check for TypeScript
    if [[ -f "$PROJECT_ROOT/tsconfig.json" ]] || grep -q '"typescript"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        lang="typescript"
        echo "[Detected] TypeScript"
    else
        lang="javascript"
    fi

    # Detect framework (check dependencies and devDependencies)
    if grep -q '"next"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Next.js"
        detected="nextjs"
    elif grep -q '"react-native"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] React Native"
        detected="react-native"
    elif grep -q '"react"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] React"
        detected="react"
    elif grep -q '"vue"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Vue.js"
        detected="vue"
    elif grep -q '"@angular/core"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Angular"
        detected="angular"
    elif grep -q '"express"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Express.js"
        detected="node-express"
    elif grep -q '"hono"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Hono (will use node-express rules as closest match)"
        detected="node-express"
    else
        echo "[Detected] Node.js project (no specific framework — will use generic rules)"
        detected="generic"
    fi

    # Detect styling
    if grep -q '"tailwindcss"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Tailwind CSS"
    fi

    # Detect package manager
    if [[ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]]; then
        echo "[Detected] pnpm"
    elif [[ -f "$PROJECT_ROOT/yarn.lock" ]]; then
        echo "[Detected] yarn"
    elif [[ -f "$PROJECT_ROOT/bun.lockb" ]] || [[ -f "$PROJECT_ROOT/bun.lock" ]]; then
        echo "[Detected] bun"
    elif [[ -f "$PROJECT_ROOT/package-lock.json" ]]; then
        echo "[Detected] npm"
    fi

    # Detect testing
    if grep -q '"vitest"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Vitest"
    elif grep -q '"jest"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Jest"
    fi

    # Detect database/ORM
    if grep -q '"prisma"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Prisma ORM"
    elif grep -q '"drizzle-orm"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        echo "[Detected] Drizzle ORM"
    fi
fi

# Python ecosystem
if [[ -f "$PROJECT_ROOT/requirements.txt" ]] || [[ -f "$PROJECT_ROOT/pyproject.toml" ]] || [[ -f "$PROJECT_ROOT/Pipfile" ]] || [[ -f "$PROJECT_ROOT/setup.py" ]]; then
    echo "[Detected] Python project"
    lang="python"
    detected="python"

    framework_found=false
    for manifest in "$PROJECT_ROOT/requirements.txt" "$PROJECT_ROOT/pyproject.toml" "$PROJECT_ROOT/Pipfile" "$PROJECT_ROOT/setup.py"; do
        [[ -f "$manifest" ]] || continue
        if grep -qi "fastapi" "$manifest" 2>/dev/null; then
            echo "[Detected] FastAPI"
            detected="python-fastapi"
            framework_found=true
            break
        elif grep -qi "django" "$manifest" 2>/dev/null; then
            echo "[Detected] Django"
            detected="python-django"
            framework_found=true
            break
        elif grep -qi "flask" "$manifest" 2>/dev/null; then
            echo "[Detected] Flask (no dedicated stack rules — will use generic)"
            detected="generic"
            framework_found=true
            break
        fi
    done
    if [[ "$framework_found" == "false" ]]; then
        echo "[Detected] Python project (no specific framework — will use generic rules)"
        detected="generic"
    fi
fi

# Flutter/Dart
if [[ -f "$PROJECT_ROOT/pubspec.yaml" ]]; then
    echo "[Detected] Flutter/Dart"
    lang="dart"
    detected="flutter"
fi

# Go
if [[ -f "$PROJECT_ROOT/go.mod" ]]; then
    echo "[Detected] Go"
    lang="go"
    detected="go"
fi

# Rust
if [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
    echo "[Detected] Rust"
    lang="rust"
    detected="rust"

    # Detect web frameworks
    if grep -q "axum" "$PROJECT_ROOT/Cargo.toml" 2>/dev/null; then
        echo "[Detected] Axum framework"
    elif grep -q "actix" "$PROJECT_ROOT/Cargo.toml" 2>/dev/null; then
        echo "[Detected] Actix framework"
    fi
fi

# Java/Kotlin
if [[ -f "$PROJECT_ROOT/pom.xml" ]] || [[ -f "$PROJECT_ROOT/build.gradle" ]] || [[ -f "$PROJECT_ROOT/build.gradle.kts" ]]; then
    echo "[Detected] Java/Kotlin project (no dedicated stack rules — will use generic)"
    detected="generic"
fi

if [[ -z "$detected" ]]; then
    echo "[Dev System] NEW_PROJECT — No existing project files detected."
    echo "[Dev System] The recommendation engine will help you choose the optimal stack."
else
    echo ""
    echo "[Dev System] EXISTING_PROJECT — Stack detected: $detected"
fi

echo ""
echo "[Dev System] Run /init to complete setup."
