"""Integration tests for the health endpoints (SPEC-001)."""

from fastapi.testclient import TestClient


def test_live_when_process_is_running_returns_200(client: TestClient) -> None:
    response = client.get("/health/live")

    assert response.status_code == 200
    assert response.json() == {"status": "alive"}


def test_ready_when_dependencies_are_reachable_returns_200(client: TestClient) -> None:
    response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.json()["status"] == "ready"


def test_health_response_contains_no_secret(client: TestClient) -> None:
    body = client.get("/health/ready").text.lower()

    for forbidden in ("password", "secret", "token", "dsn"):
        assert forbidden not in body
