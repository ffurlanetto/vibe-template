#!/usr/bin/env python3
"""Turn a jury's verdicts into one decision for /build.

The rules live in `.claude/skills/build/SKILL.md` sections 6 to 8. They used to
live there *only*, as prose addressed to a model, which made them impossible to
test and easy to round off under pressure: "21 of 30" and "2 of 3" are exactly the
kind of threshold that is wrong by one and still reads right.

This script owns the arithmetic and nothing else. Whether two candidates'
strengths actually compose is a reading of the code that no arithmetic reaches, so
it arrives as an input (`complementary_strengths`) rather than being inferred.

It is a pure function: one JSON object on stdin, one JSON object on stdout, no
file touched, no environment read. Exit 0 carries a decision; exit 2 means the
bundle could not be trusted and nothing is decided — never a default of ADOPT,
because a parse error resolving to "adopt" would ship an unreviewed candidate.

See ADR-007, which also records what this does *not* do: the orchestrator is
instructed to call it, not forced to.
"""

from __future__ import annotations

import json
import sys
from typing import Any


def _out(line: str) -> None:
    """Write one line to stdout — the decision, and nothing else."""
    sys.stdout.write(line + "\n")


def _fail(message: str) -> None:
    """Write one refusal to stderr. stdout stays empty so no caller reads a verdict."""
    sys.stderr.write(f"quorum: {message}\n")


# The three lenses of the jury, and the two whose FAIL is fatal whatever the
# totals say. Hardcoded on purpose: an axis is an agent, and a bundle that could
# rename an axis could remove it.
JURORS = ("code-reviewer", "security-auditor", "test-architect")
BLOCKING_AXES = ("code-reviewer", "security-auditor")

MIN_TOTAL = 21  # out of 30
MIN_PASSES = 2  # of 3
MAX_SCORE = 10
COVERAGE_EPSILON = 1e-9  # coverage is a float; equality needs a tolerance
ID_LIMIT = 200  # an id is echoed back; it does not get to be unbounded


