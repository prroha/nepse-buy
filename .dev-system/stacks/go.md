# Go Stack Rules

## Project Structure
```
cmd/
├── server/
│   └── main.go             # Entry point
internal/                    # Private application code
├── handler/                 # HTTP handlers
├── service/                 # Business logic
├── repository/              # Data access
├── model/                   # Domain types
├── middleware/               # HTTP middleware
└── config/                  # Configuration
pkg/                         # Public reusable packages (if any)
migrations/                  # Database migrations
```

## Go Idioms
- Accept interfaces, return structs.
- Errors are values — handle them, don't ignore them.
- `if err != nil` immediately after the call. No deep nesting.
- Prefer table-driven tests.
- Short variable names in tight scopes (`i`, `r`, `w`), descriptive in wider scopes.
- No `init()` functions unless absolutely necessary.

## Naming
- `MixedCaps` / `mixedCaps`, never underscores in Go names.
- Package names: short, lowercase, single-word. No `utils`, `common`, `base`.
- Interfaces: single method → method name + `er` (`Reader`, `Writer`, `Closer`).
- Getters: `Name()` not `GetName()`. Setters: `SetName()`.
- Acronyms: all caps (`HTTP`, `URL`, `ID`), not `Http` or `Url`.

## Error Handling
- Wrap errors with context: `fmt.Errorf("fetching user %d: %w", id, err)`.
- Custom error types for domain errors.
- `errors.Is()` and `errors.As()` for checking, not type assertions.
- Sentinel errors (`var ErrNotFound = errors.New(...)`) for expected conditions.
- Never `panic` in library code. Reserve for truly unrecoverable situations.

## Concurrency
- Don't communicate by sharing memory; share memory by communicating (channels).
- Always know who owns the goroutine and who closes the channel.
- Use `context.Context` for cancellation and timeouts.
- `sync.WaitGroup` for fan-out/fan-in.
- `errgroup` for concurrent tasks with error handling.
- Never start a goroutine without a plan to stop it.

## HTTP (stdlib / chi / gin / echo)
- `http.Handler` / `http.HandlerFunc` interface.
- Middleware as `func(next http.Handler) http.Handler`.
- Request validation at the handler level.
- Structured logging with `slog` (Go 1.21+).
- Graceful shutdown with `context` and `os/signal`.

## Dependencies
- Minimal external dependencies. Stdlib is powerful — use it.
- `go mod tidy` to keep go.mod clean.
- Vendor only when reproducibility is critical.

## OpenAPI Documentation
- Use `swaggo/swag` for annotation-based OpenAPI generation from comments.
- Add `// @Summary`, `// @Description`, `// @Tags`, `// @Param`, `// @Success`, `// @Failure` annotations above each handler.
- Run `swag init` to generate `docs/swagger.json` and `docs/swagger.yaml`.
- Serve Swagger UI at `/swagger/` using `swaggo/http-swagger` middleware.
- Alternative: hand-maintain `openapi.yaml` and validate against handlers in CI.
- Alternative: use `ogen` for code-first OpenAPI — generates server stubs and types from the spec.
- Include request/response examples in annotations.
- Tag handlers by resource for organized docs.

## Testing
- `testing` package. `_test.go` files co-located with source.
- Table-driven tests for multiple cases.
- `testify/assert` acceptable but not required.
- `httptest` for HTTP handler tests.
- `t.Parallel()` for independent tests.
- `-race` flag in CI.
