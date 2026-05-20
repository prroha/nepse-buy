# Rust API Architecture Template

## Recommended Structure (Axum)
```
src/
├── main.rs                 # Entry point: server setup, router, graceful shutdown
├── config.rs               # Env-based config (dotenvy + serde)
├── errors.rs               # AppError enum, IntoResponse impl
├── lib.rs                   # Re-exports for integration tests
├── routes/
│   ├── mod.rs              # Router composition
│   ├── health.rs           # GET /health
│   └── <resource>/
│       ├── mod.rs          # Sub-router
│       ├── handlers.rs     # Request handlers
│       └── models.rs       # Request/response DTOs
├── services/               # Business logic (no HTTP concerns)
│   └── <domain>.rs
├── db/
│   ├── mod.rs              # Pool setup
│   ├── repositories/       # Data access (sqlx queries)
│   │   └── <entity>.rs
│   └── migrations/         # sqlx migrations
├── middleware/
│   ├── auth.rs             # JWT/session validation
│   └── tracing_layer.rs    # Request tracing
└── domain/                 # Core domain types
    └── <entity>.rs
tests/
├── common/mod.rs           # Shared test setup (test db, test client)
└── api/                    # Integration tests per resource
```

## Key Patterns
- **Layered**: handlers → services → repositories. Each layer only calls the one below.
- **AppState**: Shared via Axum `State<Arc<AppState>>` — holds db pool, config, services.
- **Error handling**: `AppError` enum implements `IntoResponse`. All handlers return `Result<Json<T>, AppError>`.
- **Extractors**: Custom extractors for auth (`AuthUser`), validated JSON (`ValidJson<T>`).
- **Migrations**: sqlx migrations, run at startup or via CLI.
- **Tracing**: `tracing` + `tracing-subscriber` for structured logs. Request ID propagation.
- **Graceful shutdown**: `tokio::signal` for SIGTERM handling.
