# Architecture Index
Updated: 2026-05-19T09:09:35Z

> **Status: Greenfield.** No source files yet. This index documents the *planned* architecture per locked v1 scope. Re-run `/index` after code lands to replace planned sections with detected ones.

## Planned Directory Structure (post-fork from fullstack-starter)
```
nepse-buy/
├── core/
│   ├── backend/                # Node.js + Express + TypeScript
│   │   ├── prisma/             # Schema + migrations
│   │   ├── src/
│   │   │   ├── auth/           # JWT, RBAC (from starter)
│   │   │   ├── users/
│   │   │   ├── stocks/         # Stock CRUD, watchlist
│   │   │   ├── market-data/    # Adapter interface + impls
│   │   │   │   ├── sources/
│   │   │   │   │   ├── nepalstock.ts    # Price OHLC scraper
│   │   │   │   │   └── nepse-alpha.ts   # Fundamentals scraper
│   │   │   │   └── ingestion.ts         # Persists observations
│   │   │   ├── signals/        # DCA + weak-month engine (pure fns)
│   │   │   ├── notifications/  # Resend email + in-app feed
│   │   │   ├── jobs/           # BullMQ workers + cron defs
│   │   │   └── server.ts       # Express bootstrap
│   │   └── tests/
│   └── mobile/                 # Flutter + Riverpod
│       ├── lib/
│       │   ├── data/           # Repos, dio client, models
│       │   ├── domain/         # Entities, use-cases
│       │   ├── presentation/   # Screens: auth, watchlist, feed, detail, settings
│       │   └── core/           # DI, theme, routing
│       └── test/
├── shared/
│   └── backend-utils/          # Shared utility package (from starter)
├── docker-compose.dev.yml      # Postgres + Redis + backend
└── docker-compose.yml          # Production stack
```

## Architectural Layers

### Backend (Node/Express/TS)
1. **HTTP layer** (`auth/`, `users/`, `stocks/`) — REST endpoints, Zod validation, JWT middleware.
2. **Market-data layer** (`market-data/`) — Source-independent ingestion. Adapters scrape; ingestion writes append-only `PriceObservation` and `FundamentalsObservation` rows tagged with `source` + `fetched_at`.
3. **Signal engine** (`signals/`) — Pure functions over DB reads. Computes 20-day MA, 3–5yr P/E and P/B medians, season classification, emits `DailySignal` rows with `inputsSnapshot` for audit.
4. **Job orchestration** (`jobs/`) — BullMQ workers triggered by cron (16:00 NPT trading days): scrape → ingest → evaluate → notify.
5. **Notification delivery** (`notifications/`) — Resend transactional email + persisted in-app feed.

### Mobile (Flutter)
- Clean Architecture (data/domain/presentation) inherited from starter.
- Screens: login/register, watchlist (curated default + searchable add), daily signal feed, per-stock detail (price + 20-day MA + P/E history), notification preferences.

## Data Flow
1. Cron fires at 16:00 NPT → `scrape-prices` and `scrape-fundamentals` jobs run.
2. Adapters fetch + parse → ingestion inserts append-only observation rows.
3. `evaluate-signals` job runs per watchlist item → emits `DailySignal`.
4. `notify-users` job groups today's signals per user → sends one Resend email + writes in-app feed entries.
5. Flutter app reads feed + watchlist via JWT-authed REST endpoints.

## Key Dependencies (planned)
| Layer | Package | Purpose |
|---|---|---|
| Backend | express, @prisma/client, zod, jsonwebtoken, bcrypt | HTTP, DB, validation, auth |
| Backend | bullmq, ioredis | Job queue + scheduling |
| Backend | resend | Transactional email |
| Backend | cheerio + undici (or playwright) | HTML scraping (TBD per source) |
| Mobile | flutter_riverpod, dio, freezed, dartz, flutter_secure_storage | State, HTTP, models, errors, token storage |
| Mobile | (TBD) email/in-app feed UI only — no FCM in v1 |

## External Systems
- **nepalstock.com.np** — price/volume OHLC (source of truth). Scraped.
- **nepsealpha.com** — fundamentals (P/E, P/B, EPS, book value). Scraped.
- **Resend** — transactional email.
- **Postgres** — primary store, append-only observation tables.
- **Redis** — BullMQ queue backend.

## Patterns In Use
See `.dev-system/generated/PATTERNS.md` — empty pending first implementations.
