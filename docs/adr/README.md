# ADR Index — vibe-template

Architecture Decision Records for the template itself.
Every architectural change must have an ADR **before** implementation (AGENTS.md A6).

The index shipped to generated projects lives in
`templates/common/docs/adr/README.md`, alongside the seed ADR-001.

## Index

| No. | Title | Status | Date | Component |
|-----|-------|--------|------|-----------|
| [002](ADR-002-test-gate.md) | The test gate: a constraint with an auditable way out | Accepted | 2026-09-27 | hooks · skills |
| [003](ADR-003-agent-ledger.md) | The agent ledger: a file protocol shared by both tools | Accepted | 2026-09-27 | hooks · opencode plugin |
| [004](ADR-004-delivery-flow.md) | Delivery flow: a branch first, a draft always, waiting for the build | Accepted | 2026-09-30 | AGENTS.md · skills |
| [005](ADR-005-cohort-and-jury.md) | A cohort of implementers, a jury with a quorum, and a bounded loop | Accepted | 2026-09-30 | skills · agents |
| [006](ADR-006-part-b-composition.md) | The kernel and the blank Part B are composed, not copied | Accepted | 2026-09-30 | AGENTS.md · init.sh |
| [007](ADR-007-quorum-as-code.md) | The cohort's arithmetic is a script, not a paragraph | Accepted | 2026-09-30 | scripts · skills |

## Statuses

| Status | Meaning |
|--------|---------|
| **Proposed** | Under review, not yet implementable |
| **Accepted** | Validated, implementation authorized |
| **Deprecated** | Superseded by a more recent decision |
| **Rejected** | Discarded with documented rationale |
