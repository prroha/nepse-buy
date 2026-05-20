#!/usr/bin/env bash
# Reproduces .github/workflows/refresh-static-data.yml on your laptop.
# Saves the 5-10 min round trip of pushing + waiting for GHA when you're
# chasing npm/tsx/PATH-style bugs.
#
# Usage:
#   scripts/run-workflow-locally.sh                          # export-only (fastest sanity check)
#   scripts/run-workflow-locally.sh scrape-dividends curated # one scrape against the curated list
#   scripts/run-workflow-locally.sh scrape-all curated 4     # full run, 4yrs of price history
#
# Required tools: "$RUNTIME", npm 9+, node 20+. Playwright + Chromium come from
# whatever's already in your npm install — no separate apt step needed
# locally because you presumably have a desktop browser stack already.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Container runtime — docker if available, otherwise podman (Fedora default).
# Override with CONTAINER_RUNTIME=docker|podman.
RUNTIME="${CONTAINER_RUNTIME:-}"
if [ -z "$RUNTIME" ]; then
  if command -v docker >/dev/null 2>&1; then
    RUNTIME=docker
  elif command -v podman >/dev/null 2>&1; then
    RUNTIME=podman
  else
    echo "neither docker nor podman is installed"; exit 1
  fi
fi
echo "[local-test] using container runtime: $RUNTIME"

ACTION="${1:-export-only}"   # export-only | scrape-dividends | scrape-prices | scrape-all
SCOPE="${2:-curated}"        # curated | watchlisted | all
PRICE_YEARS="${3:-4}"

case "$ACTION" in
  export-only|scrape-dividends|scrape-prices|scrape-all) ;;
  *) echo "unknown action: $ACTION"; exit 1;;
esac
case "$SCOPE" in
  curated|watchlisted|all) ;;
  *) echo "unknown scope: $SCOPE"; exit 1;;
esac

# Mirror the workflow's job-level env. NOTE: do NOT set NODE_ENV here for
# the same reason as the workflow — npm ci would skip devDependencies.
export DATABASE_URL="postgresql://nepse:nepse@localhost:5432/nepse_buy"
export REDIS_URL="redis://localhost:6379"
export SMOKE_INSECURE=1
# Config validator still requires JWT_SECRET in NODE_ENV=production even
# though the scrape scripts don't use it. Transparent placeholder so the
# validator passes.
export JWT_SECRET="ci-scrape-only-not-used-for-auth"

PG_CONTAINER="nepse-pg-local"
REDIS_CONTAINER="nepse-redis-local"

echo "=== [local-test] action=$ACTION scope=$SCOPE price_years=$PRICE_YEARS ==="

ensure_service() {
  local name="$1" image="$2"; shift 2
  if "$RUNTIME" ps --format '{{.Names}}' | grep -q "^${name}$"; then
    echo "[local-test] $name already running"
    return
  fi
  echo "[local-test] starting $name ($image)"
  "$RUNTIME" run -d --rm --name "$name" "$@" "$image" >/dev/null
}

wait_for_postgres() {
  echo "[local-test] waiting for Postgres to accept connections..."
  for _ in $(seq 1 30); do
    if "$RUNTIME" exec "$PG_CONTAINER" pg_isready -U nepse -d nepse_buy >/dev/null 2>&1; then
      echo "[local-test] Postgres ready"
      return
    fi
    sleep 1
  done
  echo "[local-test] Postgres failed to start within 30s"; exit 1
}

ensure_service "$PG_CONTAINER" "postgres:16-alpine" \
  -e POSTGRES_USER=nepse -e POSTGRES_PASSWORD=nepse -e POSTGRES_DB=nepse_buy \
  -p 5432:5432
ensure_service "$REDIS_CONTAINER" "redis:7-alpine" -p 6379:6379
wait_for_postgres

echo "[local-test] npm ci --include=dev (root, for workspaces)"
npm ci --include=dev

cd core/backend

echo "[local-test] prisma generate + db push (no migrations dir; ephemeral DB)"
NODE_ENV=production npx prisma generate
NODE_ENV=production npx prisma db push --accept-data-loss --skip-generate

echo "[local-test] seed (curated universe + system settings)"
NODE_ENV=production npx tsx prisma/seed.ts

if [[ "$ACTION" == "scrape-dividends" || "$ACTION" == "scrape-all" ]]; then
  echo "[local-test] scrape dividends (--$SCOPE --force)"
  NODE_ENV=production npx tsx scripts/scrape-dividends.ts --"$SCOPE" --force
fi

if [[ "$ACTION" == "scrape-prices" || "$ACTION" == "scrape-all" ]]; then
  echo "[local-test] backfill prices (--scope $SCOPE --years $PRICE_YEARS)"
  NODE_ENV=production npx tsx scripts/backfill-curated.ts --scope "$SCOPE" --years "$PRICE_YEARS"
fi

echo "[local-test] export JSON bundle → ../../data"
NODE_ENV=production npx tsx scripts/export-static-data.ts --out ../../data

cd "$ROOT"

echo
echo "=== Manifest ==="
cat data/manifest.json
echo
echo "=== Files (first 30) ==="
find data -type f -name "*.json" | sort | head -30
echo
echo "[local-test] done."
echo "  Inspect:    git status data/   git diff --stat data/"
echo "  Tear down:  "$RUNTIME" stop $PG_CONTAINER $REDIS_CONTAINER"