class Invalid(Exception):
    """The bundle cannot be trusted. Nothing is decided."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise Invalid(message)


def _int(value: Any, what: str) -> int:
    # bool is an int in Python, and `true` is not a score.
    _require(isinstance(value, int) and not isinstance(value, bool), f"{what} must be an integer")
    return value


def _number(value: Any, what: str) -> float:
    _require(
        isinstance(value, (int, float)) and not isinstance(value, bool), f"{what} must be a number"
    )
    return float(value)


def _clip(text: Any) -> str:
    return str(text)[:ID_LIMIT]


def read_candidate(raw: Any, index: int) -> dict[str, Any]:
    """Validate one candidate and reduce it to the numbers the rules need.

    Nothing a juror wrote in prose — a strength, a blocking finding — is carried
    out of here. Those are model output about someone's source tree and may quote
    a credential; the orchestrator already holds them.
    """
    where = f"candidate #{index}"
    _require(isinstance(raw, dict), f"{where} must be an object")
    _require("id" in raw, f"{where} has no id")
    cid = _clip(raw["id"])

    gate = raw.get("gate")
    _require(gate in ("green", "red"), f"{cid}: gate must be the string 'green' or 'red'")

    jurors = raw.get("jurors")
    _require(isinstance(jurors, list), f"{cid}: jurors must be a list")
    seen: dict[str, str] = {}
    total = 0
    for entry in jurors:
        _require(isinstance(entry, dict), f"{cid}: each juror must be an object")
        agent = entry.get("agent")
        _require(
            agent in JURORS, f"{cid}: unknown juror {agent!r} — expected one of {', '.join(JURORS)}"
        )
        _require(agent not in seen, f"{cid}: {agent} appears twice")
        verdict = entry.get("verdict")
        _require(
            verdict in ("PASS", "FAIL"),
            f"{cid}: {agent} returned {verdict!r}, expected PASS or FAIL",
        )
        score = _int(entry.get("score"), f"{cid}: {agent}'s score")
        _require(
            0 <= score <= MAX_SCORE, f"{cid}: {agent}'s score {score} is outside 0-{MAX_SCORE}"
        )
        seen[agent] = verdict
        total += score
    missing = [name for name in JURORS if name not in seen]
    _require(
        not missing,
        f"{cid}: no verdict from {', '.join(missing)} — the quorum is defined over all three",
    )

    size = raw.get("size") or {}
    _require(isinstance(size, dict), f"{cid}: size must be an object")

    return {
        "id": cid,
        "gate": gate,
        "total": total,
        "verdicts": seen,
        "passes": sum(1 for v in seen.values() if v == "PASS"),
        "blocking_fail": [a for a in BLOCKING_AXES if seen[a] == "FAIL"],
        "files_changed": (
            _int(size["files_changed"], f"{cid}: files_changed")
            if "files_changed" in size
            else None
        ),
        "lines_changed": (
            _int(size["lines_changed"], f"{cid}: lines_changed")
            if "lines_changed" in size
            else None
        ),
    }


def disqualification(candidate: dict[str, Any]) -> str | None:
    """Why this candidate is not acceptable, or None when it is.

    Ordered so the answer is the most fundamental one: a candidate that does not
    build is not a candidate whose score means anything.
    """
    if candidate["gate"] != "green":
        return "the objective gate is red"
    if candidate["blocking_fail"]:
        return f"FAIL from {' and '.join(candidate['blocking_fail'])}, a blocking axis"
    if candidate["passes"] < MIN_PASSES:
        return f"{candidate['passes']} of 3 PASS, fewer than {MIN_PASSES}"
    if candidate["total"] < MIN_TOTAL:
        return f"total {candidate['total']}, below {MIN_TOTAL}/30"
    return None


def pick(accepted: list[dict[str, Any]]) -> tuple[dict[str, Any], str]:
    """Choose between accepted candidates, and say what settled it.

    The skill says "on a tie, the one with the simpler structure". Simpler has to
    become a number or a model arbitrates it, so: the total, then the files it
    touches, then the lines. The final fallback is the id — arbitrary, and
    reported as such, because a deterministic arbitrary beats a coin flip nobody
    can reproduce.
    """
    best = max(c["total"] for c in accepted)
    front = [c for c in accepted if c["total"] == best]
    if len(front) == 1:
        return front[0], "total"
    for measure in ("files_changed", "lines_changed"):
        known = [c for c in front if c[measure] is not None]
        if len(known) == len(front):
            smallest = min(c[measure] for c in front)
            narrowed = [c for c in front if c[measure] == smallest]
            if len(narrowed) == 1:
                return narrowed[0], measure
            front = narrowed
    return min(front, key=lambda c: c["id"]), "id"


def ratchet_verdict(best_total: int, bundle: dict[str, Any]) -> tuple[str, str]:
    """Compare this iteration against the last one. Returns (state, explanation).

    An iteration that lowers the score, the passing test count or the coverage is
    rejected: the previous best stays the base. It is not a decision of its own —
    it answers "what do we build on", not "what do we do next" — so the caller
    keeps iterating, one ceiling slot poorer. Not spending a slot would let a
    cohort that regresses every round loop forever, which is the thing the ceiling
    exists to prevent.
    """
    history = bundle["history"]
    if not history:
        return "n/a", ""
    previous = history[-1]
    metrics = bundle["metrics"]
    regressions = []
    if best_total < previous["best_total"]:
        regressions.append(f"total score {previous['best_total']} → {best_total}")
    if (
        "passing_tests" in metrics
        and "passing_tests" in previous
        and metrics["passing_tests"] < previous["passing_tests"]
    ):
        regressions.append(
            f"passing tests {previous['passing_tests']} → {metrics['passing_tests']}"
        )
    if (
        "coverage" in metrics
        and "coverage" in previous
        and metrics["coverage"] < previous["coverage"] - COVERAGE_EPSILON
    ):
        regressions.append(f"coverage {previous['coverage']} → {metrics['coverage']}")
    if regressions:
        return "rejected", "; ".join(regressions)
    return "ok", ""


def flat(later: dict[str, Any], earlier: dict[str, Any]) -> bool:
    """True when `later` improved on none of the three measures."""
    return not (
        later["best_total"] > earlier["best_total"]
        or later.get("passing_tests", 0) > earlier.get("passing_tests", 0)
        or later.get("coverage", 0.0) > earlier.get("coverage", 0.0) + COVERAGE_EPSILON
    )


def read_bundle(raw: Any) -> dict[str, Any]:
    """Validate the whole bundle and reduce it to what `decide` needs.

    Every key the rules depend on is required rather than defaulted. A missing
    ceiling that defaulted to some number would silently change when the loop
    stops, which is the kind of default that is wrong in a way nobody notices.
    """
    _require(isinstance(raw, dict), "the bundle must be a JSON object")
    for key in ("candidates", "iteration", "ceiling"):
        _require(key in raw, f"the bundle has no '{key}'")
    candidates = raw["candidates"]
    _require(
        isinstance(candidates, list) and candidates,
        "candidates must be a non-empty list — no cohort is a caller bug, not a verdict",
    )

    history = raw.get("history") or []
    _require(isinstance(history, list), "history must be a list")
    clean_history = []
    for i, entry in enumerate(history):
        _require(isinstance(entry, dict), f"history #{i} must be an object")
        item = {"best_total": _int(entry.get("best_total"), f"history #{i}: best_total")}
        if "passing_tests" in entry:
            item["passing_tests"] = _int(entry["passing_tests"], f"history #{i}: passing_tests")
        if "coverage" in entry:
            item["coverage"] = _number(entry["coverage"], f"history #{i}: coverage")
        clean_history.append(item)

    metrics_raw = raw.get("metrics") or {}
    _require(isinstance(metrics_raw, dict), "metrics must be an object")
    metrics: dict[str, Any] = {}
    if "passing_tests" in metrics_raw:
        metrics["passing_tests"] = _int(metrics_raw["passing_tests"], "metrics: passing_tests")
    if "coverage" in metrics_raw:
        metrics["coverage"] = _number(metrics_raw["coverage"], "metrics: coverage")

    complementary = raw.get("complementary_strengths", False)
    _require(isinstance(complementary, bool), "complementary_strengths must be true or false")

    return {
        "candidates": [read_candidate(c, i) for i, c in enumerate(candidates)],
        "iteration": _int(raw["iteration"], "iteration"),
        "ceiling": _int(raw["ceiling"], "ceiling"),
        "complementary_strengths": complementary,
        "history": clean_history,
        "metrics": metrics,
    }


def decide(bundle: dict[str, Any]) -> dict[str, Any]:
    """Apply sections 6 to 8 of the build skill, in that order."""
    candidates = bundle["candidates"]
    accepted, disqualified = [], []
    for candidate in candidates:
        why = disqualification(candidate)
        if why is None:
            accepted.append(candidate)
        else:
            disqualified.append({"id": candidate["id"], "why": why})

    buildable = [c for c in candidates if c["gate"] == "green"]
    best_total = max((c["total"] for c in buildable), default=0)

    result: dict[str, Any] = {
        "decision": "",
        "candidate": None,
        "reason": "",
        "accepted": [c["id"] for c in accepted],
        "disqualified": disqualified,
        "ratchet": "n/a",
        "base": "current",
        "best_total": best_total,
        "tie_break": None,
    }

    # A quorum outranks everything below: the ceiling and the diminishing-returns
    # stop exist to end a loop that is not converging, and this one has converged.
    if accepted:
        winner, tie_break = pick(accepted)
        result.update(
            decision="ADOPT",
            candidate=winner["id"],
            tie_break=tie_break,
            reason=(
                f"{winner['id']} reaches quorum: {winner['passes']} of 3 PASS, "
                f"no blocking FAIL, total {winner['total']}/30"
                + (f"; chosen on {tie_break}" if len(accepted) > 1 else "")
            ),
        )
        return result

    state, detail = ratchet_verdict(best_total, bundle)
    result["ratchet"] = state
    if state == "rejected":
        result["base"] = "previous-best"
    ratchet_note = (
        f"; ratchet rejected this iteration ({detail}) — the previous best stays the base"
        if state == "rejected"
        else ""
    )

    if not buildable:
        result.update(
            decision="STOP",
            reason="every candidate failed the objective gate — the plan is the suspect, "
            "not the cohort (build §4). Re-plan rather than re-run.",
        )
        return result

    blockers = "; ".join(f"{d['id']}: {d['why']}" for d in disqualified[:3])
    no_quorum = f"no candidate reached quorum — {blockers}"

    if bundle["iteration"] >= bundle["ceiling"]:
        result.update(
            decision="STOP",
            reason=f"{no_quorum}. Iteration {bundle['iteration']} of {bundle['ceiling']} "
            f"— the ceiling is reached; report the blocker, "
            f"do not ship the best of a bad set" + ratchet_note,
        )
        return result

    history = bundle["history"]
    if len(history) >= 2:
        current = {"best_total": best_total, **bundle["metrics"]}
        if flat(current, history[-1]) and flat(history[-1], history[-2]):
            result.update(
                decision="STOP",
                reason=f"{no_quorum}. Two iterations with no measurable gain — diminishing "
                f"returns; a loop optimising a criterion it cannot move is burning budget"
                + ratchet_note,
            )
            return result

    if bundle["complementary_strengths"]:
        result.update(
            decision="CONSOLIDATE",
            reason=f"{no_quorum}. The jury named complementary strengths, so consolidate "
            f"before iterating — it counts as an iteration" + ratchet_note,
        )
        return result

    result.update(
        decision="ITERATE",
        reason=f"{no_quorum}. Feed the blocking findings back to the cohort "
        f"(iteration {bundle['iteration']} of {bundle['ceiling']})" + ratchet_note,
    )
    return result


def main() -> int:
    """Read one bundle from stdin, write one decision to stdout.

    Returns the process exit status: 0 when a decision was made, 2 when the
    bundle could not be trusted.
    """
    try:
        raw = json.loads(sys.stdin.read())
    except RecursionError:
        _fail("the bundle is nested too deeply to parse")
        return 2
    except Exception as error:  # noqa: BLE001 — any unparseable input is the same refusal
        _fail(f"the bundle is not valid JSON ({error})")
        return 2
    try:
        _out(json.dumps(decide(read_bundle(raw)), ensure_ascii=False))
    except Invalid as error:
        _fail(str(error))
        return 2
    except RecursionError:
        _fail("the bundle is nested too deeply to read")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
