## What

<!-- The change, in the reviewer's terms. One paragraph. -->

## Why

<!-- The problem or requirement. Link the spec, the ADR or the ticket. -->

## How

<!-- Design choices a reviewer would not guess from the diff. Trade-offs taken. -->

## Testing

- [ ] `make check` green
- [ ] New behavior covered by tests, nominal **and** error paths
- <!-- What you tested manually, if anything -->

## Risk & rollout

- Impact area:
- Migration or data change: <!-- yes (detail) / no -->
- Rollback:

## Checklist

- [ ] Plan approved before implementation (A1)
- [ ] No secret, token or internal hostname in the diff (A5)
- [ ] ADR added or updated if this is an architectural decision (A6)
- [ ] `make sync` run if anything under `.claude/` changed

## Review focus

<!-- The one to three places where the reviewer's attention is worth the most. -->
