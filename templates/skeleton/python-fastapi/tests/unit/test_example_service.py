"""Unit tests for the example service.

Naming: [Subject]_[Scenario]_[ExpectedResult] (AGENTS.md A4).
"""

import pytest

from @@PROJECT_SNAKE@@.services.example_service import (
    DuplicateExampleError,
    ExampleNotFoundError,
    ExampleService,
)


def test_create_with_new_name_returns_example(service: ExampleService) -> None:
    example = service.create("first")

    assert example.name == "first"
    assert example.id


def test_create_with_duplicate_name_raises_conflict(service: ExampleService) -> None:
    service.create("taken")

    with pytest.raises(DuplicateExampleError) as error:
        service.create("taken")

    assert error.value.name == "taken"


def test_get_with_known_id_returns_example(service: ExampleService) -> None:
    created = service.create("known")

    assert service.get(created.id).id == created.id


def test_get_with_unknown_id_raises_not_found(service: ExampleService) -> None:
    with pytest.raises(ExampleNotFoundError):
        service.get("does-not-exist")
