"""HTTP layer for the example slice.

The router translates between HTTP and the service. Business rules live in the
service; expected domain errors become status codes here (A3).
"""

from fastapi import APIRouter, Depends, HTTPException, status

from ..repositories.example_repository import InMemoryExampleRepository
from ..schemas.example import ExampleCreate, ExampleRead
from ..services.example_service import (
    DuplicateExampleError,
    ExampleNotFoundError,
    ExampleService,
)

router = APIRouter(prefix="/examples", tags=["examples"])

_repository = InMemoryExampleRepository()


def get_service() -> ExampleService:
    """Provide the service. Override in tests with ``dependency_overrides``."""
    return ExampleService(_repository)


@router.post("", response_model=ExampleRead, status_code=status.HTTP_201_CREATED)
async def create_example(
    payload: ExampleCreate,
    service: ExampleService = Depends(get_service),
) -> ExampleRead:
    """Create an example, rejecting a duplicate name with 409."""
    try:
        example = service.create(payload.name)
    except DuplicateExampleError as error:
        # Generic message to the client, detail in the structured log (A3).
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="name already in use"
        ) from error
    return ExampleRead(id=example.id, name=example.name)


@router.get("/{identifier}", response_model=ExampleRead)
async def read_example(
    identifier: str,
    service: ExampleService = Depends(get_service),
) -> ExampleRead:
    """Return one example, or 404 when it does not exist."""
    try:
        example = service.get(identifier)
    except ExampleNotFoundError as error:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not found") from error
    return ExampleRead(id=example.id, name=example.name)
