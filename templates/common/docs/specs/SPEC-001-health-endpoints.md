# SPEC-001: Health endpoints

**Date:** @@DATE@@
**Status:** Implemented
**Author:** @@PROJECT@@ team
**Related:** ADR-001 · AGENTS.md A8

## Problem

An orchestrator, a load balancer and an on-call engineer each need to know
whether this service is alive and whether it can serve traffic. Without a
distinction between the two, a service with a dead database keeps receiving
requests, and a slow start-up is killed as if it had crashed.

## Goal

Expose the two states separately, so restart decisions and routing decisions
stop using the same signal.

## Non-goals
- Business-level health (queue depth, data freshness)
- Authentication on these endpoints

## Functional requirements

| # | Requirement | Priority |
|---|-------------|----------|
| FR-1 | `GET /health/live` MUST return `200` whenever the process is running, without touching any dependency | must |
| FR-2 | `GET /health/ready` MUST return `200` only when every critical dependency is reachable | must |
| FR-3 | `GET /health/ready` MUST return `503` with the failing dependency named when one is unreachable | must |
| FR-4 | Neither endpoint MAY expose credentials, hostnames or stack traces | must |
| FR-5 | Both SHOULD answer in under 100 ms | should |

## Acceptance criteria

- [ ] Given the process is running, when `GET /health/live`, then `200` and no dependency is contacted
- [ ] Given every dependency is reachable, when `GET /health/ready`, then `200`
- [ ] Given a dependency is down, when `GET /health/ready`, then `503` naming the dependency
- [ ] Given any response, then it contains no secret, DSN or internal hostname

## Non-functional requirements
- Performance: under 100 ms (A10)
- Security: unauthenticated, but leaking nothing (A5)
- Observability: failures logged at WARN with the dependency name (A8)
