"""Structured JSON logging (AGENTS.md A3).

One line per event, machine-readable, never a bare ``print``.
"""

import json
import logging
import sys
from typing import Any

_RESERVED = frozenset(logging.LogRecord("", 0, "", 0, "", None, None).__dict__)


class JsonFormatter(logging.Formatter):
    """Render a log record as a single JSON object."""

    def format(self, record: logging.LogRecord) -> str:
        """Return the record as one JSON line."""
        payload: dict[str, Any] = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
        }
        if record.exc_info:
            # The type and message, never the full stack trace in the payload (A8).
            payload["error"] = {
                "type": record.exc_info[0].__name__ if record.exc_info[0] else "unknown",
                "message": str(record.exc_info[1]),
            }
        payload.update(
            {key: value for key, value in record.__dict__.items() if key not in _RESERVED}
        )
        return json.dumps(payload, default=str)


def configure_logging(level: str = "info") -> None:
    """Install the JSON formatter on the root logger. Call once, at startup."""
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(level.upper())
