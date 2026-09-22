"""Shared fixtures (AGENTS.md A4 — mocks only at system boundaries)."""

import pytest
from fastapi.testclient import TestClient

from @@PROJECT_SNAKE@@.main import create_app
from @@PROJECT_SNAKE@@.repositories.example_repository import InMemoryExampleRepository
from @@PROJECT_SNAKE@@.services.example_service import ExampleService


@pytest.fixture
def repository() -> InMemoryExampleRepository:
    """A fresh in-memory repository — no state leaks between tests."""
    return InMemoryExampleRepository()


@pytest.fixture
def service(repository: InMemoryExampleRepository) -> ExampleService:
    return ExampleService(repository)


@pytest.fixture
def client() -> TestClient:
    """An HTTP client bound to a freshly built application."""
    return TestClient(create_app())
