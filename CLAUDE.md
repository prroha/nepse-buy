# Dev System — Project Instructions
<!-- Keep under 100 lines. Loaded every session. -->

## First-Run & Project Profile
- If `.dev-system/config.json` does not exist or has `"initialized": false`, run `/init` before anything else.
- After `/init`, the system auto-optimizes: `.dev-system/generated/PROJECT_PROFILE.md` tells you exactly which rules, skills, and checks apply to THIS project. **Read it before every task.** Skip anything the profile marks as irrelevant.

## Critical Rules (Always Active)

### Anti-Hallucination
- NEVER invent APIs, libraries, functions, methods, or CLI flags. If unsure, say so.
- NEVER guess file paths. Use Glob/Grep to verify.
- NEVER assume dependency versions. Read the manifest first.
- NEVER fabricate error messages or configuration values.
- If you may have hallucinated, STOP, flag it, and verify before continuing.

### Code Quality
- SOLID principles. Single responsibility for functions, classes, files.
- DRY: Check `.dev-system/generated/PATTERNS.md` before writing new code.
- Max 50 lines per function, 500 lines per file.
- Composition over inheritance. Inject dependencies.
- Self-documenting code. Comments explain "why," never "what."
- No dead code. Handle errors explicitly. Write tests.

## What to Read (On Demand)
- **First**: `.dev-system/generated/PROJECT_PROFILE.md` — tells you what's relevant for this project.
- **Every task**: `.dev-system/generated/ARCHITECTURE.md` + `PATTERNS.md`
- **Only load rules listed in PROJECT_PROFILE.md** → do NOT load rules the profile says to skip.
- **Stack rules**: load from `.dev-system/stacks/<name>.md` per `config.json → activeStacks`
- **Path-specific rules** in `.claude/rules/` auto-load for UI, API, DB, and test files.

## Architecture & Patterns
- Architecture index: `.dev-system/generated/ARCHITECTURE.md`
- If `.dev-system/generated/.stale` exists → run `/index` after current task.
- Pattern registry: `.dev-system/generated/PATTERNS.md`
- ALWAYS check patterns before creating new abstractions. Reuse over reinvent.

## Commands
Run `/help` for the full list. Key commands:

| Cmd | Purpose |
|-----|---------|
| `/init` | Detect stack, auto-optimize system for this project |
| `/plan <desc>` | Create or update a multi-phase project plan |
| `/add <desc>` | Implement a feature |
| `/fix <desc>` | Diagnose and fix a bug |
| `/refactor <target>` | Refactor against Clean Code |
| `/review` | Code review |
| `/revisit` | Self-audit for violations |
| `/ui <desc>` | Design UI component |
| `/scaffold <type>` | Generate boilerplate |
| `/security` | OWASP audit |
| `/test` | Run tests |
| `/index` | Rebuild architecture index |
| `/pattern <name>` | Register pattern |
| `/help [cmd]` | Show all commands |

**Note**: PROJECT_PROFILE.md lists which commands apply to this project. Don't suggest irrelevant ones (e.g., no `/ui` for API-only projects).

## Project Plan & Activity Log
- `.dev-system/generated/PLAN.md` — optional multi-phase project plan. Created via `/plan`. Persists across sessions.
- `.dev-system/generated/ACTIVITY.md` — rolling log of recent `/add`, `/fix`, `/refactor` tasks.
- Both are auto-surfaced on SessionStart for cross-session continuity.
- Skills auto-update plan progress and append activity entries after completing work.
- If starting a new session and plan/activity is shown, read the relevant files to understand context before starting new work.

## Compaction — Preserve These
- Current task description + progress
- Modified files list
- `.dev-system/generated/PROJECT_PROFILE.md` contents
- Active test/build commands
- User decisions/approvals from this session
- Recent activity from `.dev-system/generated/ACTIVITY.md`
- Current plan phase from `.dev-system/generated/PLAN.md`
