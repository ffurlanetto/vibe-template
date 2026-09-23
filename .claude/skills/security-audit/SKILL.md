---
name: security-audit
description: Targeted security audit of a scope — secrets, cryptography, authentication, authorization, injection, transport. Use before exposing an endpoint, handling credentials, or shipping to production.
argument-hint: [scope to audit]
allowed-tools: Read, Glob, Grep, Bash(git log*), Bash(git diff*)
---

Perform a thorough security audit on the specified scope.
Adapt verifications to the language and stack defined in Part B of AGENTS.md.

---

## 1 · Secrets & Credentials
- Scan for `password`, `secret`, `token`, `key`, `api_key`, `bearer`, `BEGIN PRIVATE KEY`
- Verify `.gitignore` covers all local configuration files
- Verify sensitive environment variables are documented without dangerous defaults
- Verify no secret is logged, even partially
- Check git history, not just the working tree (`git log -p -S<pattern>`)

## 2 · Cryptography (if applicable)
- Algorithms: SHA-256+, AES-256, RSA-4096, ECDSA P-256+ — reject MD5, SHA-1, DES, RC4, ECB
- Randomness: language crypto module (`crypto/rand`, `secrets`, `System.Security.Cryptography`) — never `Math.random()`
- IV / Nonce randomly generated, never reused
- Keys: appropriate lifetime, rotation documented

## 3 · Authentication & Authorization
- Every endpoint / route checks authentication
- Authorization verified server-side before any sensitive operation
- Principle of least privilege applied
- Tokens: appropriate expiration, revocation possible
- No authorization bypass via URL parameters or request body

## 4 · Input validation
- All external inputs validated and sanitized server-side
- Maximum size defined for text fields (DoS prevention)
- DB queries: ORM or prepared statements — no string concatenation
- No path traversal possible on file operations
- Secure deserialization (no arbitrary types accepted)

## 5 · Logging & Audit trail
- Every sensitive operation generates an audit event
- Logs contain no PII and no secrets
- Audit log is append-only

## 6 · Transport & API
- HTTPS mandatory — no HTTP fallback
- CORS strictly configured (no `*` in production)
- Security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- Rate limiting on exposed endpoints

## 7 · Dependencies
- No known critical CVE in newly added dependencies (`make audit`)
- Versions pinned (no `latest`)
- Licences compatible with the project

## 8 · Agent & LLM surface (A11 / A12)
- MCP servers enabled are reviewed and least-privileged
- Untrusted content (web, issues, user input) is never treated as instructions
- LLM-exposed tools are scoped; write actions confirmed or audited

---

## Audit report format

```
## Security Audit — [scope] — [date]

### Overall result
🟢 PASS | 🟡 MINOR RISKS | 🔴 CRITICAL VULNERABILITIES

### Critical vulnerabilities — immediate fix required
| Severity | Location | Description | Remediation |
|----------|----------|-------------|-------------|

### Moderate risks — to schedule
| Severity | Location | Description | Remediation |
|----------|----------|-------------|-------------|

### Recommendations
- [Suggested improvement]

### Project constraints compliance (B6)
- [ ] [Constraint — status]
```

---

Scope to audit: $ARGUMENTS
