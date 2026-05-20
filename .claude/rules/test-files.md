---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/*_test.go"
  - "**/*_test.py"
  - "**/test_*.py"
  - "**/tests/**"
  - "tests/**"
---

When writing tests:
- Test behavior, not implementation. One assertion concept per test.
- Arrange-Act-Assert pattern. Descriptive test names: "should [expected] when [condition]".
- Mock at boundaries (external services, databases), not internal modules.
- Never test private/internal methods directly.
- Co-locate test files with source: `Button.tsx` + `Button.test.tsx`.
- Use factory pattern for test data — no hardcoded fixtures scattered across files.
