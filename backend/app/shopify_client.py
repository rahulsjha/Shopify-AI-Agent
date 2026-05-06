from __future__ import annotations

import json
import random
import re
import time
from dataclasses import dataclass
from typing import Any

import httpx


class ShopifyClientError(RuntimeError):
    pass


class ShopifyResponseError(ShopifyClientError):
    pass


_RESOURCE_KEYS = {
    "orders": "orders",
    "products": "products",
    "customers": "customers",
}


_NEXT_LINK_RE = re.compile(r'<([^>]+)>;\s*rel="next"')


@dataclass
class ShopifyClient:
    shop_name: str
    api_version: str
    access_token: str
    timeout_seconds: float = 30.0
    max_retries: int = 3
    sleep_fn: Any = time.sleep
    transport: httpx.BaseTransport | None = None

    def __post_init__(self) -> None:
        self._client = httpx.Client(
            base_url=f"https://{self.shop_name}/admin/api/{self.api_version}",
            headers={
                "X-Shopify-Access-Token": self.access_token,
                "Accept": "application/json",
            },
            timeout=self.timeout_seconds,
            transport=self.transport,
        )

    def close(self) -> None:
        self._client.close()

    def get_shopify_data(
        self,
        resource: str,
        params: dict[str, Any] | None = None,
        max_pages: int = 5,
    ) -> dict[str, Any]:
        resource_name = resource.strip().lower()
        if resource_name not in _RESOURCE_KEYS:
            raise ValueError("resource must be one of: orders, products, customers")

        key = _RESOURCE_KEYS[resource_name]
        query = {k: v for k, v in (params or {}).items() if v is not None}
        query.setdefault("limit", 250)

        collected: list[dict[str, Any]] = []
        next_url: str | None = f"/{resource_name}.json"
        pages_fetched = 0

        while next_url and pages_fetched < max_pages:
            response = self._request_with_retries(next_url, params=query if pages_fetched == 0 else None)
            payload = self._decode_json(response)
            items = payload.get(key)

            if not isinstance(items, list):
                raise ShopifyResponseError(
                    f"Malformed Shopify response for {resource_name}: expected list under '{key}'"
                )

            collected.extend(items)
            next_url = self._next_link(response.headers.get("Link"))
            pages_fetched += 1

        return {
            "resource": resource_name,
            "count": len(collected),
            "pages_fetched": pages_fetched,
            "items": collected,
            "next_page_available": bool(next_url),
        }

    def _request_with_retries(
        self,
        url: str,
        params: dict[str, Any] | None = None,
    ) -> httpx.Response:
        attempt = 0
        while True:
            response = self._client.get(url, params=params)

            if response.status_code == 429 or response.status_code >= 500:
                if attempt >= self.max_retries:
                    raise ShopifyClientError(
                        f"Shopify request failed after {self.max_retries + 1} attempts with status {response.status_code}"
                    )

                retry_after = self._retry_delay(response.headers.get("Retry-After"), attempt)
                self.sleep_fn(retry_after)
                attempt += 1
                continue

            if response.is_error:
                message = self._extract_error_message(response)
                raise ShopifyClientError(f"Shopify request failed with status {response.status_code}: {message}")

            return response

    def _retry_delay(self, retry_after: str | None, attempt: int) -> float:
        if retry_after:
            try:
                return max(float(retry_after), 0.0)
            except ValueError:
                pass

        return min(2.0 * (attempt + 1), 15.0) + random.uniform(0.0, 0.5)

    def _decode_json(self, response: httpx.Response) -> dict[str, Any]:
        try:
            payload = response.json()
        except json.JSONDecodeError as exc:
            raise ShopifyResponseError("Shopify returned malformed JSON") from exc

        if not isinstance(payload, dict):
            raise ShopifyResponseError("Shopify response payload must be a JSON object")

        return payload

    def _extract_error_message(self, response: httpx.Response) -> str:
        try:
            payload = response.json()
        except Exception:
            return response.text[:200]

        if isinstance(payload, dict):
            for key in ("errors", "error", "message"):
                if key in payload:
                    return str(payload[key])

        return response.text[:200]

    def _next_link(self, link_header: str | None) -> str | None:
        if not link_header:
            return None

        match = _NEXT_LINK_RE.search(link_header)
        if not match:
            return None

        return match.group(1)
