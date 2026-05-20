---
name: ui
description: Design and implement a UI component following UX science and accessibility standards.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "<component or page description>"
---

# Design UI: $ARGUMENTS

## Pre-Design (MANDATORY)

1. **Read project profile:** `.dev-system/generated/PROJECT_PROFILE.md` — only load rules the profile lists. Skip the rest.

2. **Read rules:**
   - `.dev-system/rules/ui-ux-design.md` — full UX principles
   - `.dev-system/generated/PATTERNS.md` — existing component patterns
   - `.dev-system/config.json` — styling framework (Tailwind, CSS Modules, etc.)

2. **Search for existing components:**
   - Look for similar components in the codebase
   - Check the shared/components directory
   - Identify reusable building blocks

## Design Phase

Present the design approach BEFORE implementing:

### Component Structure
- Component hierarchy (what composes what)
- Props interface
- State management approach

### UX Decisions (reference the principle)
- **Layout**: Based on Gestalt principles (proximity, similarity)
- **Interaction**: Based on Fitts's Law (target sizes, placement)
- **Information architecture**: Based on Hick's Law & Miller's Law
- **Feedback**: Based on Nielsen's heuristics (system status, error recovery)

### Accessibility Plan
- Keyboard navigation flow
- Screen reader announcements
- ARIA attributes needed
- Color contrast compliance

Wait for user approval.

## Implementation Phase

- Semantic HTML first, ARIA only when HTML semantics are insufficient.
- Keyboard support: all interactive elements focusable and operable.
- Focus management: logical tab order, focus trapping in modals.
- Responsive: mobile-first, test at all breakpoints.
- Loading states for async content.
- Error states with recovery guidance.
- Empty states with helpful messaging.
- `prefers-reduced-motion` for animations.

## Storybook Stories (MANDATORY for shared/reusable components)

After implementing the component, create a `.stories.tsx` (or `.stories.ts`) file:

1. **Co-locate** the story file with the component.
2. **Default story**: most common usage with sensible default args.
3. **Variant stories**: one per visual/behavioral variant (size, color, theme).
4. **State stories**: loading, error, empty, disabled, active states.
5. **Interactive stories**: add `play` functions for interaction testing where relevant.
6. **Args & ArgTypes**: define all props as args with descriptions and control types.
7. **Accessibility**: ensure all stories pass `@storybook/addon-a11y` checks.
8. **Responsive**: show the component at mobile, tablet, and desktop viewports.

Follow the Storybook rules in `.dev-system/rules/ui-ux-design.md` and the active stack file.

## Post-Implementation

- Verify contrast ratios meet WCAG 2.1 AA (4.5:1 for text).
- Verify all interactive elements have visible focus indicators.
- Verify keyboard-only navigation works.
- Verify Storybook stories render correctly and cover all states.
- Suggest testing with a screen reader.
- If this establishes a new component pattern, suggest `/pattern`.
