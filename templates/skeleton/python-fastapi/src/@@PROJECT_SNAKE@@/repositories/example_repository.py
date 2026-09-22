"""Persistence boundary for examples.

The protocol is the contract the service depends on (A3). Swap the in-memory
implementation for a real database without touching the service or the router.
"""

from typing import Protocol
from uuid import uuid4


class Example:
    """An example entity."""

    def __init__(self, identifier: str, name: str) -> None:
        """Build an example from its identifier and label."""
        self.id = identifier
        self.name = name


class ExampleRepository(Protocol):
    """Storage operations the example service needs."""

    def add(self, name: str) -> Example:
        """Persist a new example and return it."""
        ...

    def get(self, identifier: str) -> Example | None:
        """Return the example with this id, or None when it does not exist."""
        ...

    def exists_by_name(self, name: str) -> bool:
        """Return whether an example already uses this name."""
        ...


class InMemoryExampleRepository:
    """Reference implementation — replace with your datastore (see B2)."""

    def __init__(self) -> None:
        """Start with an empty store."""
        self._items: dict[str, Example] = {}

    def add(self, name: str) -> Example:
        """Persist a new example and return it."""
        example = Example(identifier=str(uuid4()), name=name)
        self._items[example.id] = example
        return example

    def get(self, identifier: str) -> Example | None:
        """Return the example with this id, or None when it does not exist."""
        return self._items.get(identifier)

    def exists_by_name(self, name: str) -> bool:
        """Return whether an example already uses this name."""
        return any(item.name == name for item in self._items.values())
