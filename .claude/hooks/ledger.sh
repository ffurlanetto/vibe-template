#!/usr/bin/env bash
# ledger.sh — append one agent lifecycle event to .claude/run/ledger.jsonl.
#
# Claude Code : SubagentStart and SubagentStop hooks (payload on stdin)
# opencode    : the guardrail plugin, around the task tool (fields as arguments)
#
#   ledger.sh                         # reads the hook payload on stdin
#   ledger.sh <event> <agent_type> <agent_id> [summary]
#
# The protocol is the file, not either tool's event API, so a third runtime joins
# by appending lines (ADR-003). Never blocks: an observer that can fail a build is
# worse than no observer.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
. "$HOOK_DIR/lib.sh"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LEDGER_FILE="${CLAUDE_LEDGER_FILE:-$ROOT/.claude/run/ledger.jsonl}"

PAYLOAD=""
if [ $# -eq 0 ]; then
  PAYLOAD="$(hook_stdin_json)"
fi

mkdir -p "$(dirname "$LEDGER_FILE")" 2>/dev/null || exit 0

LEDGER_FILE="$LEDGER_FILE" PAYLOAD="$PAYLOAD" python3 - "$@" <<'PY' || exit 0
import json, os, re, sys, time

MAX_SUMMARY = 240

# Same shapes the secret scanner looks for: a summary is model output on its way
# to disk, and a token it happened to quote must not be persisted (ADR-003).
SECRET_PATTERNS = [
    re.compile(r"(?i)((?:pass(?:wd|word)?|secret|token|api[-_]?key|apikey|access[-_]?key|"
               r"auth|credential|client[-_]?secret|private[-_]?key|dsn)"
               r"\s*[:=]\s*.?[\"'`])([^\"'`]{8,})"),
    re.compile(r"(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|"
               r"github_pat_[A-Za-z0-9_]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|"
               r"sk-(?:ant-)?[A-Za-z0-9-]{20,}|AIza[0-9A-Za-z_-]{30,}|"
               r"eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.)"),
]


def mask(text: str) -> str:
    text = SECRET_PATTERNS[0].sub(lambda m: m.group(1) + "********", text)
    return SECRET_PATTERNS[1].sub("********", text)


def summarise(text: str) -> str:
    """One line, bounded, masked — enough to say what happened, no more."""
    flat = " ".join(mask(text or "").split())
    return flat[: MAX_SUMMARY - 1] + "…" if len(flat) > MAX_SUMMARY else flat


args = sys.argv[1:]
if args:
    event = args[0]
    record = {
        "event": event if event.startswith("agent.") else f"agent.{event}",
        "session_id": os.environ.get("OPENCODE_SESSION_ID", ""),
        "agent_type": args[1] if len(args) > 1 else "",
        "agent_id": args[2] if len(args) > 2 else "",
        "summary": summarise(args[3]) if len(args) > 3 else "",
    }
else:
    try:
        payload = json.loads(os.environ.get("PAYLOAD") or "{}")
    except ValueError:
        sys.exit(0)
    name = payload.get("hook_event_name", "")
    if name not in ("SubagentStart", "SubagentStop"):
        sys.exit(0)
    record = {
        "event": "agent.start" if name == "SubagentStart" else "agent.stop",
        "session_id": payload.get("session_id", ""),
        "agent_type": payload.get("agent_type", ""),
        "agent_id": payload.get("agent_id", ""),
        "summary": summarise(payload.get("last_assistant_message", "")),
    }

record = {"ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"), **record}

try:
    # One append per line: concurrent subagents can write at once without locking.
    with open(os.environ["LEDGER_FILE"], "a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, ensure_ascii=False) + "\n")
except OSError:
    sys.exit(0)
PY
exit 0
