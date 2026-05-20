---
name: refactor
description: Refactor code following Clean Code principles and project patterns.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "<file, module, or description of what to refactor>"
---

# Refactor: $ARGUMENTS

## Pre-Refactor

1. **Read project profile:** `.dev-system/generated/PROJECT_PROFILE.md` — only load rules the profile lists. Skip the rest.

2. **Read rules:**
   - `.dev-system/rules/clean-code.md`
   - `.dev-system/rules/coding-standards.md`
   - `.dev-system/generated/PATTERNS.md`

2. **Read the target code** thoroughly. Understand what it does before changing it.

3. **Identify violations:**
   - Functions too long (> 50 lines)
   - Files too long (> 500 lines)
   - Duplicated code (check PATTERNS.md for existing solutions)
   - Poor naming
   - Mixed abstraction levels
   - Missing error handling
   - SOLID violations
   - Tight coupling

## Planning Phase

Present a refactoring plan:
- List each change with before/after description
- Explain why each change improves the code
- Note any risks or behavior changes
- Confirm no behavior changes (refactor = same behavior, better structure)

Wait for user approval.

## Implementation Phase

- Refactor incrementally — one change at a time.
- Ensure tests pass between changes (or note if tests need updating).
- Follow existing project patterns from PATTERNS.md.
- If extracting new abstractions, follow the Rule of Three.

## Post-Refactor

- If a new reusable pattern was established, suggest `/pattern`.
- Suggest running the test suite to verify no behavior changes.
- Summarize what was improved and why.

## Plan + Activity Log (MANDATORY after task completion)

1. **Plan**: If `.dev-system/generated/PLAN.md` exists, mark matching items done (`- [x]`). If all phase items done, mark phase `[COMPLETED]`, next phase `[IN PROGRESS]`. Update `Last updated:` date.
2. **Activity**: Append entry to `.dev-system/generated/ACTIVITY.md` (newest first, after header). Format: `## YYYY-MM-DD | /refactor | <target>` with Status, Files changed, Improvements, Remaining fields. Keep last 20 entries.
