---
name: review
description: Review recent changes for code quality, security, patterns compliance, and standards adherence.
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# Code Review

## Step 1: Load Standards (Project-Optimized)
1. Read `.dev-system/generated/PROJECT_PROFILE.md` — tells you which rules apply to this project.
2. Load ONLY the rules listed in the profile's `relevantRules`. Skip the rest.
3. Read `.dev-system/generated/PATTERNS.md`.
4. If the profile says `hasUI: false`, skip ALL UI/Storybook checks even if UI-looking files changed.

## Step 2: Get Changes
Run `git diff` to see unstaged changes, and `git diff --staged` for staged changes.
If no uncommitted changes, review the last commit: `git diff HEAD~1`.

## Step 3: Review Against Standards

For each changed file, check:

### Critical (Must Fix)
- Security vulnerabilities (XSS, injection, exposed secrets)
- Hallucinated imports (files/modules that don't exist)
- Broken type safety (`any`, type assertions without justification)
- Missing error handling at system boundaries
- Accessibility violations (missing alt text, no keyboard support)

### Warning (Should Fix)
- SOLID principle violations
- DRY violations (duplicated code that exists in PATTERNS.md)
- Functions > 50 lines
- Files > 500 lines
- Missing tests for new functionality
- Inconsistency with established patterns
- Poor naming
- Antipatterns:
  - God objects/functions (doing too many things)
  - Premature abstraction (abstracting before the Rule of Three)
  - Prop drilling (passing data through many layers instead of context/store)
  - Barrel file bloat (re-exporting everything, breaking tree-shaking)
  - Callback hell / deeply nested logic
  - Stringly-typed code (using strings where enums/unions belong)
  - Magic numbers/strings without named constants
  - Tight coupling between modules that should be independent
  - Feature envy (a function that uses more of another module's data than its own)
  - Shotgun surgery (one change requiring edits across many unrelated files)

### Suggestion (Nice to Have)
- Performance improvements
- Better naming alternatives
- Pattern opportunities (suggest `/pattern`)
- Documentation improvements
- Missing Storybook stories for shared UI components
- Missing OpenAPI documentation for API endpoints

## Step 4: Output Report

Format:
```
## Code Review Results

### Critical (X issues)
- [file:line] Description of issue

### Warnings (X issues)
- [file:line] Description of issue

### Suggestions (X items)
- [file:line] Description of suggestion

### Summary
Overall assessment and recommended next steps.
```
