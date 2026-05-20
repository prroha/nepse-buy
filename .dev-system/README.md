# .dev-system — Internal Reference

This directory contains the rules, stacks, templates, and scripts that power the dev system.
For full documentation, see the root [README.md](../README.md).

## Directory Structure

```
.dev-system/
├── config.json                    # Project config (created by /init)
├── rules/                         # On-demand rule files (5)
│   ├── anti-hallucination.md      # Prevents fabricating APIs, files, deps
│   ├── clean-code.md              # SOLID, DRY, naming, function/file limits
│   ├── coding-standards.md        # Language-specific standards, API design, OpenAPI
│   ├── ui-ux-design.md            # Nielsen's heuristics, WCAG 2.1 AA, Storybook
│   └── stack-recommendations.md   # Tech stack decision matrix (used by /init)
├── stacks/                        # Stack-specific rules (12)
│   ├── react.md    nextjs.md    vue.md    angular.md
│   ├── node-express.md    python-fastapi.md    python-django.md
│   ├── react-native.md    flutter.md    rust.md    go.md
│   └── generic.md
├── templates/
│   ├── project-types/             # Architecture blueprints
│   │   ├── web-app.md    api.md    mobile-app.md    rust-api.md
│   ├── architecture-index.md      # Template for generated index
│   └── pattern-entry.md           # Template for pattern registry entries
├── scripts/                       # Hook and utility scripts
│   ├── detect-stack.sh            # Auto-detect project stack (SessionStart hook)
│   ├── validate-edit.sh           # Block edits to protected dirs (PreToolUse hook)
│   ├── post-edit.sh               # Mark index as stale (PostToolUse hook)
│   ├── pre-compact.sh             # Re-inject context on compaction (PreCompact hook)
│   ├── stop-check.sh              # Reminders when Claude finishes (Stop hook)
│   ├── update-architecture-index.sh  # Generate base architecture index
│   └── health-check.sh            # Validate system integrity
└── generated/                     # Auto-generated — do not edit manually
    ├── ARCHITECTURE.md            # Project architecture map
    ├── PATTERNS.md                # Reusable pattern registry
    ├── PLAN.md                    # Multi-phase project plan (created by /plan)
    ├── ACTIVITY.md                # Rolling activity log (auto-updated by skills)
    └── .stale                     # Marker: index needs rebuild
```

## Adding a New Stack

1. Create `.dev-system/stacks/<name>.md` with framework-specific rules.
2. Update `scripts/detect-stack.sh` to auto-detect the new stack's manifest files.
3. Map the detected name to the stack file in `/init` SKILL.md `activeStacks` examples.

## Adding a New Rule

1. Create `.dev-system/rules/<name>.md`.
2. Reference it in the relevant skills (which skill should load it and when).
3. Add it to the "What to Read" section in `CLAUDE.md` if it should be loaded on demand.

## Health Check

```bash
bash .dev-system/scripts/health-check.sh
```

Verifies: config exists, all rule/stack files present, scripts executable, generated files exist.
