---
paths:
  - "src/routes/**"
  - "src/api/**"
  - "app/api/**"
  - "src/handlers/**"
  - "src/controllers/**"
  - "**/*handler*"
  - "**/*route*"
  - "**/*controller*"
  - "**/views.py"
  - "**/viewsets.py"
---

When working on API files, read and follow:
- `.dev-system/rules/coding-standards.md` — OpenAPI section
- Active stack rules from `.dev-system/stacks/` for framework-specific OpenAPI approach
- Every endpoint must be documented in OpenAPI spec with schemas, examples, and tags
- Consistent response envelope: `{ data, error, meta }`
- Input validation at the boundary, correct HTTP status codes
