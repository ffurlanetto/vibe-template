"""Integration tests for the example slice — nominal and error paths (A4)."""

from fastapi.testclient import TestClient


def test_create_example_with_valid_payload_returns_201(client: TestClient) -> None:
    response = client.post("/examples", json={"name": "integration-nominal"})

    assert response.status_code == 201
    assert response.json()["name"] == "integration-nominal"


def test_create_example_with_duplicate_name_returns_409(client: TestClient) -> None:
    client.post("/examples", json={"name": "integration-duplicate"})

    response = client.post("/examples", json={"name": "integration-duplicate"})

    assert response.status_code == 409


def test_create_example_with_empty_name_returns_422(client: TestClient) -> None:
    response = client.post("/examples", json={"name": ""})

    assert response.status_code == 422


def test_read_example_with_unknown_id_returns_404(client: TestClient) -> None:
    response = client.get("/examples/unknown-id")

    assert response.status_code == 404
