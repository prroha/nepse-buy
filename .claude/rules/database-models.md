---
paths:
  - "src/models/**"
  - "src/db/**"
  - "src/repositories/**"
  - "prisma/**"
  - "**/migrations/**"
  - "**/*.model.ts"
  - "**/*.entity.ts"
  - "**/*.repository.ts"
---

When working on database/model files:
- Never expose internal database IDs or structures in API responses
- Migrations must be version-controlled and sequential
- Repository pattern: one repository per entity
- Transactions for multi-step operations
- Validate schema changes won't break existing API contracts
