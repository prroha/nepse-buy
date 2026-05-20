---
name: scaffold
description: Generate project boilerplate and directory structure from the configured stack.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: "[component-type: project | feature <name> | component <name> | api <resource>]"
---

# Scaffold: $ARGUMENTS

Generate boilerplate following the project's configured stack and patterns.

## Step 1: Load Context

1. Read `.dev-system/generated/PROJECT_PROFILE.md` (or fallback to `.dev-system/config.json`) — get stack, project type, framework.
2. Read the relevant project template from `.dev-system/templates/project-types/<projectType>.md`.
3. Read `.dev-system/generated/PATTERNS.md` — follow existing patterns.
4. Read active stack rules from `.dev-system/stacks/<name>.md` per config.

## Step 2: Determine What to Scaffold

Based on `$ARGUMENTS`:

### `project` — Full project structure
- Create the directory tree from the project type template.
- Generate: entry point, config files, README stub, .env.example, .gitignore.
- Set up: package.json / pyproject.toml / Cargo.toml with configured dependencies.
- If Storybook in stack: add Storybook config (`.storybook/main.ts`, `preview.ts`).
- If OpenAPI in stack: add base spec file or framework config for auto-generation.
- If testing configured: add test config (vitest.config.ts, pytest.ini, etc.).

### `feature <name>` — Feature module
- Create feature directory: `src/features/<name>/`
- Generate: `components/`, `hooks/`, `services/`, `types.ts`, `index.ts` (or equivalent per stack).
- If API feature: add route handler + Zod/Pydantic schema + service + repository skeleton.

### `component <name>` — UI component
- Create: `src/shared/components/ui/<Name>/`
- Generate: `<Name>.tsx`, `<Name>.stories.tsx`, `<Name>.test.tsx`, `index.ts`.
- Follow component file structure from active stack rules.

### `api <resource>` — API resource
- Create route/handler files per stack conventions.
- Generate: handler, schema/validation, service, repository skeleton.
- Add OpenAPI annotations per stack rules.
- Add test file skeleton.

## Step 3: Generate Files

- Use the stack's idioms (not generic boilerplate).
- Include proper TypeScript types / Python type hints / Rust types.
- Add TODO comments where the user needs to fill in logic.
- Follow naming conventions from active stack.

## Step 4: Post-Scaffold

- Run `/index` to update architecture.
- If new patterns were established, suggest `/pattern`.
- List all generated files.
