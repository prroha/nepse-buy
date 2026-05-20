#!/usr/bin/env bash
# Generates the architecture index by scanning the project directory tree.
# Called by /index skill. Output is further enhanced by Claude.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STALE_MARKER="$PROJECT_ROOT/.dev-system/generated/.stale"

# Exclusion list (shared across tree and find)
EXCLUDE_DIRS="node_modules|.git|dist|build|.next|__pycache__|.dev-system|.claude|.venv|venv|coverage|.turbo|.cache|target|out|.gradle"

echo "# Architecture Index"
echo "Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# --- Directory Structure ---
echo "## Directory Structure"
echo '```'
if command -v tree &>/dev/null; then
    tree -d -L 4 -I "$EXCLUDE_DIRS" "$PROJECT_ROOT" 2>/dev/null || echo "(tree command failed)"
else
    find "$PROJECT_ROOT" -maxdepth 4 -type d \
        ! -name 'node_modules' ! -name '.git' ! -name 'dist' ! -name 'build' \
        ! -name '.next' ! -name '__pycache__' ! -name '.dev-system' ! -name '.claude' \
        ! -name '.venv' ! -name 'venv' ! -name 'coverage' ! -name '.turbo' \
        ! -name '.cache' ! -name 'target' ! -name 'out' ! -name '.gradle' \
        -printf '%P\n' 2>/dev/null | sort | head -100
fi
echo '```'
echo ""

# --- Key Config Files ---
echo "## Key Files"
for f in package.json tsconfig.json pyproject.toml requirements.txt go.mod Cargo.toml pubspec.yaml \
         docker-compose.yml docker-compose.yaml Dockerfile .env.example \
         vite.config.ts vite.config.js next.config.js next.config.ts next.config.mjs \
         tailwind.config.ts tailwind.config.js tailwind.config.mjs \
         prisma/schema.prisma drizzle.config.ts \
         Makefile justfile; do
    [[ -f "$PROJECT_ROOT/$f" ]] && echo "- \`$f\`"
done
echo ""

# --- Source File Counts ---
echo "## Source Files"
for ext in ts tsx js jsx py go rs dart vue svelte java kt rb; do
    count=$(find "$PROJECT_ROOT" -name "*.$ext" \
        ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' \
        ! -path '*/build/*' ! -path '*/.next/*' ! -path '*/target/*' \
        2>/dev/null | wc -l)
    [[ "$count" -gt 0 ]] && echo "- \`.$ext\`: $count files"
done
echo ""

# --- Entry Points ---
echo "## Entry Points"
for f in src/index.ts src/index.tsx src/main.ts src/main.tsx src/app.ts src/app.tsx \
         src/App.tsx src/App.vue src/app/layout.tsx src/app/page.tsx \
         src/pages/index.tsx src/pages/_app.tsx \
         app/page.tsx app/layout.tsx \
         main.py app.py manage.py src/main.py \
         main.go cmd/main.go cmd/server/main.go \
         src/main.rs src/lib.rs \
         lib/main.dart; do
    [[ -f "$PROJECT_ROOT/$f" ]] && echo "- \`$f\`"
done
echo ""

# --- Sections for Claude to enhance ---
echo "## External Dependencies"
echo "_Run /index to have Claude populate this section from the dependency manifest._"
echo ""
echo "## Data Flow"
echo "_Run /index to have Claude populate this section from source analysis._"
echo ""
echo "## Patterns In Use"
echo "See \`.dev-system/generated/PATTERNS.md\`"

# Clean up stale marker
rm -f "$STALE_MARKER"
