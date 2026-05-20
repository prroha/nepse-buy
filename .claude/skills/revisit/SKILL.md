---
name: revisit
description: Review changed code for rule violations, hallucinations, and dev-system compliance.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "[file-or-scope (optional)]"
---

# Revisit — Self-Audit Against Dev System Rules

Honest self-check of code written this session. Flag everything, don't minimize.

## Step 1: Determine Scope

**If `$ARGUMENTS` specifies a file or directory**: audit that scope.
**Otherwise**: identify files modified this session from conversation context.
- Fallback: `git diff --name-only HEAD` and `git diff --name-only --cached`.
- No git? Ask the user which files to audit.

## Step 2: Load Rules (Project-Optimized)

1. Read `.dev-system/generated/PROJECT_PROFILE.md` — this tells you exactly what rules apply to this project.
2. Read `.dev-system/config.json` — for active stacks and capabilities.
3. **Only load rules listed in `relevantRules`** from the profile. Skip everything else.
4. Further narrow by classifying modified files:
   - **UI files**: `.tsx`, `.vue`, `.svelte`, `.html`, files in `components/`, `pages/`, `app/`
   - **API files**: `route.ts`, `handler`, `controller`, `views.py`, `routes/`, `handlers/`
   - If `hasUI` is false in config capabilities, skip ALL UI checks even if a `.tsx` file was edited (it's likely a non-UI component).
   - If `hasAPI` is false, skip ALL OpenAPI checks.
5. Load `PATTERNS.md` and active stack rules only.

Do NOT load rules the project profile says to skip.

## Step 3: Audit — Hallucination Check

**Actually verify with tools** — do NOT just reason about it.

For each modified file, use Glob/Grep/Read to verify:
- Every import path points to a real file
- Every imported symbol exists in the target module
- Every dependency is in the manifest (package.json, requirements.txt, etc.)
- Every API endpoint matches actual route definitions
- Every env variable exists in .env.example or config
- Every type/interface reference resolves to a real definition

Flag anything unverifiable.

## Step 4: Audit — Rule Compliance

Apply the rules you loaded in Step 2. Check each modified file against:
- **clean-code.md**: SOLID, function/file length, DRY, error handling, naming
- **coding-standards.md**: language-specific rules, API design (if applicable)
- **PATTERNS.md**: was an existing pattern available but not reused?
- **Stack rules**: framework-specific idioms and conventions

Do NOT restate the rules here — you already read the files. Apply them.

## Step 5: Audit — UI/UX & Storybook (Only If UI Files Changed)

Skip entirely if no UI files were modified.

Check against `ui-ux-design.md` rules:
- Accessibility (WCAG 2.1 AA), loading/error/empty states, touch targets, semantic HTML
- **Storybook**: shared UI components must have `.stories.tsx` with default + variant + state stories

## Step 6: Audit — OpenAPI (Only If API Files Changed)

Skip entirely if no API files were modified.

Check against `coding-standards.md` OpenAPI section + active stack rules:
- Spec exists and covers modified endpoints
- Schemas, examples, tags, and interactive docs present
- Framework-specific approach followed

## Step 7: Report

```
## Revisit Audit Report

### Scope
- Files audited: [list]
- Rules loaded: [list]

### Findings
| Severity | Category | Location | Issue | Fix |
|---|---|---|---|---|
| CRITICAL | Hallucination | file:line | [what's wrong] | [how to fix] |
| WARNING | Clean Code | file:line | [what's wrong] | [how to fix] |
| INFO | Standards | file:line | [what's wrong] | [how to fix] |

### Summary
- Checks: X | Passed: X | Failed: X
- Severity: [CLEAN | MINOR ISSUES | NEEDS FIXES | CRITICAL]
```

Only include sections with findings. Don't pad the report with PASSing checks.

## Step 8: Offer to Fix

If issues found, ask:
> Want me to fix these? I'll go in priority order: hallucinations → clean code → standards → OpenAPI → Storybook → UI/UX.
