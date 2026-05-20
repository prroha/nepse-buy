# Coding Standards

## JavaScript / TypeScript (Airbnb-based)

### Variables and Declarations
- `const` by default. `let` only when reassignment is needed. Never `var`.
- Destructure objects and arrays at point of use.
- Template literals over string concatenation.
- Nullish coalescing (`??`) over logical OR (`||`) for defaults.
- Optional chaining (`?.`) over manual null checks.

### Functions
- Arrow functions for callbacks and inline functions.
- Named function declarations for top-level functions (better stack traces).
- Explicit return types on all exported functions (TypeScript).
- Async/await over raw Promises. Never mix .then() and await.

### TypeScript Specific
- `strict: true` in tsconfig — non-negotiable.
- `interface` for object shapes, `type` for unions/intersections/primitives.
- `readonly` for properties that shouldn't be mutated.
- No `any`. Use `unknown` with type narrowing if the type is truly unknown.
- Discriminated unions for state variants (loading/success/error).
- Zod or similar for runtime validation at system boundaries.

### Imports and Modules
- Barrel exports (`index.ts`) for public module APIs.
- Path aliases (`@/components`, `@/lib`) over deep relative imports.
- No circular dependencies.
- Dynamic imports for code splitting (lazy-loaded routes, heavy components).

### React Specific
- Functional components only (no class components).
- Custom hooks for shared stateful logic.
- Memoize expensive computations (useMemo) and callbacks (useCallback) — but not by default, only when profiling shows need.
- Keys: stable, unique identifiers — never array index.
- Co-locate component + styles + tests in the same directory.

## API Design (Google API Design Guide)

### Resource Naming
- RESTful: nouns, plural (`/users`, `/orders`).
- Hierarchical: `/users/{userId}/orders/{orderId}`.
- Actions as sub-resources: `POST /orders/{id}/cancel` (not `/cancelOrder`).
- Lowercase, hyphen-separated: `/user-profiles` (not `/userProfiles`).

### Request / Response
- Consistent envelope: `{ data, error, meta }`.
- Pagination: cursor-based preferred, offset/limit acceptable.
- Filtering: query params (`?status=active&sort=-createdAt`).
- Partial responses: `?fields=id,name,email`.

### Status Codes
- 200: Success. 201: Created. 204: No Content.
- 400: Bad Request. 401: Unauthorized. 403: Forbidden. 404: Not Found. 409: Conflict. 422: Validation Error.
- 500: Internal Error. 503: Service Unavailable.
- Never return 200 with an error body.

### Versioning
- URL path versioning: `/api/v1/users`.
- Major version only. Breaking changes = new version.

### Data Transfer
- Request DTOs separate from domain models.
- Response DTOs separate from domain models.
- Never expose internal database IDs or structures directly.
- Dates in ISO 8601 format (UTC).

### OpenAPI Documentation
- Every API MUST have an OpenAPI 3.1 spec (or the framework's auto-generated equivalent).
- Spec file: `openapi.yaml` or `openapi.json` at project root, or auto-generated from code.
- Every endpoint must document: summary, description, request body schema, response schemas (success + errors), auth requirements.
- Use `$ref` and `components/schemas` for reusable types — never duplicate schemas.
- Include `examples` for request/response bodies.
- Tag endpoints by resource/domain for organization.
- Version the spec alongside code — spec changes = code changes in the same commit.
- Serve interactive docs in development (Swagger UI, Redoc, or framework built-in).
- **Framework-specific approaches:**
  - FastAPI: auto-generates from Pydantic models — ensure all models have `Field(description=...)` and `model_config` with `json_schema_extra` examples.
  - Django REST: use `drf-spectacular` for OpenAPI 3.1 generation from serializers.
  - Express/Hono: use `zod-openapi` or `@asteasolutions/zod-to-openapi` to generate from Zod schemas.
  - Next.js API routes: maintain a manual `openapi.yaml` or use `next-swagger-doc`.
  - Go: use `swaggo/swag` annotations or hand-maintain `openapi.yaml`.
  - Rust (Axum): use `utoipa` crate for derive-macro-based OpenAPI generation.
- CI should validate that the spec matches the implementation (spec drift detection).

## File and Folder Structure

### Feature-Based Organization
```
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── services/
│   │   ├── types.ts
│   │   └── index.ts
│   └── orders/
├── shared/
│   ├── components/
│   ├── hooks/
│   ├── lib/
│   ├── types/
│   └── utils/
├── app/                 # Routes / pages
└── styles/              # Global styles only
```

### Conventions
- Feature folders contain everything for that feature.
- `shared/` contains truly shared, cross-feature code.
- Co-locate tests: `Button.tsx` + `Button.test.tsx` in same directory.
- One component per file. File name matches component name.
- Index files export the public API of each module.

## Git Conventions

### Commit Messages
- Format: `type(scope): description`
- Types: feat, fix, refactor, test, docs, chore, perf, style, ci
- Scope: feature or module name
- Description: imperative mood, lowercase, no period
- Example: `feat(auth): add password reset flow`

### Branching
- `main` — production-ready code
- `feat/description` — new features
- `fix/description` — bug fixes
- `refactor/description` — refactoring
