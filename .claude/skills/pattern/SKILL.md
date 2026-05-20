---
name: pattern
description: Register a new coding pattern in the project pattern registry.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: "<pattern name>"
---

# Add Pattern: $ARGUMENTS

## Step 1: Read Current Registry
Read `.dev-system/generated/PATTERNS.md` to:
- Get the next pattern ID (PAT-XXX)
- Ensure this pattern doesn't already exist

## Step 2: Gather Pattern Details
Ask the user (or determine from context) for:
1. **Pattern name**: Short, descriptive name
2. **Canonical example**: File path of the best implementation of this pattern
3. **When to use**: Situations where this pattern applies
4. **Description**: Brief explanation of how the pattern works

## Step 3: Verify the Example
Read the canonical example file to ensure it exists and is a good reference.

## Step 4: Register
Append to `.dev-system/generated/PATTERNS.md`:

```markdown
## PAT-XXX: <Pattern Name>
- **Location**: <canonical example file path>
- **Usage**: <when to use this pattern>
- **Description**: <how the pattern works>
- **Example**: See <file path>
```

## Step 5: Confirm
Output the registered pattern details and remind the user that this pattern will be suggested for reuse in future `/add` calls.
