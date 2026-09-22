"""@@PROJECT@@ — FastAPI entry point.

Wiring only: settings, logging, routers. No business logic in this module.
"""

from fastapi import FastAPI

from .core.config import get_settings
from .core.logging import configure_logging
from .routers import example, health


def create_app() -> FastAPI:
    """Build the application. A factory keeps tests free of import-time state."""
    settings = get_settings()
    configure_logging(settings.log_level)

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        # Disable the interactive docs in production (A5).
        docs_url=None if settings.app_env == "production" else "/docs",
        redoc_url=None,
    )

    app.include_router(health.router)
    app.include_router(example.router)
    return app


app = create_app()
