#!/usr/bin/env python3
"""Write a project's test-gate policy from the shipped default plus the stack's layout.

Called by scripts/scaffold.sh with the default policy and the destination path.
The stack module declares TEST_SOURCES and TEST_PATTERNS in the environment; its
own layout takes precedence, while the generic globs stay on as a safety net for
files the module did not anticipate. See docs/adr/ADR-002-test-gate.md.
"""

import json
import os
import sys


def main() -> int:
    default_path, destination = sys.argv[1], sys.argv[2]
    policy = json.load(open(default_path, encoding="utf-8"))

    sources = os.environ.get("TEST_SOURCES", "").split()
    tests = os.environ.get("TEST_PATTERNS", "").split()

    def merge(declared: list[str], kept: list[str]) -> list[str]:
        """Stack patterns first, generic ones after, without repeating any."""
        seen, merged = set(), []
        for pattern in declared + kept:
            if pattern not in seen:
                seen.add(pattern)
                merged.append(pattern)
        return merged

    if sources:
        # Keep the bare-extension globs: they catch a stray file at the root.
        policy["sources"] = merge(sources, [p for p in policy["sources"] if p.startswith("*.")])
    if tests:
        # Keep the cross-directory globs: they catch a test the module did not name.
        policy["tests"] = merge(tests, [p for p in policy["tests"] if p.startswith("**/")])

    with open(destination, "w", encoding="utf-8") as handle:
        json.dump(policy, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
