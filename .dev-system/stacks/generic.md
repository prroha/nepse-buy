# Generic Stack Rules

These rules apply when no specific stack file matches the project.

## General Principles
- Follow the language's official style guide.
- Use the language's standard project structure conventions.
- Prefer standard library solutions over third-party when adequate.
- Use the language's idiomatic patterns (don't write Java in Python, etc.).

## Project Structure
- Separate concerns: presentation, business logic, data access.
- Feature-based organization over type-based.
- Co-locate tests with source code.
- Shared code in explicit shared/lib/common directories.

## Dependencies
- Minimize external dependencies.
- Prefer well-maintained, widely-used libraries.
- Pin dependency versions.
- Regular security audits of dependencies.

## Testing
- Use the language's standard testing framework.
- Unit tests for business logic.
- Integration tests for boundaries (API, database).
- Test behavior, not implementation.

## Documentation
- README with setup instructions.
- API documentation (auto-generated where possible).
- Architecture decision records for major choices.
