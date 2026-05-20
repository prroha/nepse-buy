---
name: init
description: Initialize the dev system — detects or asks for tech stack, creates config, indexes architecture.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: "[project-type: web-app|mobile-app|api]"
---

# Initialize Dev System

Follow these steps carefully:

## Step 1: Check Existing Initialization
- Read `.dev-system/config.json` if it exists.
- If `initialized: true`, ask the user if they want to re-initialize. If no, stop.

## Step 2: Detect Existing Project or Identify New Project

Run `bash .dev-system/scripts/detect-stack.sh` to check for existing project files.

### Path A — Existing Project (stack detected):
Present auto-detected findings and ask the user to confirm or correct.
Ask for anything the script couldn't detect (database, ORM, testing, etc.).

### Path B — New Project (no project files detected):
The script will report "No known project files detected." — this triggers the **Recommendation Engine**.

**Go to Step 2b.**

## Step 2b: Recommendation Engine (New Projects Only)

Read `.dev-system/rules/stack-recommendations.md` for the full decision matrix.

Follow this flow:

### 2b.1: Gather Requirements
Ask the user (adapt — skip what's obvious from context or `$ARGUMENTS`):
1. **What are you building?** (Brief description)
2. **Project type?** web-app | mobile-app | api | full-stack | CLI tool
3. **Key requirements?** (real-time, offline, SEO, heavy computation, file uploads, auth, payments, background jobs, search, etc.)
4. **Scale expectations?** Hobby/MVP | Startup | Growth | Scale
5. **Team context?** Solo | Small team | Larger team
6. **Deployment preference?** Serverless | Container | VPS | Edge | No preference
7. **Timeline?** Prototype | MVP | Production
8. **Hard constraints?** (existing infra, team expertise, client requirements, budget)

If `$ARGUMENTS` provides context (e.g., "a real-time chat app"), use it to pre-fill answers and skip redundant questions.

### 2b.2: Recommend Stack
Using the decision matrix from `stack-recommendations.md`, recommend the optimal stack. Present it as a table:

```
## Recommended Stack for [Project Name]

Based on your requirements ([key factors]):

| Layer | Choice | Why |
|---|---|---|
| Frontend | ... | ... |
| Backend | ... | ... |
| Database | ... | ... |
| ORM | ... | ... |
| Styling | ... | ... |
| Auth | ... | ... |
| Testing | ... | ... |
| Deployment | ... | ... |

### Why This Stack?
[2-3 sentences — why these pieces fit together]

### Alternatives Considered
- **[Alternative]**: Better if [condition]. Chose [recommended] because [reason].

### Trade-offs
- [Downsides or things to watch out for]
```

### 2b.3: Confirm
Ask the user:
- Does this look right?
- Want to adjust any layer?
- Any constraints I missed?

### 2b.4: Finalize
Once confirmed, use the recommended stack to populate config values and proceed to Step 3.

## Step 3: Write Config
Create `.dev-system/config.json`:
```json
{
  "schemaVersion": 2,
  "initialized": true,
  "projectName": "<name>",
  "projectType": "<web-app|mobile-app|api|full-stack|cli>",
  "stack": {
    "language": "<language>",
    "framework": "<framework>",
    "styling": "<styling or null>",
    "testing": "<testing framework>",
    "packageManager": "<package manager>",
    "database": "<database or null>",
    "orm": "<orm or null>"
  },
  "capabilities": {
    "hasUI": true/false,
    "hasAPI": true/false,
    "hasDatabase": true/false,
    "hasAuth": true/false,
    "hasTests": true/false
  },
  "relevantRules": ["<only the rule files this project needs>"],
  "relevantSkills": ["<only the skills that apply to this project>"],
  "detectedAt": "<ISO 8601 timestamp>",
  "userConfirmed": true,
  "activeStacks": ["<stack-file-names without .md>"]
}
```

### Determining `capabilities`:
- `hasUI`: true if projectType is web-app, mobile-app, or full-stack; or if framework is React/Vue/Angular/Next.js/Flutter/React Native
- `hasAPI`: true if projectType is api or full-stack; or if framework is Express/FastAPI/Django/Axum/Go; or if the project has `src/api/`, `app/api/`, or route files
- `hasDatabase`: true if database is not null
- `hasAuth`: true if the project has auth middleware, auth providers, or auth-related dependencies
- `hasTests`: true if testing framework is not null

### Determining `relevantRules`:
Based on capabilities, include ONLY what applies:
- **Always**: `anti-hallucination.md`, `clean-code.md`
- **hasUI**: add `ui-ux-design.md`
- **hasAPI**: add `coding-standards.md`
- **Neither UI nor API** (CLI/library): only `anti-hallucination.md`, `clean-code.md`, `coding-standards.md`

### Determining `relevantSkills`:
- **Always**: `init`, `add`, `fix`, `refactor`, `pattern`, `review`, `revisit`, `test`, `index`, `help`
- **hasUI**: add `ui`, `scaffold` (with component support)
- **hasAPI**: add `scaffold` (with api support), `security`
- **hasDatabase**: add `scaffold` (with model support)

### `activeStacks` mapping:
- Next.js project → `["nextjs", "react"]`
- React Native → `["react-native", "react"]`
- FastAPI → `["python-fastapi"]`
- Rust Axum → `["rust"]`
- Unknown → `["generic"]`

## Step 4: Generate Architecture Index
1. Run `bash .dev-system/scripts/update-architecture-index.sh > .dev-system/generated/ARCHITECTURE.md`
2. Read the generated file, then enhance it:
   - Read key source files to understand data flow
   - Read the dependency manifest to list key dependencies with their purpose
   - Document main architectural layers
3. Write the enhanced version back to `.dev-system/generated/ARCHITECTURE.md`

## Step 5: Initialize Pattern Registry
**Existing project**: Scan for common patterns (repeated file structures, shared utilities, hooks, base classes). Register 3-5 key patterns.
**New project**: Create empty registry.

Write to `.dev-system/generated/PATTERNS.md`:
```markdown
# Pattern Registry
Updated: <ISO 8601 timestamp>

<!-- Use /pattern to register new patterns. -->
```

## Step 6: Create Stale Marker
Run: `rm -f .dev-system/generated/.stale` (index is fresh after init).

## Step 7: Generate Project Profile

Create `.dev-system/generated/PROJECT_PROFILE.md` — a compact, project-specific context file that optimizes every future session.

Based on `config.json` capabilities, generate:

```markdown
# Project Profile: [projectName]
<!-- Auto-generated by /init. Loaded on SessionStart. Do not edit manually. -->

## Stack
[language] / [framework] | [styling] | [testing] | [database] | [orm]

## This Project Uses
- [only list what capabilities are true — e.g., "UI (React + Tailwind + Storybook)", "API (REST + OpenAPI)", "Database (PostgreSQL + Prisma)"]

## This Project Does NOT Use
- [list what's false — e.g., "No UI components", "No database"]
- [IMPORTANT: This tells Claude to SKIP loading these rules and checks]

## Rules to Load
- Always: `anti-hallucination.md`, `clean-code.md`
- [conditional]: `ui-ux-design.md` (only if hasUI)
- [conditional]: `coding-standards.md` (only if hasAPI)
- Stack: [list activeStacks files]

## Rules to SKIP
- [list rules NOT in relevantRules — Claude should NEVER load these]

## Available Commands
[list only relevantSkills — don't show /ui for a pure API project, don't show /security for a static site]

## Build & Test Commands
- Test: [detected test command, e.g., "npm test", "pytest", "cargo test"]
- Build: [detected build command, e.g., "npm run build", "cargo build"]
- Lint: [detected lint command if any]
- Dev: [detected dev command, e.g., "npm run dev"]
```

**This file is loaded by the SessionStart hook instead of the raw config.json, giving Claude only what it needs for this specific project.**

## Step 8: Summarize
Output:
- Project name, type, and stack
- Number of source files found
- Patterns registered (if any)
- Capabilities detected (hasUI, hasAPI, hasDatabase, etc.)
- Available commands (only relevant ones)
- Token optimization: which rules and skills were excluded
