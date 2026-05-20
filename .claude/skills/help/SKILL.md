---
name: help
description: Show all available dev-system commands, hooks, and features.
allowed-tools: Read
argument-hint: "[command-name (optional)]"
---

# Dev System Help

## If `$ARGUMENTS` is empty — show everything:

Output this:

```
## Dev System Commands

| Command | Purpose |
|---------|---------|
| /init | Detect stack (existing) or recommend optimal stack (new project) |
| /plan <desc> | Create, view, or update a multi-phase project plan |
| /add <desc> | Plan and implement a feature following project patterns |
| /fix <desc> | Diagnose and fix a bug with anti-hallucination safeguards |
| /refactor <target> | Refactor code against Clean Code / SOLID principles |
| /review | Code review: security, quality, patterns, standards |
| /revisit | Self-audit for rule violations, hallucinations, missed standards |
| /pattern <name> | Register a reusable pattern in the pattern registry |
| /ui <desc> | Design and build a UI component (UX + a11y + Storybook) |
| /test | Run project tests and report results |
| /scaffold <type> | Generate boilerplate: project, feature, component, api |
| /security | OWASP Top 10 audit, dependency scan, secrets detection |
| /index | Rebuild the architecture index |
| /help [cmd] | Show this list, or details for a specific command |

## Hooks (Automatic)

| Hook | Trigger | What It Does |
|------|---------|--------------|
| SessionStart | Session begins | Auto-detects stack, shows plan status + recent activity |
| PreToolUse (Edit/Write) | Before file edits | Blocks edits to node_modules, .git, dist, build |
| PostToolUse (Edit/Write) | After file edits | Marks architecture index as stale |
| Stop | Claude finishes | Reminds about stale index, suggests /revisit if many files changed |
| PreCompact | Context compacting | Re-injects config, modified files list, stale warnings |

## Path-Specific Rules (Auto-Loaded)

| Rule File | Triggers When Editing |
|-----------|----------------------|
| `.claude/rules/ui-components.md` | Components, pages, layouts, .stories files |
| `.claude/rules/api-endpoints.md` | Routes, handlers, controllers, views |
| `.claude/rules/database-models.md` | Models, repositories, migrations, schemas |
| `.claude/rules/test-files.md` | Test files (*.test.ts, *.spec.ts, *_test.go, etc.) |

These load automatically — no manual "read this file" needed.

## Rules (On-Demand)

| Rule | Loaded By |
|------|-----------|
| `anti-hallucination.md` | /fix, /review, /revisit |
| `clean-code.md` | /refactor, /review, /revisit |
| `coding-standards.md` | /add (API), /review, /revisit |
| `ui-ux-design.md` | /ui, /review (if UI), /revisit (if UI) |
| `stack-recommendations.md` | /init (new projects only) |

## Project Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Session instructions (loaded every session) |
| `.claude/settings.json` | Hooks and permissions configuration |
| `.dev-system/config.json` | Project stack configuration (created by /init) |
| `.dev-system/generated/ARCHITECTURE.md` | Architecture index (rebuild with /index) |
| `.dev-system/generated/PATTERNS.md` | Reusable pattern registry |
| `.dev-system/generated/PLAN.md` | Multi-phase project plan (created by /plan) |
| `.dev-system/generated/ACTIVITY.md` | Rolling activity log (auto-updated by skills) |
| `.dev-system/stacks/<name>.md` | Stack-specific rules and patterns |
```

## If `$ARGUMENTS` names a specific command:

Read `.claude/skills/<command>/SKILL.md` and output a concise summary: what it does, what it reads, and its workflow steps.
