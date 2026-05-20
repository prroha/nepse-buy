---
name: security
description: Security audit — OWASP Top 10, dependency vulnerabilities, secrets, and auth patterns.
allowed-tools: Bash, Read, Glob, Grep, Agent
argument-hint: "[file-or-scope (optional)]"
---

# Security Audit: $ARGUMENTS

## Step 1: Determine Scope

**If `$ARGUMENTS` specified**: audit that scope.
**Otherwise**: audit the full project.

Read `.dev-system/generated/PROJECT_PROFILE.md` (or fallback to `.dev-system/config.json`) for stack context. Only run checks relevant to the project's capabilities (e.g., skip UI checks if `hasUI: false`).

## Step 2: OWASP Top 10 Check

Scan the codebase for these vulnerability classes:

### A01: Broken Access Control
- Grep for unprotected routes (routes without auth middleware)
- Check for missing authorization checks (role/permission guards)
- Look for direct object references without ownership validation
- Check CORS configuration (never `*` in production)

### A02: Cryptographic Failures
- Grep for hardcoded secrets, API keys, passwords (patterns: `password =`, `secret =`, `api_key =`, `token =`)
- Check .env files are gitignored
- Look for weak hashing (MD5, SHA1 for passwords — should be bcrypt/argon2)
- Check TLS/HTTPS enforcement

### A03: Injection
- SQL: grep for string concatenation in queries (should use parameterized)
- XSS: grep for `dangerouslySetInnerHTML`, `v-html`, unescaped user input in templates
- Command injection: grep for `exec`, `spawn`, `system` with user input
- Path traversal: grep for user input in file paths without sanitization

### A04: Insecure Design
- Check for rate limiting on auth endpoints
- Check for account lockout after failed attempts
- Look for missing CSRF protection on state-changing endpoints

### A05: Security Misconfiguration
- Check for debug mode in production config
- Check for default credentials
- Check security headers (Helmet.js, security middleware)
- Check for verbose error messages exposing internals

### A07: Auth Failures
- Check token storage (httpOnly cookies, not localStorage)
- Check session management
- Check password requirements enforcement
- Look for JWT without expiration or with weak signing

### A08: Software & Data Integrity
- Check for dependency vulnerabilities: run `npm audit`, `pip audit`, `cargo audit`, or `govulncheck`
- Check for pinned dependency versions
- Look for integrity checks on external resources (SRI for CDN scripts)

### A09: Logging & Monitoring
- Check for structured logging on auth events
- Check that sensitive data is NOT logged (passwords, tokens, PII)
- Check for request ID propagation

### A10: SSRF
- Grep for user-controlled URLs in fetch/HTTP calls without allowlist

## Step 3: Secrets Scan

```
Grep for patterns:
- API keys: /[A-Za-z0-9_-]{20,}/
- AWS keys: /AKIA[0-9A-Z]{16}/
- Private keys: /-----BEGIN.*PRIVATE KEY-----/
- Connection strings with passwords
- .env files committed to git
```

## Step 4: Report

```
## Security Audit Report

### Critical (Immediate Fix Required)
- [file:line] [Vulnerability class] Description

### High (Fix Before Deploy)
- [file:line] [Vulnerability class] Description

### Medium (Fix Soon)
- [file:line] [Vulnerability class] Description

### Low (Hardening)
- [file:line] [Vulnerability class] Description

### Dependency Vulnerabilities
[Output of npm audit / pip audit / cargo audit]

### Summary
- Critical: X | High: X | Medium: X | Low: X
```

## Step 5: Offer to Fix

Fix in priority order: Critical → High → Medium → Low.
