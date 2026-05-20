---
name: test
description: Run project tests and report results.
allowed-tools: Bash, Read, Glob, Grep
argument-hint: "[file or pattern to test]"
---

# Run Tests

## Step 1: Detect Test Runner
Read `.dev-system/generated/PROJECT_PROFILE.md` (or fallback to `.dev-system/config.json`) to determine the testing framework and package manager.

If config doesn't specify, detect from project files:
- `vitest.config.*` or package.json has "vitest" → `npx vitest`
- package.json has "jest" → `npx jest`
- `pytest.ini` or `pyproject.toml` with pytest → `pytest`
- `Cargo.toml` → `cargo test`
- `go.mod` → `go test ./...`
- `pubspec.yaml` → `flutter test`

## Step 2: Determine Scope
- If `$ARGUMENTS` is empty → run ALL tests
- If `$ARGUMENTS` is a file path → run tests for that file only
- If `$ARGUMENTS` is a pattern/keyword → run matching tests

## Step 3: Run Tests
Execute the appropriate test command. Show the full output.

## Step 4: Report
If tests fail:
- List each failing test with the error message
- Suggest a fix for each failure (read the failing test + source code)
- Ask if the user wants you to fix the failures

If all tests pass:
- Report the count of tests passed
- Note test coverage if available
