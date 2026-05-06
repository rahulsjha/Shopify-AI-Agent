from __future__ import annotations

import json
from functools import lru_cache

from langchain_core.tools import tool

from .config import load_settings
from .shopify_client import ShopifyClient


@lru_cache(maxsize=1)
def get_shopify_client() -> ShopifyClient:
    settings = load_settings()
    return ShopifyClient(
        shop_name=settings.shop_name,
        api_version=settings.api_version,
        access_token=settings.access_token,
        timeout_seconds=settings.request_timeout_seconds,
        max_retries=settings.max_retries,
    )


@tool("get_shopify_data")
def get_shopify_data_tool(request_json: str) -> str:
    """Fetch read-only Shopify data for orders, products, or customers."""

    try:
        request_payload = json.loads(request_json)
    except json.JSONDecodeError as exc:
        raise ValueError("Tool input must be valid JSON with resource, params, and optional max_pages") from exc

    if not isinstance(request_payload, dict):
        raise ValueError("Tool input must be a JSON object")

    resource = request_payload.get("resource")
    params = request_payload.get("params") or {}
    max_pages = int(request_payload.get("max_pages", load_settings().max_pages))

    if not isinstance(resource, str):
        raise ValueError("resource must be a string")
    if not isinstance(params, dict):
        raise ValueError("params must be a JSON object")

    data = get_shopify_client().get_shopify_data(resource=resource, params=params, max_pages=max_pages)
    return json.dumps(data, default=str)
