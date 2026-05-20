---
paths:
  - "src/components/**"
  - "src/shared/components/**"
  - "src/features/*/components/**"
  - "app/**/page.tsx"
  - "app/**/layout.tsx"
  - "**/*.stories.tsx"
  - "**/*.stories.ts"
---

When working on UI files, read and follow:
- `.dev-system/rules/ui-ux-design.md` — Nielsen's heuristics, WCAG 2.1 AA, Storybook
- Every shared UI component must have a `.stories.tsx` file (CSF3, args-driven, all states)
- Touch targets >= 44x44px, contrast >= 4.5:1, semantic HTML, keyboard accessible
