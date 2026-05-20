---
name: index
description: Rebuild the project architecture index from the current codebase state.
allowed-tools: Bash, Read, Write, Glob, Grep, Agent
---

# Rebuild Architecture Index

## Step 1: Generate Base Index
Read `.dev-system/generated/PROJECT_PROFILE.md` (or fallback to `.dev-system/config.json`) for stack context.
Run: `bash .dev-system/scripts/update-architecture-index.sh > .dev-system/generated/ARCHITECTURE.md`

## Step 2: Enhance with Semantic Understanding
Read the generated file, then enhance it by:

1. **Reading key source files** to understand:
   - Application entry points and bootstrapping
   - Routing structure (pages, API routes)
   - State management approach
   - Data fetching patterns
   - Authentication/authorization flow

2. **Reading dependency manifest** (package.json, requirements.txt, etc.) to list key dependencies with their purpose (not all — just the important ones like framework, ORM, auth, UI library).

3. **Documenting data flow**: How data moves from user input → API → database → response → UI.

4. **Identifying architectural layers**: presentation, business logic, data access, infrastructure.

## Step 3: Update Pattern Registry
- Read `.dev-system/generated/PATTERNS.md`
- Check if any existing patterns reference files that no longer exist
- Flag any new patterns observed during the scan
- Update PATTERNS.md if needed

## Step 4: Clean Up
- Remove the stale marker: `rm -f .dev-system/generated/.stale`
- Write the enhanced ARCHITECTURE.md

## Step 5: Output Summary
- List the main directories and their purposes
- List any changes since the last index
- Note any patterns that may be stale or new

Keep the architecture index concise. It should be readable in under 2 minutes and use fewer than 3000 tokens. Focus on information that helps understand WHERE to find things and HOW things connect.
