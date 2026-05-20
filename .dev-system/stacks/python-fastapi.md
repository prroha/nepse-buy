# Python / FastAPI Stack Rules

## Project Structure
```
src/
├── api/
│   ├── routes/             # Route definitions
│   ├── deps.py             # Dependency injection
│   └── middleware.py       # Custom middleware
├── core/
│   ├── config.py           # Settings (pydantic-settings)
│   ├── security.py         # Auth utilities
│   └── exceptions.py       # Custom exceptions
├── models/                 # SQLAlchemy/Pydantic models
├── schemas/                # Pydantic request/response schemas
├── services/               # Business logic
├── repositories/           # Data access
└── main.py                 # App factory
```

## FastAPI Specifics
- Pydantic models for ALL request/response validation.
- Dependency injection via `Depends()` for auth, db sessions, etc.
- `async def` for I/O-bound endpoints, `def` for CPU-bound.
- Background tasks for non-blocking operations.
- Proper status codes in response model decorators.

## Python Style
- Type hints on all function signatures.
- f-strings over `.format()` or `%`.
- dataclasses or Pydantic models over plain dicts.
- `pathlib.Path` over `os.path`.
- Context managers for resource management.
- List comprehensions over `map()`/`filter()` for readability.

## Testing
- pytest with fixtures.
- `httpx.AsyncClient` for API tests.
- Factory pattern for test data (factory_boy or custom).
- Separate test database.

## OpenAPI Documentation
- FastAPI auto-generates OpenAPI 3.1 — leverage this fully.
- Every Pydantic model must have `Field(description="...")` on all fields.
- Add `model_config` with `json_schema_extra = {"examples": [...]}` for request/response examples.
- Use `tags` parameter on all route decorators to organize endpoints by domain.
- Add `summary` and `description` to every route decorator.
- Define all possible `responses` (error codes + schemas) on each endpoint.
- Customize the generated docs title, description, and version in the FastAPI app constructor.
- Docs are served at `/docs` (Swagger UI) and `/redoc` (Redoc) by default — keep both enabled in development.
- For production: consider disabling interactive docs or restricting access.

## Error Handling
- Custom exception classes.
- Exception handlers registered on the app.
- `HTTPException` for known HTTP errors.
- Never return 200 with error body.
