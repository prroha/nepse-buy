#!/usr/bin/env bash
# Health check: validates that the dev system is properly configured.
# Run manually or via /init to verify system integrity.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
errors=0
warnings=0

echo "=== Dev System Health Check ==="
echo ""

# Check core files
echo "## Core Files"
for f in CLAUDE.md .claude/settings.json .dev-system/README.md; do
    if [[ -f "$PROJECT_ROOT/$f" ]]; then
        echo "  OK  $f"
    else
        echo "  FAIL  $f — MISSING"
        ((errors++))
    fi
done

# Check rule files
echo ""
echo "## Rules"
for f in anti-hallucination.md clean-code.md coding-standards.md ui-ux-design.md; do
    if [[ -f "$PROJECT_ROOT/.dev-system/rules/$f" ]]; then
        echo "  OK  rules/$f"
    else
        echo "  FAIL  rules/$f — MISSING"
        ((errors++))
    fi
done

# Check scripts
echo ""
echo "## Scripts"
for f in detect-stack.sh validate-edit.sh post-edit.sh pre-compact.sh stop-check.sh update-architecture-index.sh health-check.sh; do
    if [[ -f "$PROJECT_ROOT/.dev-system/scripts/$f" ]]; then
        if [[ -x "$PROJECT_ROOT/.dev-system/scripts/$f" ]]; then
            echo "  OK  scripts/$f"
        else
            echo "  WARN  scripts/$f — not executable"
            ((warnings++))
        fi
    else
        echo "  FAIL  scripts/$f — MISSING"
        ((errors++))
    fi
done

# Check skills
echo ""
echo "## Skills"
for skill in init plan add fix refactor index pattern review revisit ui scaffold test security help; do
    if [[ -f "$PROJECT_ROOT/.claude/skills/$skill/SKILL.md" ]]; then
        echo "  OK  /$(printf '%-10s' "$skill")"
    else
        echo "  FAIL  /$skill — MISSING"
        ((errors++))
    fi
done

# Check config
echo ""
echo "## Configuration"
if [[ -f "$PROJECT_ROOT/.dev-system/config.json" ]]; then
    if grep -q '"initialized":\s*true' "$PROJECT_ROOT/.dev-system/config.json" 2>/dev/null; then
        echo "  OK  config.json (initialized)"
        # Validate schema version
        if grep -q '"schemaVersion"' "$PROJECT_ROOT/.dev-system/config.json" 2>/dev/null; then
            echo "  OK  schema version present"
        else
            echo "  WARN  config.json missing schemaVersion — run /init to upgrade"
            ((warnings++))
        fi
    else
        echo "  WARN  config.json exists but not initialized"
        ((warnings++))
    fi
else
    echo "  INFO  config.json not found — run /init"
fi

# Check generated files
echo ""
echo "## Generated Files"
if [[ -f "$PROJECT_ROOT/.dev-system/generated/ARCHITECTURE.md" ]]; then
    if grep -qi "not yet\|placeholder\|run /init\|run /index" "$PROJECT_ROOT/.dev-system/generated/ARCHITECTURE.md" 2>/dev/null; then
        echo "  WARN  ARCHITECTURE.md — placeholder only, run /index"
        ((warnings++))
    else
        echo "  OK  ARCHITECTURE.md"
    fi
    if [[ -f "$PROJECT_ROOT/.dev-system/generated/.stale" ]]; then
        echo "  WARN  Architecture index is STALE — run /index"
        ((warnings++))
    fi
else
    echo "  WARN  ARCHITECTURE.md — MISSING, run /index"
    ((warnings++))
fi

if [[ -f "$PROJECT_ROOT/.dev-system/generated/PATTERNS.md" ]]; then
    echo "  OK  PATTERNS.md"
else
    echo "  WARN  PATTERNS.md — MISSING"
    ((warnings++))
fi

# Summary
echo ""
echo "=== Results ==="
echo "Errors:   $errors"
echo "Warnings: $warnings"

if [[ "$errors" -gt 0 ]]; then
    echo "STATUS: BROKEN — fix errors above"
    exit 1
elif [[ "$warnings" -gt 0 ]]; then
    echo "STATUS: OK with warnings"
    exit 0
else
    echo "STATUS: HEALTHY"
    exit 0
fi
