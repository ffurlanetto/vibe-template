---
name: deps-audit
description: Supply-chain audit of dependencies — known CVEs, version pinning, lockfile integrity, licences, unused and duplicated packages. Use before a release and whenever a dependency is added.
argument-hint: [optional package or scope]
allowed-tools: Read, Glob, Grep, Bash(make audit), Bash(git diff*), Bash(git log*)
---

Audit the project's dependency supply chain (rule A13).

**Steps:**
1. Locate the manifest and lockfile for the stack (B2)
2. Run `make audit` and analyze the output
3. Inspect what changed if dependencies were touched in this branch
4. Produce the report

---

## 1 · Known vulnerabilities
- Run `make audit`; list every critical/high finding with its remediation path
- For each: is the vulnerable code path actually reachable from this project?
- A transitive CVE with no fix available → document the mitigation, do not ignore it silently

## 2 · Pinning & reproducibility
- [ ] Lockfile present and committed
- [ ] No `latest`, no floating major version in the manifest
- [ ] Lockfile consistent with the manifest (no manual edit)
- [ ] CI actions pinned by SHA outside the official `actions/` org

## 3 · New dependencies in this branch
For each added package:
- [ ] Justified — could the standard library do it?
- [ ] Maintained (last release, open issues, single-maintainer risk)
- [ ] Reasonable install size and transitive count
- [ ] Licence compatible with the project (B6)
- [ ] No install scripts running arbitrary code, or they are reviewed

## 4 · Hygiene
- [ ] No unused dependency
- [ ] No duplicated package at incompatible versions
- [ ] Dev dependencies not shipped in the production artifact

---

## Report format

```
## Dependency Audit — [date]

### Overall result
🟢 PASS | 🟡 TO SCHEDULE | 🔴 BLOCKING

### Vulnerabilities
| Severity | Package | Version | CVE | Reachable? | Remediation |
|----------|---------|---------|-----|------------|-------------|

### Pinning and lockfile
- [findings]

### Dependencies added in this branch
| Package | Version | Justification | Licence | Verdict |
|---------|---------|---------------|---------|---------|

### Recommended actions
- [ ] [Action]
```

---

Scope: $ARGUMENTS
