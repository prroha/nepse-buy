# Clean Code Principles

Actionable rules based on Clean Code (Robert C. Martin), SOLID, and industry best practices.

## SOLID Principles

### Single Responsibility (SRP)
- Each function does ONE thing. If you can describe it with "and," split it.
- Each file has ONE concern. A file with a component shouldn't also define API calls.
- Each module has ONE reason to change.
- Indicator of violation: function/class name contains "And" or "Or."

### Open/Closed (OCP)
- Prefer composition over modification.
- Use strategy pattern for varying behavior.
- Use middleware/plugin patterns for extensibility.
- New features should add code, not change existing code (where practical).

### Liskov Substitution (LSP)
- Subtypes must honor the contract of their parent.
- Never override a method to throw "not implemented."
- If you need to check the type before acting, the hierarchy is wrong.

### Interface Segregation (ISP)
- Small, focused interfaces over large, general ones.
- Components should not depend on props/methods they don't use.
- Split large interfaces into role-specific ones.

### Dependency Inversion (DIP)
- Depend on abstractions, not concretions.
- Inject dependencies (constructor, function params, context/providers).
- High-level modules should not import from low-level modules directly.

## DRY (Don't Repeat Yourself)
- Before writing new code, search for existing solutions in the codebase.
- Check PATTERNS.md for established patterns.
- Extract shared logic into utilities, hooks, or services.
- **Rule of Three**: Duplicate twice is OK. On the third occurrence, extract.
- **Prefer duplication over the wrong abstraction.** If the shared logic isn't truly the same concept, keep them separate.

## Naming Conventions
- Variables and functions describe what they represent/do.
- No abbreviations except industry-standard ones (URL, API, ID, HTML, CSS, DB).
- Boolean variables: `is`, `has`, `should`, `can`, `will` prefix.
- Functions that return booleans: same prefix pattern.
- Event handlers: `handle` prefix (handleClick, handleSubmit).
- Collections: plural nouns (users, items, orders).
- Maps/dictionaries: descriptive of key-value relationship (userById, ordersByDate).

## Function Design
- **Length**: Prefer under 30 lines. Refactor if > 50 lines.
- **Parameters**: Max 3 parameters. Use an options object for more.
- **Side effects**: Minimize. Pure functions when possible.
- **Return early**: Guard clauses at the top, not nested if-else chains.
- **Single level of abstraction**: Don't mix high-level orchestration with low-level details.

## File Organization
- **Length**: Prefer under 300 lines. Refactor if > 500 lines.
- **Imports**: Group by: external libs → internal modules → relative files → types.
- **Export**: Prefer named exports over default exports (better refactoring support).
- **Ordering**: Types/interfaces → constants → helper functions → main export.

## Error Handling
- Handle errors explicitly at every boundary.
- Never swallow exceptions (empty catch blocks).
- Use typed/custom error classes for domain errors.
- Provide actionable error messages: what happened + what to do about it.
- Log errors with context (what operation, what input, what state).
- Fail fast: validate inputs at function entry.

## Comments and Documentation
- Code should be self-documenting through good naming.
- Comments explain "WHY," never "WHAT" (the code shows what).
- No commented-out code — use version control.
- Complex algorithms: brief comment explaining the approach.
- Public API functions: JSDoc/docstring with parameter descriptions.
- TODO comments: include context and your name/date.

## Testing
- Test behavior, not implementation.
- One assertion concept per test.
- Test names describe the scenario: "should return empty array when no items match."
- Arrange-Act-Assert pattern.
- Don't test private/internal methods directly.
- Mock at boundaries (external services, databases), not internal modules.
