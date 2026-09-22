# RUNBOOK: [Incident or operation name]

**Severity:** SEV1 | SEV2 | SEV3
**Owner:** [team]
**Last rehearsed:** YYYY-MM-DD

> A runbook is read at 3am by someone who did not write it. Commands, not prose.

## Symptoms
- [What the alert says, what users report]

## Impact
- [Who is affected and how badly]

## Diagnose

```bash
# 1. Is the service alive?
curl -sS https://<host>/health/live

# 2. Can it serve traffic?
curl -sS https://<host>/health/ready

# 3. Recent errors
# <log query>
```

| Observation | Likely cause | Go to |
|-------------|--------------|-------|
| `live` fails | process down / OOM | Mitigation A |
| `live` ok, `ready` fails | dependency down | Mitigation B |

## Mitigate

### A — [name]
```bash
# exact commands
```

### B — [name]
```bash
# exact commands
```

## Verify recovery
- [ ] `/health/ready` returns 200
- [ ] Error rate back under [threshold]
- [ ] [Business metric] back to normal

## Escalate
- [Who, how, after how long]

## Post-incident
- [ ] Timeline written
- [ ] Root cause identified
- [ ] Follow-up issues opened
