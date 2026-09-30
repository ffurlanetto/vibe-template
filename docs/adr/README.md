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

## Statuses

| Status | Meaning |
|--------|---------|
| **Proposed** | Under review, not yet implementable |
| **Accepted** | Validated, implementation authorized |
| **Deprecated** | Superseded by a more recent decision |
| **Rejected** | Discarded with documented rationale |
