---
name: add
description: Plan and implement a new feature following project patterns and standards.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "<feature description>"
---

# Add Feature: $ARGUMENTS

## Pre-Implementation (MANDATORY — do not skip)

1. **Read project profile:**
   - `.dev-system/generated/PROJECT_PROFILE.md` — tells you what applies to this project
   - `.dev-system/generated/ARCHITECTURE.md` — project structure
   - `.dev-system/generated/PATTERNS.md` — existing patterns to reuse

2. **Read ONLY relevant rules** (as listed in PROJECT_PROFILE.md):
   - `.dev-system/rules/anti-hallucination.md` — always
   - Other rules ONLY if the profile lists them (skip rules the profile says to skip)
   - Stack-specific rules from `.dev-system/stacks/` per `config.json → activeStacks`

3. **Search for reusable code:**
   - Search the codebase for similar implementations
   - Check if existing utilities, hooks, or services can be extended
   - Identify patterns from PATTERNS.md that apply

## Planning Phase

Present a plan to the user BEFORE writing any code:

- **What**: Brief description of the feature
- **Where**: Files to create and files to modify
- **Patterns**: Which existing patterns will be reused
- **New patterns**: Any new patterns this feature establishes
- **Dependencies**: Any new packages needed (justify each one)
- **Tests**: What tests will be written

Wait for user approval before proceeding.

## Implementation Phase

- Follow all rules from CLAUDE.md and the relevant rule files.
- Reuse existing patterns — do NOT reinvent.
- Keep functions small and focused (SRP).
- Add proper error handling at boundaries.
- Write tests alongside implementation.
- If UI: follow ui-ux-design.md principles + create Storybook stories for all shared/reusable components.
- If API: ensure all endpoints have OpenAPI documentation (auto-generated or annotated per stack rules).

## Post-Implementation

1. If new directories or key files were created, suggest running `/index`.
2. If a new reusable pattern was established, suggest running `/pattern`.
3. Summarize what was built and any follow-up items.

## Plan + Activity Log (MANDATORY after task completion)

1. **Plan**: If `.dev-system/generated/PLAN.md` exists, mark matching items done (`- [x]`). If all phase items done, mark phase `[COMPLETED]`, next phase `[IN PROGRESS]`. Update `Last updated:` date. Tell the user what was marked done.
2. **Activity**: Append entry to `.dev-system/generated/ACTIVITY.md` (newest first, after header). Format: `## YYYY-MM-DD | /add | <name>` with Status, Files changed, Key decisions, Remaining fields. Keep last 20 entries.
