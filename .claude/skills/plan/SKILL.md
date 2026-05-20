---
name: plan
description: Create, view, or update a multi-phase project plan for cross-session continuity.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: "<description> | status | update <phase> <status> | revise"
---

# Project Plan: $ARGUMENTS

## Determine Action

- **No arguments or "status"** → Show current plan status
- **"update <phase> <status>"** → Update a specific phase or item
- **"revise"** → User wants to change the plan — discuss and rewrite
- **Anything else** → Create or discuss a new plan

## Action: Show Status

1. Read `.dev-system/generated/PLAN.md`. If missing, say "No plan exists. Describe what you're building and I'll help you plan it."
2. Display: current phase (`[IN PROGRESS]`), progress (checked/unchecked), next unchecked item, and summary of completed/pending phases.

## Action: Create Plan

1. **Discuss first** — understand the full scope before writing anything.
2. **Draft phases** (3-6 max). Each phase should be independently deliverable, ordered by dependency, and completable in 1-3 sessions.
3. **Present the plan** for user approval. Do NOT write until approved.
4. **Write** `.dev-system/generated/PLAN.md`:

```markdown
# Project Plan: <Project Name>
Created: YYYY-MM-DD | Last updated: YYYY-MM-DD

## Overview
<2-3 sentence summary>

## Phase 1: <Name> [IN PROGRESS]
- [ ] Item 1
- [ ] Item 2

## Phase 2: <Name> [PENDING]
- [ ] Item 1
- [ ] Item 2
```

- Items should be concrete tasks mapping to roughly one `/add` or `/fix` invocation
- Convert relative dates to absolute dates (e.g., "next week" → "2026-03-25")
- Keep file under 100 lines — details belong in `/add` invocations, not the plan
- Only ONE phase `[IN PROGRESS]` at a time

## Action: Update Phase/Item

1. Read `.dev-system/generated/PLAN.md`
2. Mark items done (`- [x]`), update phase status (`[COMPLETED]`/`[IN PROGRESS]`). When all phase items checked, mark phase `[COMPLETED]` and next phase `[IN PROGRESS]`.
3. Update `Last updated:` date. Write the file.

## Action: Revise Plan

1. Read current plan, discuss changes with user, rewrite with approval.
2. Preserve completed phases as-is. If skipping a phase, mark `[SKIPPED]` with reason.
3. Update `Last updated:` date.
