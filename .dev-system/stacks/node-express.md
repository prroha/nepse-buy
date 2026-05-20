# Node.js / Express Stack Rules

## Project Structure
- Follow the API architecture template in `.dev-system/templates/project-types/api.md`.
- Layered architecture: routes → services → repositories.
- Middleware chain: logging → auth → validation → handler → error handler.

## Express Specifics
- Use `express.Router()` for modular route definitions.
- Async handler wrapper to catch errors: `asyncHandler(fn)`.
- Global error handling middleware (last in chain).
- Request validation middleware using Zod or Joi.
- Never access `req.body` without validation.

## Security
- Helmet.js for HTTP security headers.
- CORS configured explicitly (never `*` in production).
- Rate limiting on all endpoints.
- Input sanitization for XSS prevention.
- Parameterized queries (never string concatenation for SQL).
- bcrypt for password hashing (cost factor >= 12).

## Error Handling
- Custom error classes extending a base `AppError`.
- Error middleware logs and returns consistent error envelope.
- Never expose stack traces in production.
- Operational errors (expected) vs programmer errors (bugs) — handle differently.

## Environment
- `dotenv` for local development only.
- Config module that validates all env vars at startup (fail fast).
- Never hardcode secrets. Never commit `.env`.

## OpenAPI Documentation
- Generate OpenAPI 3.1 spec from Zod schemas using `zod-openapi` or `@asteasolutions/zod-to-openapi`.
- Register all route schemas with the OpenAPI registry.
- Serve Swagger UI at `/docs` in development (`swagger-ui-express`).
- Export `openapi.json` at `/api/openapi.json` for tooling and client generation.
- Every route handler's request/response schemas must be reflected in the spec.
- Use `tsoa` as an alternative for decorator-based OpenAPI generation.

## Database
- Connection pooling.
- Migrations in version control (sequential, timestamped).
- Repository pattern: one repository per entity.
- Transactions for multi-step operations.
