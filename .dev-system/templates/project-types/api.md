# API Architecture Template

## Recommended Structure
```
src/
├── routes/                 # Route definitions (controllers)
│   └── <resource>/
│       ├── handler.ts      # Request handlers
│       ├── schema.ts       # Request/response validation schemas
│       └── index.ts        # Route registration
├── services/               # Business logic layer
│   └── <domain>.service.ts
├── repositories/           # Data access layer
│   └── <entity>.repository.ts
├── models/                 # Domain models / entities
│   └── <entity>.model.ts
├── middleware/              # Express/Fastify middleware
│   ├── auth.ts
│   ├── error-handler.ts
│   ├── validate.ts
│   └── rate-limit.ts
├── lib/                    # Shared utilities
│   ├── database.ts         # DB connection
│   ├── logger.ts           # Logging
│   ├── errors.ts           # Custom error classes
│   └── config.ts           # Environment config
├── types/                  # Shared type definitions
└── index.ts                # App entry point
```

## Layered Architecture
1. **Route/Controller**: HTTP concerns only (parse request, send response).
2. **Service**: Business logic. Framework-agnostic. Testable in isolation.
3. **Repository**: Data access. Abstracts the database.
4. **Model**: Domain entities. Pure data structures.

## Key Patterns
- **Request validation**: Validate at the route level using Zod/Joi schemas.
- **Error handling**: Global error middleware. Custom error classes (NotFoundError, ValidationError, AuthError).
- **Response envelope**: Consistent `{ data, error, meta }` shape.
- **Authentication**: Middleware-based. JWT or session-based.
- **Logging**: Structured JSON logs. Request ID tracking.
- **Rate limiting**: Per-endpoint and per-user.
- **Health check**: `GET /health` endpoint.
- **API versioning**: URL path (`/api/v1/`).
- **Database migrations**: Version-controlled, sequential.
