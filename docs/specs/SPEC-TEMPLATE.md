# SPEC-NNN: [Feature title]

**Date:** YYYY-MM-DD
**Status:** `Draft` | `Under Review` | `Approved` | `Implemented` | `Deprecated`
**Author:** [Name]
**Reviewers:** [Names]
**Related ADRs:** [ADR-NNN if associated architectural decision]
**Ticket:** [PROJ-NNN]

---

## 1. Context & Problem

> Describe the current situation, the problem, or the opportunity that justifies this feature.
> Answer: **Why now?** and **What happens if we don't do this?**

[Context description]

---

## 2. Objective

> One affirmative sentence describing what this feature accomplishes.

**As a** [persona / user role],
**I want to** [action or capability],
**so that** [concrete value or benefit].

---

## 3. Scope

### In scope

- [ ] [Included behavior or use case]
- [ ] [...]

### Out of scope

- [What is explicitly excluded and why]
- [...]

---

## 4. Functional Specification

### 4.1 Nominal flow (Happy Path)

```
Step 1: [User or system action]
  → Expected result: [...]

Step 2: [...]
  → Expected result: [...]
```

### 4.2 Edge cases & errors

| Scenario | Expected behavior | User message |
|----------|------------------|--------------|
| [Invalid input] | [Reject with 400] | [Generic message] |
| [Missing resource] | [Return 404] | [Generic message] |
| [System error] | [Return 500 + log] | "An error occurred" |

### 4.3 Business rules

- [Rule 1 — condition and consequence]
- [Rule 2]

---

## 5. Acceptance Criteria

> Criteria must be objectively testable (no "fast", "intuitive", "simple").

- [ ] [Measurable behavior 1]
- [ ] [Measurable behavior 2]
- [ ] No regression on existing features
- [ ] Performance: [latency / response time per B6 budget]
- [ ] Security: A5 checklist completed

---

## 6. Design & UX (if applicable)

> Link to Figma mockups, wireframes, or textual description of the visual flow.

[Figma link / screenshots / description]

**UX considerations:**
- [Accessibility: WCAG 2.1 AA minimum]
- [Mobile behavior]
- [Loading and error states]

---

## 7. Technical Impact

### Affected components

| Component | Impact type | Notes |
|-----------|------------|-------|
| [Module X] | Modification | [description] |
| [Endpoint Y] | Creation | [description] |
| [Table Z] | Migration | [fields added/modified] |

### Dependencies

- [External service, library, or prerequisite feature]

### Identified risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | High/Medium/Low | High/Medium/Low | [Mitigation] |

---

## 8. Test Plan

| Type | Scenarios to cover |
|------|-------------------|
| Unit | [Critical functions / classes] |
| Integration | [Component interactions] |
| E2E | [Full user journey] |
| Performance | [Expected load, acceptable thresholds] |
| Security | [Auth, injection, permissions] |

---

## 9. Deployment Plan

- **Feature flag:** Yes / No — [flag name if applicable]
- **DB migration:** Yes / No — [description if applicable]
- **Rollback:** [Procedure if production deployment fails]
- **Post-deployment monitoring:** [Metrics to watch for 24h after deployment]

---

## 10. Open Questions

| # | Question | Owner | Deadline | Answer |
|---|----------|-------|----------|--------|
| 1 | [Blocking question] | [Name] | [Date] | — |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | YYYY-MM-DD | [Name] | Initial draft |
