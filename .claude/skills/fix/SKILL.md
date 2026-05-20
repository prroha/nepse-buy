---
name: fix
description: Diagnose and fix a bug systematically with anti-hallucination safeguards.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "<bug description>"
---

# Fix Bug: $ARGUMENTS

## Rules
- Read `.dev-system/generated/PROJECT_PROFILE.md` first — only load rules the profile lists. Skip the rest.
- Read `.dev-system/rules/anti-hallucination.md` — always.
- Do NOT guess at the cause. Investigate systematically.
- Do NOT fix unrelated code. Minimal, focused fix only.

## Diagnosis Phase

1. **Understand the bug**: What is the expected behavior? What is the actual behavior?
2. **Read the architecture index**: `.dev-system/generated/ARCHITECTURE.md` — understand where the bug likely lives.
3. **Trace the code path**:
   - Start from the user-facing symptom (UI component, API endpoint, etc.)
   - Follow the code path through each layer
   - Read EVERY file in the path — do not assume what the code does
4. **Form a hypothesis**: Based on actual code read, not assumptions.
5. **Verify the hypothesis**: Find evidence in the code that confirms the root cause.

## Proposal Phase

Present to the user:
- **Root cause**: What is actually wrong and why
- **Evidence**: The specific code/logic that causes the bug
- **Fix**: The minimal change needed
- **Risk**: What else could be affected

Wait for user approval before implementing.

## Implementation Phase

- Make the minimal fix. Do not refactor surrounding code.
- Do not change function signatures unless absolutely necessary.
- Preserve existing behavior for all non-buggy code paths.

## Verification Phase

- Suggest or write a test that would have caught this bug.
- If the bug was in a pattern, check if other instances of that pattern have the same issue.
- Verify the fix doesn't break existing tests: suggest running the test suite.

## Plan + Activity Log (MANDATORY after task completion)

1. **Plan**: If `.dev-system/generated/PLAN.md` exists, mark matching items done (`- [x]`). If all phase items done, mark phase `[COMPLETED]`, next phase `[IN PROGRESS]`. Update `Last updated:` date.
2. **Activity**: Append entry to `.dev-system/generated/ACTIVITY.md` (newest first, after header). Format: `## YYYY-MM-DD | /fix | <summary>` with Status, Root cause, Files changed, Remaining fields. Keep last 20 entries.
