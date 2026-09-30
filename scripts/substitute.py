#!/usr/bin/env python3
"""Replace <PROJECT_NAME> with the project's name, literally.

Called by init.sh once per generated AGENTS.md / CLAUDE.md. It exists as its own
file rather than as a heredoc inside init.sh so that the bootstrap carries no
nested heredoc, and because a literal replace is the whole point: the name comes
from the command line, and `sed` would expand `&` to the matched text and need
the delimiter and backslashes escaped. No name has to be rejected for the
substitution's convenience.

Usage: NAME="my project" python3 scripts/substitute.py <file>
"""
import os
import pathlib
import sys

PLACEHOLDER = "<PROJECT_NAME>"


def substitute(path: pathlib.Path, name: str) -> int:
    """Rewrite *path* with every PLACEHOLDER replaced by *name*.

    Returns the number of replacements made. The file is left untouched when
    there are none, so a second bootstrap run changes nothing.
    """
    text = path.read_text(encoding="utf-8")
    count = text.count(PLACEHOLDER)
    if count:
        path.write_text(text.replace(PLACEHOLDER, name), encoding="utf-8")
    return count


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"usage: NAME=<name> {argv[0]} <file>", file=sys.stderr)
        return 2
    name = os.environ.get("NAME")
    if name is None:
        print("NAME is not set", file=sys.stderr)
        return 2
    substitute(pathlib.Path(argv[1]), name)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
