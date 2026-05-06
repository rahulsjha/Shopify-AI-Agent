from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


ROOT_DIR = Path(__file__).resolve().parents[2]
load_dotenv(ROOT_DIR / ".env")


@dataclass(frozen=True)
class Settings:
    shop_name: str
    api_version: str
    access_token: str
    gemini_api_key: str | None
    gemini_model: str
    max_pages: int
    request_timeout_seconds: float
    max_retries: int


def load_settings() -> Settings:
    shop_name = os.getenv("SHOPIFY_SHOP_NAME", "").strip().strip('"')
    api_version = os.getenv("SHOPIFY_API_VERSION", "2025-04").strip().strip('"')
    access_token = os.getenv("SHOPIFY_ACCESS_TOKEN", "").strip().strip('"')

    if not shop_name:
        raise RuntimeError("SHOPIFY_SHOP_NAME is required")
    if not api_version:
        raise RuntimeError("SHOPIFY_API_VERSION is required")
    if not access_token:
        raise RuntimeError("SHOPIFY_ACCESS_TOKEN is required")

    return Settings(
        shop_name=shop_name,
        api_version=api_version,
        access_token=access_token,
        gemini_api_key=os.getenv("GEMINI_API_KEY", "").strip() or None,
        gemini_model=os.getenv("GEMINI_MODEL", "gemini-2.0-flash").strip(),
        max_pages=int(os.getenv("SHOPIFY_MAX_PAGES", "5")),
        request_timeout_seconds=float(os.getenv("SHOPIFY_REQUEST_TIMEOUT", "30")),
        max_retries=int(os.getenv("SHOPIFY_MAX_RETRIES", "3")),
    )
