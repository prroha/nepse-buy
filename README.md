# nepse-buy

Personal Android app for executing a refined DCA strategy on the Nepal Stock Exchange (NEPSE) — seasonal awareness (WEAK / NORMAL / STRONG months), valuation gates, OD-loan optimisation, FIFO cost basis + CGT, broker-SMS auto-ingest.

No always-on backend. Everything runs locally on the phone.

## Architecture (v0.9 pivot)

```
                     ┌──────────────────────┐
                     │   GitHub Actions     │   ← you trigger manually
                     │  "Refresh static data"│
                     │  (workflow_dispatch) │
                     └──────────┬───────────┘
                                │  scrape NEPSE + ShareSansar + Mero Lagani
                                ▼
                     ┌──────────────────────┐
                     │  data/*.json          │   ← committed back to repo
                     │  (in this repo)       │
                     └──────────┬───────────┘
                                │  HTTPS (raw.githubusercontent.com)
                                ▼
                     ┌──────────────────────┐
                     │  Flutter app (Android)│
                     │  • sqflite cache       │
                     │  • on-device engine    │
                     │  • signals + portfolio │
                     │  • broker SMS parser   │
                     └──────────────────────┘
```

- Static (market) data lives in `data/` — fetched from GitHub raw, cached in sqflite.
- Personal data (watchlist, trades, debt, fee schedule, settings) lives only on the phone in sqflite. Backed up via the in-app Backup & Restore screen.
- The TypeScript backend under `core/backend/` is a **data-prep toolkit**, not a running server. It executes inside the GHA workflow only.

## Repo layout

```
nepse-buy/
├── core/
│   ├── backend/                  TypeScript / Fastify / Prisma / Postgres
│   │   ├── prisma/schema.prisma  Postgres schema (only used inside GHA)
│   │   ├── scripts/
│   │   │   ├── export-static-data.ts     dumps DB → data/*.json
│   │   │   ├── scrape-dividends.ts       ShareSansar history
│   │   │   ├── backfill-curated.ts       Nepal Stock OHLC
│   │   │   └── run-pipeline.ts           in-process pipeline (dev)
│   │   └── src/                  scrapers + signal engine + REST API (legacy)
│   └── mobile/                   Flutter / Riverpod / sqflite
│       ├── lib/
│       │   ├── core/             security, theme, network, services
│       │   ├── data/
│       │   │   ├── local/        sqflite repositories (user-personal data)
│       │   │   ├── static/       JSON-bundle client + models
│       │   │   └── repositories/ screen-facing repos (local-backed)
│       │   ├── domain/           engine (signal/fee/FIFO), broker SMS, backup
│       │   └── presentation/     screens, widgets, providers, router
│       └── test/                 49 unit tests (engine, parser, backup, security)
├── data/                         JSON bundle published by GHA
│   ├── manifest.json
│   ├── stocks.json
│   ├── signals-engine.json
│   ├── prices/<SYMBOL>.json
│   ├── fundamentals/<SYMBOL>.json
│   └── dividends/<SYMBOL>.json
└── .github/workflows/
    └── refresh-static-data.yml   manual trigger to re-scrape + republish
```

## Setup (first time)

### Prerequisites

- **Flutter SDK** (any 3.x channel)
- **JDK 17 or 21** — Android Gradle Plugin doesn't accept JDK 22+, including any `26-ea`. On Fedora: `sudo dnf install java-17-openjdk-devel`
- **Android SDK** (via Android Studio or `cmdline-tools`)
- **GitHub repo** (a fork or your own copy of this repo) so GHA can push data back

### 1. Point Flutter at JDK 17

```bash
flutter config --jdk-dir=/usr/lib/jvm/java-17-openjdk
flutter doctor -v | grep -i java
```

### 2. Generate Android platform code

The repo only contains Dart; create the Android scaffolding:

```bash
cd core/mobile
flutter create --platforms=android --org=ai.act3 --project-name=nepse_buy .
```

