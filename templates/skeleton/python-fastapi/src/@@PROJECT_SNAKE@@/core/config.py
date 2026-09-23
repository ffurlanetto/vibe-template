"""Application settings, read from the environment (AGENTS.md A5).

Never hardcode a credential here: every value comes from the environment, and
`.env.example` documents the full set of variables.
"""

from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Typed view of the process environment."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "@@PROJECT@@"
    app_env: Literal["development", "staging", "production"] = "development"
    log_level: Literal["debug", "info", "warning", "error"] = "info"
    port: int = 8080


@lru_cache
def get_settings() -> Settings:
    """Return the process-wide settings, parsed once.

    Raises:
        pydantic.ValidationError: if a required variable is missing or invalid —
            the process fails at startup rather than at the first request (A3).
    """
    return Settings()
