# Flutter / Dart Stack Rules

## Architecture
- Feature-first folder structure.
- BLoC or Riverpod for state management.
- Repository pattern for data access.
- Use cases / interactors for business logic.

## Dart Style
- `final` by default for variables.
- Named parameters for functions with > 2 params.
- Extensions for utility methods on existing types.
- Sealed classes for state unions (Dart 3+).
- Pattern matching with switch expressions.

## Widget Design
- Small, focused widgets (extract early).
- `const` constructors where possible.
- Stateless by default, Stateful only when needed.
- Keys on list items and conditionally-rendered widgets.

## Performance
- `const` widgets to skip rebuilds.
- `ListView.builder` for long lists (never Column with map).
- Image caching with `cached_network_image`.
- Avoid rebuilding the entire tree — isolate state.

## Testing
- Unit tests for business logic.
- Widget tests for component behavior.
- Integration tests for critical flows.
- Golden tests for visual regression.