Edit `core/mobile/android/app/src/main/AndroidManifest.xml` and add inside `<manifest>` (above `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.READ_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

Change `<application … >` to enable system backup:

```xml
<application
    android:label="nepse_buy"
    android:icon="@mipmap/ic_launcher"
    android:allowBackup="true"
    android:fullBackupContent="@xml/backup_rules"
    android:dataExtractionRules="@xml/backup_rules">
```

Create `core/mobile/android/app/src/main/res/xml/backup_rules.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
  <include domain="database" path="nepse_buy.db"/>
  <exclude domain="sharedpref" path="FlutterSecureStorage.xml"/>
</full-backup-content>
```

Set `minSdkVersion 23` in `core/mobile/android/app/build.gradle` (required for `local_auth` + `flutter_local_notifications`).

### 3. Populate the JSON bundle

Push this repo to GitHub (or use your fork). Then on GitHub:

1. Open **Actions** → **Refresh static data** → **Run workflow**
2. Pick `action: scrape-all`, `scope: curated`
3. Wait ~10 minutes (Playwright cold start + ShareSansar + Mero Lagani + NEPSE price backfill)
4. The workflow commits `data/*.json` back to the repo

Your raw-content URL is `https://raw.githubusercontent.com/<owner>/<repo>/main/data`.

### 4. Build and install the APK

From `core/mobile/`:

```bash
flutter pub get

flutter build apk --release --dart-define=STATIC_DATA_URL=https://raw.githubusercontent.com/<owner>/<repo>/main/data
```

APK lands at `build/app/outputs/flutter-apk/app-release.apk`.

```bash
# USB-connected phone in dev mode:
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer the .apk via Drive/USB and tap to install.
# Allow "install from unknown sources" the first time.
```

For iterative dev: `flutter run --dart-define=STATIC_DATA_URL=...` with a phone or emulator attached.

### 5. First launch

1. Allow notifications when prompted (skippable — Signals still works).
2. **Settings → Security** → enable App Lock with a 4–8 digit PIN; toggle biometric if available.
3. **Settings → Backup & Restore** → export the (empty) bundle once to verify the share sheet works.
4. **Portfolio → Broker messages → sync** → grant SMS permission and let it ingest any past broker SMSes.

## Day-to-day

| Action | When | What it does |
|---|---|---|
| Open app | Daily | Engine evaluates each watchlisted symbol; Signals tab lists BUY / HOLD_FUNDS / WAIT / HARVEST |
| **Tap "Refresh"** in freshness banner | Cache > 7 days old | Re-downloads the existing JSON bundle from GitHub (seconds) |
| **Trigger GHA workflow** | Want new prices / dividends | Re-scrapes upstream + republishes JSON bundle (~10 min) |
| **Portfolio → Broker messages → sync** | After you trade on your TMS | Reads new SMSes, parses Naasa-style `(SYMBOL N kitta @ PRICE)` tuples, queues for approval |
| **Settings → Backup & Restore → Export** | Before reinstalling / new phone | Bundles watchlist + trades + debt + fees into JSON, opens share sheet (save to Drive) |

## Backend (only for development / new scrape sources)

Day-to-day you don't need this — it runs inside GitHub Actions. But for adding a new scrape source or debugging the engine:

```bash
cd core/backend
docker compose -f ../../docker-compose.dev.yml up -d postgres redis
npm install
npx prisma migrate dev
npm run db:seed:prod

# Smoke a scraper
SMOKE_INSECURE=1 npx tsx scripts/scrape-dividends.ts --curated --force

# Export DB → JSON
npx tsx scripts/export-static-data.ts --out ../../data
```

The TS engine and the Dart engine are kept in lockstep — see `core/backend/src/signals/` and `core/mobile/lib/domain/engine/`. Rationale strings are byte-equivalent so we can compare server-rendered evaluations against on-device ones during regression testing.

## Tests

```bash
# Mobile (49 tests — engine + parser + backup + security)
cd core/mobile && flutter test

# Backend (mix of unit + integration; integration needs Postgres on :5433)
cd core/backend && npm test
```

The mobile test suite is hermetic; backend integration tests fail without `docker compose up postgres` (a pre-existing condition).

## Common gotchas

- **`flutter build apk` fails with cryptic `26-ea`** → JDK 26-EA is installed. Switch to JDK 17 with `flutter config --jdk-dir=/usr/lib/jvm/java-17-openjdk`.
- **`flutter create` warning about existing files** → safe to accept; the existing Dart code under `lib/` is untouched. Run `git status` afterwards and revert anything unexpected.
- **`READ_SMS` permission** → Google Play Store disallows for unrelated apps. Since this is sideloaded for personal use, that's fine.
- **Biometric prompt no-ops on emulator** → expected; biometrics only work on real hardware. PIN is always the fallback.
- **GHA workflow can't push to a protected `main` branch** → either remove the protection on `data/` or change the workflow's commit target to a `data` branch and update `STATIC_DATA_URL` to use that branch.
- **NEPSE WASM scrape fails the first time** → TLS-fingerprint sensitive. Re-run the workflow; we have jitter + 429 abort but no challenge-rotation logic yet.

## Configuration

Build-time flags via `--dart-define=KEY=VALUE`:

| Flag | Default | Purpose |
|---|---|---|
| `STATIC_DATA_URL` | `https://raw.githubusercontent.com/act3ai/nepse-buy/main/data` | Where the app fetches JSON from |
| `API_URL` | `http://10.0.2.2:8000/api/v1` | Legacy REST endpoint (unused after pivot; safe to ignore) |

Runtime, in the app:

| Setting | Where | Default |
|---|---|---|
| PIN, biometric, auto-lock window | Settings → Security | None / 60s window |
| DCA weekly NPR (sizing helper) | `user_settings.dca_weekly_npr` row | 25 000 |

## Project status

- v0.9: static-data pivot complete (5 phases — skip-aware scraping, JSON exporter, Dart engine port, backup/restore, app lock)
- v0.10: freshness banner, local notifications, signal history, sector + price charts, one-tap trade entry, broker SMS auto-ingest with Naasa-format multi-trade fan-out + BAmt cross-check
- 49 Dart tests passing; backend test suite has pre-existing auth-integration failures unrelated to the pivot
