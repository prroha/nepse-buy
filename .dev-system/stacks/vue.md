# Vue.js Stack Rules

## Composition API
- Use `<script setup>` syntax (Composition API) exclusively. No Options API.
- `ref()` for primitive reactive state, `reactive()` for objects.
- `computed()` for derived values — never store derived state in ref.
- `watch()` / `watchEffect()` sparingly — prefer computed when possible.

## Component Design
- Single File Components (SFC): `<script setup>`, `<template>`, `<style scoped>`.
- Props: define with `defineProps<T>()` for type safety.
- Emits: define with `defineEmits<T>()`.
- One component per file. PascalCase file names.

## State Management (Pinia)
- One store per domain concept.
- Keep stores focused — prefer multiple small stores over one large store.
- Use getters for derived state.
- Actions for async operations and complex mutations.

## Composables
- Prefix with `use` (e.g., `useAuth`, `useFetch`).
- Return reactive refs, not raw values.
- Handle cleanup in `onUnmounted`.

## Template Best Practices
- `v-if` over `v-show` for conditional rendering (unless toggled frequently).
- `:key` on `v-for` with stable unique IDs.
- Short expressions in templates — move logic to computed properties.
- Named slots for component composition.

## Storybook
- Use `@storybook/vue3` with `<script setup>` components.
- Every shared UI component must have a `.stories.ts` file.
- Use CSF3 format: `meta` default export + named story exports.
- Pass props via `args` — Storybook auto-generates Controls from Vue prop types.
- Use decorators for Pinia stores, router, and i18n providers.
- Test slot content via story-level `render` functions.
- Organize: Atoms → Molecules → Organisms → Templates.
