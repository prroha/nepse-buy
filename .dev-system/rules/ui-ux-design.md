# UI/UX Design Principles

Science-backed design rules for building intuitive, accessible interfaces.

## Nielsen's 10 Usability Heuristics (Implementation Guide)

### 1. Visibility of System Status
- Show loading spinners/skeletons for async operations.
- Progress bars for multi-step processes.
- Toast/snackbar for action confirmations ("Saved", "Deleted").
- Real-time validation on forms (not just on submit).
- Disable buttons during submission with visual feedback.

### 2. Match Between System and Real World
- Use natural language in labels, not technical jargon.
- Icons should be universally recognizable (or paired with text).
- Organize information in the order users expect (name before address, etc.).
- Use domain-specific terminology the user already knows.

### 3. User Control and Freedom
- Every destructive action needs a confirmation dialog or undo.
- Provide clear "back" and "cancel" paths.
- Allow dismissing modals with Escape key and overlay click.
- Support undo/redo where applicable.

### 4. Consistency and Standards
- Use a design token system (colors, spacing, typography, shadows).
- Same action = same visual treatment everywhere.
- Follow platform conventions (mobile: bottom nav, web: top nav/sidebar).
- Consistent terminology throughout (don't mix "delete"/"remove"/"discard").

### 5. Error Prevention
- Disable invalid actions rather than showing errors after the fact.
- Confirmation dialogs for irreversible actions.
- Inline validation as user types (debounced).
- Smart defaults that reduce chance of error.
- Autosave drafts for long forms.

### 6. Recognition Rather Than Recall
- Visible navigation — no hidden menus for primary actions.
- Breadcrumbs for deep hierarchies.
- Search with autocomplete/suggestions.
- Recently used items, favorites, shortcuts.
- Placeholder text showing expected format.

### 7. Flexibility and Efficiency of Use
- Keyboard shortcuts for power users.
- Bulk actions for list views.
- Customizable dashboards/views.
- Quick actions (right-click menus, swipe actions on mobile).
- Type-ahead / command palette for advanced users.

### 8. Aesthetic and Minimalist Design
- Every element should serve a purpose. No decorative-only elements.
- Whitespace is a design tool — use it generously.
- Visual hierarchy: size, color, weight to guide attention.
- Above the fold: most important content first.
- Progressive disclosure for complex interfaces.

### 9. Help Users Recognize and Recover from Errors
- Error messages in plain language (not error codes).
- Point to the exact field/location of the error.
- Suggest how to fix it ("Password must be at least 8 characters").
- Red color + icon for errors (don't rely on color alone — a11y).
- Don't clear the form on error — preserve user input.

### 10. Help and Documentation
- Tooltips for non-obvious interface elements.
- Onboarding flow for first-time users.
- Contextual help (? icons linking to relevant docs).
- Empty states with guidance ("No items yet. Create your first one.").

## Fitts's Law
**"The time to reach a target is a function of the target size and distance."**

- Primary CTAs: large, prominent, easy to reach.
- On mobile: primary actions in thumb zone (bottom of screen).
- Minimum touch target: **44x44px** (mobile), **32x32px** (desktop).
- Related actions grouped together to reduce mouse travel.
- Infinite edges: leverage screen edges/corners for frequently-used actions.
- Don't place destructive actions adjacent to primary actions.

## Hick's Law
**"Decision time increases logarithmically with the number of choices."**

- Limit choices per screen. Use progressive disclosure.
- Navigation: max **7 ± 2 items** in primary nav.
- Forms: break into multi-step wizards for > 7 fields.
- Dropdowns: group options into categories if > 10 items.
- Provide smart defaults to reduce decisions needed.
- Highlight the recommended/most common option.

## Miller's Law
**"Working memory holds 7 ± 2 chunks of information."**

- Chunk information into groups of 5-9 items.
- Use visual separators: cards, dividers, whitespace.
- Paginate lists (15-25 items per page) or use virtual scrolling.
- Dashboard widgets: max 5-7 key metrics visible at once.
- Phone numbers, credit cards: display in chunks (XXX-XXX-XXXX).

## Gestalt Principles

### Proximity
- Group related elements close together.
- Separate unrelated elements with whitespace.
- Form field + label + error = tightly grouped.

### Similarity
- Same visual style for same-type elements (all action buttons look the same).
- Differentiate different-type elements (primary vs secondary buttons).

### Continuity
- Align elements along clear visual lines/grids.
- Visual flow: top-left to bottom-right (LTR languages).
- Use lines/arrows to guide complex flows.

### Closure
- Complete visual containers (cards, panels, borders).
- Users will mentally "complete" incomplete shapes — use this for loading states.

### Figure-Ground
- Clear distinction between interactive content and background.
- Modals: dim the background to focus attention.
- Active/selected states clearly distinguishable from inactive.

## WCAG 2.1 AA Compliance

### Color and Contrast
- Text contrast ratio: **>= 4.5:1** (normal text), **>= 3:1** (large text 18px+).
- Never convey information by color alone. Use icons, patterns, or text.
- Test with color blindness simulators.

### Keyboard Accessibility
- All interactive elements focusable and operable via keyboard.
- Visible focus indicators (outline/ring) — never `outline: none` without replacement.
- Tab order follows visual reading order.
- Skip-to-content link at page top.
- Trap focus inside modals when open.

### Screen Readers
- Semantic HTML: `<nav>`, `<main>`, `<aside>`, `<article>`, `<button>`, `<a>`.
- All images: `alt` text (decorative images: `alt=""`).
- Form inputs: `<label>` elements (not just placeholders).
- ARIA labels for icon-only buttons.
- Live regions (`aria-live`) for dynamic content updates.

### Motion and Animation
- `prefers-reduced-motion` media query: disable non-essential animation.
- No auto-playing content without controls.
- Animations < 5 seconds or provide stop control.

### Forms
- Labels above or to the left of inputs (not inside as placeholders only).
- Required fields marked clearly.
- Error summary at top of form + inline errors.
- Autocomplete attributes for standard fields (name, email, address).
- Logical tab order through form fields.

## Responsive Design
- Mobile-first approach: design for smallest screen, enhance for larger.
- Breakpoints: 320px (mobile), 768px (tablet), 1024px (desktop), 1440px (wide).
- Touch targets: 44px minimum on mobile.
- No horizontal scrolling on any breakpoint.
- Test on real devices, not just browser resize.

## Component Development with Storybook

### Why Storybook
- Develop UI components in isolation — outside the app context.
- Living documentation — the Storybook IS the component catalog.
- Visual regression testing — catch unintended visual changes.
- Design-dev alignment — designers and devs share the same source of truth.

### Story Structure
- Every shared/reusable UI component MUST have a `.stories.tsx` (or `.stories.ts`) file.
- Co-locate stories with the component: `Button/Button.tsx` + `Button/Button.stories.tsx`.
- Feature-specific components: stories optional (add when component is complex or reused).

### Story Writing Rules
- **Default story**: shows the component in its most common usage.
- **Variant stories**: one story per meaningful visual/behavioral variant (size, state, theme).
- **State stories**: loading, error, empty, disabled, active, hover, focus states.
- **Interactive stories**: use `play` functions for interaction testing (click, type, navigate).
- **Args**: define all props as args with sensible defaults — enables Storybook Controls panel.
- **ArgTypes**: add descriptions, control types, and categories for clean documentation.

### Organizing Stories
```
src/
├── shared/components/ui/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.stories.tsx      # Stories
│   │   ├── Button.test.tsx         # Unit tests
│   │   └── index.ts
│   ├── Input/
│   │   ├── Input.tsx
│   │   ├── Input.stories.tsx
│   │   └── ...
```

### Story Best Practices
- Group stories by atomic design level: Atoms → Molecules → Organisms → Templates → Pages.
- Use `autodocs` tag for auto-generated documentation pages.
- Include a `Docs` page with usage guidelines, do's and don'ts.
- Add accessibility addon (`@storybook/addon-a11y`) — every story must pass a11y checks.
- Add viewport addon — show responsive behavior in stories.
- Use decorators for common wrappers (theme provider, router, store).
- Use `parameters.design` to link Figma frames (if applicable).

### Component Design Tokens in Stories
- Document the design tokens the component uses (colors, spacing, typography).
- Show the component against light and dark themes.
- Show the component at different breakpoints.

### Storybook for Design System Consistency
- The `shared/components/ui/` directory is the design system.
- Storybook is the single source of truth for component API, behavior, and appearance.
- Before creating a new UI component, check Storybook for an existing one.
- Components in Storybook are composable building blocks — app features compose them, never rewrite them.
- Run Storybook in CI: visual regression tests catch unintended changes (Chromatic, Percy, or Playwright screenshots).
