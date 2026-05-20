# Anti-Hallucination Rules

These rules prevent Claude from fabricating information. They apply to ALL tasks.

## APIs and Libraries
- NEVER reference an API endpoint without verifying it exists in the codebase or official docs.
- NEVER use a library function without confirming it exists in the installed version.
- NEVER invent function signatures, method names, or class properties.
- When suggesting a third-party library, verify it exists and is actively maintained.
- If you cannot verify an API or function, explicitly say: "I'm not certain this exists — please verify."

## File System
- NEVER assume a file or directory exists. Use Glob or Read to confirm.
- NEVER create import paths without verifying the target file exists.
- NEVER guess at the export structure of a module — read it first.
- When referencing configuration files, read them to confirm their structure.

## Dependencies
- NEVER assume a specific version of a dependency. Read the lock file or manifest.
- NEVER assume a dependency is installed. Check package.json/requirements.txt/etc.
- NEVER assume the API of a dependency based on a different version.
- When using a dependency feature, verify it's available in the installed version.

## Configuration and Environment
- NEVER guess configuration values, environment variables, or secrets.
- Read existing config files (.env.example, config files) to determine the pattern.
- NEVER assume default values for configuration without checking the framework docs.

## Error Messages and Debugging
- NEVER fabricate error messages, stack traces, or log output.
- Only reference actual errors from tool output (Bash, terminal, etc.).
- When diagnosing a bug, trace through actual code — never hypothesize about code you haven't read.

## Third-Party Services
- NEVER assume how a third-party service, API, or library behaves internally.
- Reference only documented, verified behavior.
- If external docs are needed and unavailable, say so.

## Code Patterns
- NEVER assume the codebase follows a particular pattern without checking.
- Read PATTERNS.md and actual code before applying or extending patterns.
- When you see an unfamiliar pattern in the codebase, ask about it rather than assuming it's wrong.

## Self-Correction Protocol
1. If you realize you may have stated something unverified, immediately flag it.
2. Stop the current line of reasoning.
3. Verify the claim using available tools (Read, Glob, Grep, Bash).
4. Correct yourself explicitly: "I stated X, but after checking, Y is correct."
5. Continue only after verification.

## Verification Checklist (Before Every Implementation)
- [ ] All imports reference files that exist
- [ ] All function calls match actual signatures in the codebase
- [ ] All API endpoints match the actual route definitions
- [ ] All type references match actual type definitions
- [ ] All environment variables match .env.example or existing config
- [ ] All dependency usages match the installed version's API
