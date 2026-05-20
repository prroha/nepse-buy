# Rust Stack Rules

## Project Structure
```
src/
├── main.rs / lib.rs        # Crate entry point
├── bin/                     # Multiple binary targets
├── models/                  # Domain types and structs
│   └── mod.rs
├── handlers/                # Request handlers (Actix/Axum)
│   └── mod.rs
├── services/                # Business logic
│   └── mod.rs
├── db/                      # Database access
│   ├── mod.rs
│   └── migrations/
├── middleware/               # HTTP middleware
├── errors.rs                # Custom error types
├── config.rs                # Configuration (from env)
└── lib.rs                   # Library root (re-exports)
tests/                       # Integration tests
benches/                     # Benchmarks
```

## Ownership & Borrowing
- Prefer borrowing (`&T`) over cloning. Clone only when ownership transfer is necessary.
- Use `&str` in function params, return `String` when the function creates new data.
- Prefer `&[T]` over `&Vec<T>` in function params.
- Use `Cow<'_, str>` when a function sometimes borrows, sometimes owns.
- Avoid unnecessary `Arc`/`Rc` — restructure ownership first.

## Error Handling
- Define custom error enums per module/crate using `thiserror`.
- Use `anyhow::Result` in application code (binaries), `thiserror` in libraries.
- `?` operator for propagation — no manual `match` on `Result` just to re-wrap.
- Never `unwrap()` or `expect()` in library code. OK in tests and infallible cases with a comment.
- `panic!` only for programmer errors (invariant violations), never for runtime conditions.

## Types & Patterns
- Newtype pattern for domain types: `struct UserId(Uuid)` — prevents mixing IDs.
- Builder pattern for complex struct construction.
- Enum + match for state machines — compiler enforces exhaustiveness.
- `impl From<A> for B` for type conversions, not manual conversion functions.
- Sealed traits for non-extensible public interfaces.
- Use `#[non_exhaustive]` on public enums/structs for forward compatibility.

## Traits & Generics
- Trait bounds: prefer `impl Trait` in args for simplicity, explicit generics when needed.
- `where` clauses for readability when bounds are complex.
- Default trait implementations where sensible.
- Derive macros: `#[derive(Debug, Clone, PartialEq)]` on most types. Add `Serialize, Deserialize` (serde) for API types.

## Naming Conventions
- `snake_case` for functions, methods, variables, modules, crates.
- `PascalCase` for types, traits, enum variants.
- `SCREAMING_SNAKE_CASE` for constants and statics.
- `is_`, `has_`, `can_` prefix for boolean-returning methods.
- Conversion methods: `as_` (cheap, borrowed), `to_` (expensive, owned), `into_` (consuming).

## Async (Tokio / async-std)
- `async fn` for I/O-bound operations.
- `tokio::spawn` for concurrent tasks, `tokio::task::spawn_blocking` for CPU-bound work.
- Never block the async runtime — no `std::thread::sleep`, use `tokio::time::sleep`.
- Use `tokio::select!` for racing futures.
- Structured concurrency: `JoinSet` or `FuturesUnordered` for managing multiple tasks.

## Web Frameworks (Axum / Actix)
- Extractors for request parsing (typed, validated).
- Shared state via `Extension` or `State` (Axum) / `Data` (Actix).
- Middleware for cross-cutting concerns (auth, logging, tracing).
- Tower layers (Axum) for composable middleware.
- `tracing` crate for structured logging (not `println!` or `log`).

## Performance
- Prefer stack allocation: arrays, small structs, enums.
- `Box<dyn Trait>` only when dynamic dispatch is truly needed.
- `Vec::with_capacity()` when the size is known.
- Iterators over manual loops — they optimize to the same code and are more expressive.
- Benchmark before optimizing: `criterion` crate for benchmarks.
- Profile with `cargo flamegraph` before guessing.

## Testing
- `#[cfg(test)] mod tests` in each module for unit tests.
- `tests/` directory for integration tests.
- `#[should_panic]` for expected panics.
- `proptest` or `quickcheck` for property-based testing.
- Test helpers: use `mod test_utils` or builder patterns for fixtures.
- Mock traits for external dependencies (use `mockall` or manual mocks).

## Cargo & Dependencies
- `cargo clippy` — treat warnings as errors in CI.
- `cargo fmt` — enforce consistent formatting.
- `cargo audit` — check for known vulnerabilities.
- Minimize dependencies. Prefer std library solutions when adequate.
- Feature flags for optional functionality.
- Workspace (`Cargo.toml` with `[workspace]`) for multi-crate projects.

## Unsafe
- Avoid `unsafe` unless absolutely necessary.
- Every `unsafe` block must have a `// SAFETY:` comment explaining the invariant.
- Encapsulate unsafe in a safe abstraction.
- Prefer well-audited crates over writing your own unsafe code.

## OpenAPI Documentation
- Use `utoipa` crate for derive-macro-based OpenAPI 3.1 generation.
- Add `#[derive(ToSchema)]` on all request/response DTOs.
- Add `#[utoipa::path(...)]` attribute on all handler functions with summary, description, request body, responses.
- Register all paths and schemas in `#[derive(OpenApi)]` struct.
- Serve Swagger UI using `utoipa-swagger-ui` at `/swagger-ui/` in development.
- Include `example` attributes on struct fields for request/response examples.
- Tag handlers by resource using `tag = "resource-name"`.
- Alternative: use `aide` crate for Axum-native OpenAPI generation.

## Documentation
- `///` doc comments on all public items.
- `//!` module-level docs at the top of `mod.rs` / `lib.rs`.
- Include examples in doc comments (`/// # Examples`).
- `#[doc(hidden)]` for public items that are implementation details.
