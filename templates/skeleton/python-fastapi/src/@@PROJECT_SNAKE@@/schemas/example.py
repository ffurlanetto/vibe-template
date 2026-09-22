"""Request and response schemas for the example slice.

Pydantic models at the boundary — never a raw ``dict`` (B3).
"""

from pydantic import BaseModel, Field


class ExampleCreate(BaseModel):
    """Payload accepted when creating an example."""

    name: str = Field(min_length=1, max_length=120, description="Human-readable label")


class ExampleRead(BaseModel):
    """Representation returned to clients."""

    id: str
    name: str
