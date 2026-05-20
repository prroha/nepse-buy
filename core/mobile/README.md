# nepse-buy — Flutter app

The mobile half of [nepse-buy](../../README.md). See the root README for architecture, setup, and day-to-day usage.

## Quick reference

```bash
# Install deps
flutter pub get

# Run on a connected device or emulator
flutter run --dart-define=STATIC_DATA_URL=https://raw.githubusercontent.com/<owner>/<repo>/main/data

# Build a release APK
flutter build apk --release --dart-define=STATIC_DATA_URL=https://raw.githubusercontent.com/<owner>/<repo>/main/data

# Run the test suite (49 tests)
flutter test
```

## Layout

```
lib/
├── core/
│   ├── notifications/   local-notification scheduling
│   ├── security/        app-lock service + PIN hasher
│   ├── theme/, network/, services/
├── data/
│   ├── local/           sqflite repositories (user-personal data + broker inbox)
│   ├── static/          JSON-bundle client + Dart models
│   └── repositories/    screen-facing repos (entity contracts; locally backed)
├── domain/
│   ├── engine/          signal + fee + FIFO engine (Dart port of backend TS)
│   ├── backup/          user-data export/import
│   └── broker_sms/      Naasa-format parser + scanner
└── presentation/
    ├── screens/         signals, portfolio, watchlist, discover, stock_detail,
    │                    debt, settings, broker_inbox, signal_history, …
    ├── widgets/         charts (sector pie, price line), molecules, atoms
    ├── providers/       Riverpod state
    └── router/          go_router config
```

## Schema versions

- v1 — KV cache + outbox queue
- v2 — `user_watchlist`, `user_trades`, `user_debt_accounts`, `user_fee_schedule`, `user_settings`
- v3 — `local_signal_history`, `pending_broker_messages`
- v4 — `pending_broker_messages.trade_index` + `bill_amount` (multi-trade SMS fan-out + fee cross-check)
