---
description: Targeted security audit — secrets, cryptography, authentication, authorization, injection
---

Perform a thorough security audit on the specified scope.
Adapt verifications to the language and stack defined in Part B of CLAUDE.md.

---

## 1 · Secrets & Credentials

- Scan files for patterns: `password`, `secret`, `token`, `key`, `api_key`, `bearer`, `BEGIN PRIVATE KEY`
- Verify `.gitignore` covers all local configuration files
- Verify sensitive environment variables have documented names (without dangerous default values)
- Verify no secret is logged (even partially)

## 2 · Cryptography (if applicable)

- Algorithms used: SHA-256+, AES-256, RSA-4096, ECDSA P-256+ — reject MD5, SHA-1, DES, RC4, ECB
- Random generation: language crypto module (`crypto/rand`, `secrets`, `System.Security.Cryptography`…) — never `Math.random()`
- IV / Nonce: randomly generated, never reused
- Keys: appropriate lifetime, rotation documented

## 3 · Authentication & Authorization

- Every endpoint / route checks authentication
- Authorizations are verified before any sensitive operation (not client-side only)
- Principle of least privilege applied
- Tokens: appropriate expiration, revocation possible
- No authorization bypass via URL parameters or body

## 4 · Input validation

- All external inputs are validated and sanitized server-side
- Maximum size defined for text fields (DoS prevention)
- DB queries: ORM or prepared statements — no string concatenation
- No path traversal possible on file operations
- Secure deserialization (no arbitrary types accepted)

## 5 · Logging & Audit trail

- Every sensitive operation generates an audit event
- Logs do not contain personal data (PII) or secrets
- Audit log is append-only (no modification possible after write)

## 6 · Transport & API

- HTTPS mandatory — no HTTP fallback
- CORS strictly configured (no `*` in production)
- Security headers present: CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- Rate limiting on exposed endpoints

## 7 · Dependencies

- No known critical CVE in newly added dependencies
- Versions pinned (no `latest`)
- Licenses compatible with the project

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
- [ ] [Constraint 1 — status]
- [ ] [Constraint 2 — status]
```

---

Scope to audit: $ARGUMENTS
