# Angular Stack Rules

## Components
- Standalone components (no NgModules for new code).
- `OnPush` change detection strategy by default.
- Smart (container) vs Dumb (presentational) component split.
- Input/Output decorators with explicit types.

## Signals (Angular 17+)
- Prefer signals over RxJS for component state.
- `signal()` for writable state, `computed()` for derived.
- `effect()` for side effects (sparingly).

## RxJS
- Use for streams and async operations in services.
- Always unsubscribe: `takeUntilDestroyed()`, `async` pipe, or `DestroyRef`.
- Avoid nested subscribes — use `switchMap`, `mergeMap`, `concatMap`.
- `shareReplay(1)` for shared observables.

## Services
- Injectable services for business logic and API calls.
- `providedIn: 'root'` for singleton services.
- Feature-level providers for scoped services.

## Forms
- Reactive forms for complex forms (not template-driven).
- Typed form groups (`FormGroup<T>`).
- Custom validators as pure functions.

## File Structure
```
feature/
├── feature.component.ts
├── feature.component.html
├── feature.component.scss
├── feature.component.spec.ts
├── feature.component.stories.ts    # Storybook (required for shared components)
├── feature.service.ts
├── feature.routes.ts
└── index.ts
```

## Storybook
- Use `@storybook/angular` with standalone components.
- Every component in `shared/components/` must have a `.stories.ts` file.
- CSF3 format: `meta` default export with `moduleMetadata` for providers/imports.
- Use `argsToTemplate` helper for automatic template generation from args.
- Include stories for all `@Input()` variants, state combinations, and interaction flows.
- Use decorators for dependency injection (services, stores).
- Angular-specific: use `componentWrapperDecorator` for layout context.
- Organize by atomic design: Atoms → Molecules → Organisms → Templates.
