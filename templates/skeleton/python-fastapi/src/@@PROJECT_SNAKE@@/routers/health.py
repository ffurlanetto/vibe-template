"""Health endpoints (AGENTS.md A8, SPEC-001).

``/health/live``  — the process is running. Touches nothing.
``/health/ready`` — every critical dependency answers. 503 when one does not.
"""

import logging

from fastapi import APIRouter, Response, status

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/health", tags=["health"])


async def _check_dependencies() -> dict[str, bool]:
    """Probe every critical dependency declared in B2.

    Add one entry per dependency (database, cache, broker). Keep each probe
    cheap and bounded: this endpoint must answer in under 100 ms (SPEC-001).
    """
    return {}


@router.get("/live", status_code=status.HTTP_200_OK)
async def live() -> dict[str, str]:
    """Return 200 as long as the process is able to serve."""
    return {"status": "alive"}


@router.get("/ready")
async def ready(response: Response) -> dict[str, object]:
    """Return 200 when every dependency is reachable, 503 otherwise."""
    checks = await _check_dependencies()
    failing = [name for name, healthy in checks.items() if not healthy]

    if failing:
        # The dependency name is safe to expose; its DSN is not (A5).
        logger.warning("readiness check failed", extra={"failing": failing})
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "unavailable", "failing": failing}

    return {"status": "ready", "checks": checks}
