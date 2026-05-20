# React Stack Rules

## Component Design
- Functional components only. No class components.
- Props interface defined above the component, exported if needed externally.
- Destructure props in the function signature.
- One component per file. File name = component name (PascalCase).

## State Management
- `useState` for simple local state.
- `useReducer` for complex local state with multiple transitions.
- Context for low-frequency cross-cutting state (theme, auth, locale).
- External store (Zustand/Jotai) only for high-frequency shared state.
- Never put derived state in useState — compute it during render.

## Performance
- Default: do NOT memoize. Only optimize when measured.
- `React.memo()`: when a component re-renders with same props frequently.
- `useMemo`: for expensive computations (not for simple object creation).
- `useCallback`: only when passing callbacks to memoized children.
- `React.lazy()` + `Suspense` for code splitting.
- Keys: use stable IDs, never array indices.

## Hooks
- Custom hooks for reusable stateful logic.
- Hook names start with `use`.
- Keep hooks focused — one concern per hook.
- Never call hooks conditionally.

## Patterns
- Compound components for complex UI (Tabs, Accordion).
- Render props only when children need parent state.
- HOCs: avoid — use hooks instead.
- Error boundaries at route level and around unreliable features.
- Controlled components for forms (unless using React Hook Form/similar).

## File Structure
```
ComponentName/
├── ComponentName.tsx           # Component
├── ComponentName.stories.tsx   # Storybook stories (required for shared/ui components)
├── ComponentName.test.tsx      # Tests
├── useComponentLogic.ts        # Complex logic hook (if needed)
└── index.ts                    # Re-export
```

## Storybook
- Every component in `shared/components/ui/` MUST have a `.stories.tsx` file.
- Use Component Story Format (CSF3) with `meta` default export and named story exports.
- Define all props as `args` with defaults for Controls panel interactivity.
- Include stories for: default state, all variants (sizes, colors), disabled, loading, error states.
- Use `play` functions for interaction testing (click, type, assert).
- Add `@storybook/addon-a11y` — every story must pass accessibility checks.
- Use decorators for providers (theme, router, query client).
- Organize by atomic design: Atoms (Button, Input) → Molecules (SearchBar) → Organisms (Header) → Templates → Pages.
