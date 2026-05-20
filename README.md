# Dev System

A portable, stack-aware development system for [Claude Code](https://claude.ai/claude-code) that enforces clean code, prevents hallucinations, and guides optimal architecture decisions across any project.

Drop it into any repository. Run `/init`. Start building.

## What It Does

- **Detects your stack** automatically (or recommends the optimal one for new projects)
- **Enforces code quality** — SOLID, DRY, function/file limits, error handling
- **Prevents hallucinations** — verifies imports, dependencies, and APIs exist before using them
- **Guides UI/UX** — Nielsen's heuristics, WCAG 2.1 AA, Storybook-first component development
- **Documents APIs** — OpenAPI 3.1 spec generation per framework conventions
- **Tracks architecture** — auto-indexed project structure and reusable pattern registry
- **Audits security** — OWASP Top 10, dependency vulnerabilities, secrets detection
- **Scaffolds boilerplate** — generates project structure, features, components, API resources

## Quick Start

```bash
# 1. Copy the dev-system into your project
cp -r .dev-system/ /path/to/your-project/.dev-system/
cp -r .claude/ /path/to/your-project/.claude/
cp CLAUDE.md /path/to/your-project/CLAUDE.md

# 2. Open your project with Claude Code
cd /path/to/your-project
claude

# 3. Initialize
/init
```

For **new projects**, `/init` runs the recommendation engine — it asks about your requirements (scale, real-time, timeline, etc.) and recommends the optimal stack with trade-off analysis.

For **existing projects**, `/init` auto-detects your stack from manifest files and configures rules accordingly.

## Commands

| Command | Purpose |
|---------|---------|
| `/init` | Detect stack (existing) or recommend optimal stack (new project) |
| `/plan <desc>` | Create, view, or update a multi-phase project plan |
| `/add <desc>` | Plan and implement a feature following project patterns |
| `/fix <desc>` | Diagnose and fix a bug with anti-hallucination safeguards |
| `/refactor <target>` | Refactor code against Clean Code / SOLID principles |
| `/review` | Code review: security, quality, patterns, standards |
| `/revisit` | Self-audit for rule violations, hallucinations, missed standards |
| `/pattern <name>` | Register a reusable pattern in the pattern registry |
| `/ui <desc>` | Design and build a UI component (UX + a11y + Storybook) |
| `/test` | Run project tests and report results |
| `/scaffold <type>` | Generate boilerplate: `project`, `feature <name>`, `component <name>`, `api <resource>` |
| `/security` | OWASP Top 10 audit, dependency scan, secrets detection |
| `/index` | Rebuild the architecture index |
| `/help [cmd]` | List all commands, or show details for a specific command |

## Supported Stacks

Auto-detection and stack-specific rules for:

| Frontend | Backend | Mobile |
|----------|---------|--------|
| React | Node.js / Express | React Native (Expo) |
| Next.js (App Router) | Python / FastAPI | Flutter |
| Vue / Nuxt | Python / Django | |
| Angular | Go | |
| | Rust (Axum / Actix) | |

Falls back to a generic ruleset for unlisted stacks.

## How It Works

### Auto-Optimization Per Project

After `/init`, the system generates a **Project Profile** (`.dev-system/generated/PROJECT_PROFILE.md`) that optimizes itself for your specific project:

- Detects **capabilities**: `hasUI`, `hasAPI`, `hasDatabase`, `hasAuth`, `hasTests`
- Lists only the **relevant rules** — a pure API project skips `ui-ux-design.md` entirely
- Lists only the **relevant skills** — no `/ui` for API-only, no `/security` for static sites
- Includes **build/test/dev commands** so Claude knows how to run things
- Specifies **rules to SKIP** — Claude never wastes tokens loading rules that don't apply

Every skill reads the profile first and only loads what's needed. This means a Rust API project loads ~200 fewer tokens per skill invocation than a full-stack Next.js app, because it skips UI rules, Storybook checks, and frontend standards.

### Token-Efficient Architecture

- **`CLAUDE.md`** (~74 lines) — loaded every session. Contains only critical rules and command reference.
- **Project Profile** — loaded on SessionStart. Tells Claude exactly what applies to this project.
- **Rules** — loaded on-demand by skills, only those listed in the profile.
- **Path-specific rules** — auto-loaded by Claude Code when you edit matching files. Zero cost until triggered.
- **Stack files** — only the active stack(s) are loaded, not all 12.
- **PreCompact hook** — re-injects the profile (not raw config) on context compaction.

### Hooks (Automatic Lifecycle Events)

| Hook | Trigger | What It Does |
|------|---------|--------------|
| `SessionStart` | Session begins | Auto-detects stack, shows plan status + recent activity |
| `PreToolUse` | Before file edits | Blocks edits to `node_modules`, `.git`, `dist`, `build` |
| `PostToolUse` | After file edits | Marks architecture index as stale |
| `PreCompact` | Context compacting | Re-injects config, modified files, stale warnings |
| `Stop` | Claude finishes | Reminds about stale index, suggests `/revisit` if 5+ files changed |

### Path-Specific Rules (Auto-Loaded)

Rules that activate automatically based on which files you're editing:

| Rule | Triggers When Editing |
|------|----------------------|
| `ui-components.md` | Components, pages, layouts, `.stories` files |
| `api-endpoints.md` | Routes, handlers, controllers, views |
| `database-models.md` | Models, repositories, migrations, schemas |
| `test-files.md` | Test files (`*.test.ts`, `*.spec.ts`, `*_test.go`, etc.) |

### On-Demand Rules

Detailed rule files loaded by specific commands:

| Rule | What It Covers | Loaded By |
|------|---------------|-----------|
| `anti-hallucination.md` | Prevents fabricating APIs, files, dependencies | `/fix`, `/review`, `/revisit` |
| `clean-code.md` | SOLID, DRY, naming, function/file limits | `/refactor`, `/review`, `/revisit` |
| `coding-standards.md` | Language-specific standards, API design, OpenAPI | `/add`, `/review`, `/revisit` |
| `ui-ux-design.md` | Nielsen's heuristics, WCAG 2.1 AA, Storybook | `/ui`, `/review`, `/revisit` |
| `stack-recommendations.md` | Tech stack decision matrix | `/init` (new projects only) |

## Project Structure

```
your-project/
├── CLAUDE.md                          # Session instructions (66 lines, always loaded)
├── .claude/
│   ├── settings.json                  # Hooks configuration
│   ├── settings.local.json            # Local permissions (not committed)
│   ├── skills/                        # 15 command skills
│   │   ├── init/SKILL.md
│   │   ├── plan/SKILL.md
│   │   ├── add/SKILL.md
│   │   ├── fix/SKILL.md
│   │   ├── refactor/SKILL.md
│   │   ├── review/SKILL.md
│   │   ├── revisit/SKILL.md
│   │   ├── pattern/SKILL.md
│   │   ├── ui/SKILL.md
│   │   ├── test/SKILL.md
│   │   ├── scaffold/SKILL.md
│   │   ├── security/SKILL.md
│   │   ├── index/SKILL.md
│   │   └── help/SKILL.md
│   └── rules/                         # Path-specific rules (auto-loaded)
│       ├── ui-components.md
│       ├── api-endpoints.md
│       ├── database-models.md
│       └── test-files.md
├── .dev-system/
│   ├── config.json                    # Stack configuration (created by /init)
│   ├── rules/                         # On-demand rule files
│   │   ├── anti-hallucination.md
│   │   ├── clean-code.md
│   │   ├── coding-standards.md
│   │   ├── ui-ux-design.md
│   │   └── stack-recommendations.md
│   ├── stacks/                        # Stack-specific rules (12 stacks)
│   │   ├── react.md
│   │   ├── nextjs.md
│   │   ├── vue.md
│   │   ├── angular.md
│   │   ├── node-express.md
│   │   ├── python-fastapi.md
│   │   ├── python-django.md
│   │   ├── go.md
│   │   ├── rust.md
│   │   ├── react-native.md
│   │   ├── flutter.md
│   │   └── generic.md
│   ├── templates/                     # Architecture templates
│   │   └── project-types/
│   │       ├── web-app.md
│   │       ├── api.md
│   │       ├── mobile-app.md
│   │       └── rust-api.md
│   ├── scripts/                       # Hook scripts
│   │   ├── detect-stack.sh
│   │   ├── validate-edit.sh
│   │   ├── post-edit.sh
│   │   ├── pre-compact.sh
│   │   ├── stop-check.sh
│   │   ├── update-architecture-index.sh
│   │   └── health-check.sh
│   └── generated/                     # Auto-generated (by /init, /index, /plan)
│       ├── ARCHITECTURE.md
│       ├── PATTERNS.md
│       ├── PLAN.md                    # Multi-phase project plan (created by /plan)
│       ├── ACTIVITY.md                # Rolling activity log (auto-updated by skills)
│       └── .stale                     # Marker: index needs rebuild
```

## Key Design Principles

### Anti-Hallucination First
Every skill verifies before acting. Imports are checked with Glob. Dependencies are confirmed in manifests. APIs are validated against route definitions. If something can't be verified, Claude flags it instead of guessing.

### Token Efficiency
CLAUDE.md stays under 100 lines. Rules load on-demand. Path-specific rules auto-load only when relevant files are touched. The PreCompact hook preserves critical context during compaction. No rule content is duplicated across skills.

### Stack-Aware
The system adapts its guidance to your specific framework. A Next.js project gets App Router patterns, Server Components rules, and `@storybook/nextjs` setup. A FastAPI project gets Pydantic validation, dependency injection, and auto-generated OpenAPI docs. Each stack gets idiomatic patterns, not generic advice.

### Reuse Over Reinvent
The pattern registry (`PATTERNS.md`) tracks reusable abstractions. Every skill checks it before creating new code. `/pattern` registers new patterns. The architecture index gives Claude a map of the codebase without reading every file.

## Extending the System

### Add a New Stack

Create `.dev-system/stacks/<name>.md` with framework-specific rules. Update `detect-stack.sh` to auto-detect the new stack's manifest files.

### Add a New Skill

Create `.claude/skills/<name>/SKILL.md` with frontmatter (`name`, `description`, `allowed-tools`) and workflow steps. Add it to the commands table in `CLAUDE.md`, `/help`, and `health-check.sh`.

### Add a Path-Specific Rule

Create `.claude/rules/<name>.md` with a `paths` frontmatter array and the rules to apply when those files are edited.

### Add a Hook

Edit `.claude/settings.json` to add new hooks at lifecycle events. Currently configured: `SessionStart`, `Stop`, `PreToolUse`, `PostToolUse`, `PreCompact`. Other available events include `PostCompact`, `Notification`, `SubagentStart`, `SubagentStop`, and more.

## Requirements

- [Claude Code CLI](https://claude.ai/claude-code) installed and configured
- Bash shell (for hook scripts)
- Git (for change tracking and architecture indexing)
