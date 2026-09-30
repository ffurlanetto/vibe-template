#!/usr/bin/env bash
# show-ledger.sh — render .claude/run/ledger.jsonl as a table. Run via `make agents`.
#
# The ledger is written by the SubagentStart/SubagentStop hooks and by the
# opencode guardrail plugin (ADR-003). Reading it needs nothing but this script.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEDGER_FILE="${CLAUDE_LEDGER_FILE:-$ROOT/.claude/run/ledger.jsonl}"
LIMIT="${1:-50}"

if [ ! -s "$LEDGER_FILE" ]; then
  echo "No agent activity recorded yet ($LEDGER_FILE)."
  echo "The ledger fills as subagents run; see docs/DUAL-AGENT.md."
  exit 0
fi

LEDGER_FILE="$LEDGER_FILE" LIMIT="$LIMIT" python3 - <<'PY'
import json, os
from collections import OrderedDict
from datetime import datetime

path, limit = os.environ["LEDGER_FILE"], int(os.environ["LIMIT"])

events = []
for line in open(path, encoding="utf-8"):
    line = line.strip()
    if not line:
        continue
    try:
        events.append(json.loads(line))
    except ValueError:
        continue          # a torn line from a concurrent append costs one record

events = events[-limit:]

def parsed(stamp):
    try:
        return datetime.strptime(stamp, "%Y-%m-%dT%H:%M:%S%z")
    except (ValueError, TypeError):
        return None

# Pair each stop with its start so the table can show how long the agent ran.
runs = OrderedDict()
for event in events:
    key = event.get("agent_id") or f"{event.get('agent_type')}-{event.get('ts')}"
    run = runs.setdefault(key, {"type": event.get("agent_type", "?"),
                                "session": (event.get("session_id") or "")[:8],
                                "start": None, "stop": None, "summary": ""})
    if event.get("event") == "agent.start":
        run["start"] = parsed(event.get("ts"))
    else:
        run["stop"] = parsed(event.get("ts"))
        run["summary"] = event.get("summary", "")

print(f"{'AGENT':<18} {'SESSION':<9} {'STATUS':<9} {'TOOK':>7}  SUMMARY")
for run in runs.values():
    if run["stop"]:
        status, took = "done", ""
        if run["start"]:
            took = f"{(run['stop'] - run['start']).total_seconds():.0f}s"
    else:
        status, took = "running", ""
    summary = run["summary"][:70] + ("…" if len(run["summary"]) > 70 else "")
    print(f"{run['type']:<18} {run['session']:<9} {status:<9} {took:>7}  {summary}")

running = sum(1 for r in runs.values() if not r["stop"])
print(f"\n{len(runs)} agent run(s), {running} still running.")
PY
