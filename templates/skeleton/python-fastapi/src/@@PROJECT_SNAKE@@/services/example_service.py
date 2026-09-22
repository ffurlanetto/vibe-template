"""Business rules for examples.

No FastAPI import belongs in this module: the service knows nothing about HTTP
(AGENTS.md A3 — separation of concerns).
"""

from ..repositories.example_repository import Example, ExampleRepository


class DuplicateExampleError(Exception):
    """Raised when the requested name is already taken — an expected error."""

    def __init__(self, name: str) -> None:
        """Record the name that was already taken."""
        super().__init__(f"an example named {name!r} already exists")
        self.name = name


class ExampleNotFoundError(Exception):
    """Raised when no example matches the requested id — an expected error."""

    def __init__(self, identifier: str) -> None:
        """Record the identifier that could not be found."""
        super().__init__(f"no example with id {identifier!r}")
        self.identifier = identifier


class ExampleService:
    """Creates and reads examples, enforcing the uniqueness rule."""

    def __init__(self, repository: ExampleRepository) -> None:
        """Wire the service to its persistence boundary."""
        self._repository = repository

    def create(self, name: str) -> Example:
        """Create an example.

        Args:
            name: the label to register; must not already exist.

        Returns:
            The created example.

        Raises:
            DuplicateExampleError: when the name is already in use.
        """
        if self._repository.exists_by_name(name):
            raise DuplicateExampleError(name)
        return self._repository.add(name)

    def get(self, identifier: str) -> Example:
        """Return one example.

        Raises:
            ExampleNotFoundError: when no example carries this id.
        """
        example = self._repository.get(identifier)
        if example is None:
            raise ExampleNotFoundError(identifier)
        return example
