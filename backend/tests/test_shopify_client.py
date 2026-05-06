from __future__ import annotations

import httpx
import pytest

from backend.app.shopify_client import ShopifyClient, ShopifyResponseError


def make_client(handler):
    transport = httpx.MockTransport(handler)
    return ShopifyClient(
        shop_name="example.myshopify.com",
        api_version="2025-04",
        access_token="token",
        transport=transport,
        sleep_fn=lambda _: None,
    )


def test_get_shopify_data_paginates():
    calls = []

    def handler(request: httpx.Request) -> httpx.Response:
        calls.append(str(request.url))
        if "page_info=next" in str(request.url):
            return httpx.Response(200, json={"orders": [{"id": 2}]})
        return httpx.Response(
            200,
            headers={"Link": '<https://example.myshopify.com/admin/api/2025-04/orders.json?page_info=next>; rel="next"'},
            json={"orders": [{"id": 1}]},
        )

    client = make_client(handler)
    data = client.get_shopify_data("orders", params={"status": "any"}, max_pages=5)

    assert data["count"] == 2
    assert [item["id"] for item in data["items"]] == [1, 2]
    assert len(calls) == 2


def test_get_shopify_data_retries_429():
    attempts = {"count": 0}
    sleeps = []

    def handler(_: httpx.Request) -> httpx.Response:
        attempts["count"] += 1
        if attempts["count"] == 1:
            return httpx.Response(429, headers={"Retry-After": "0.01"}, json={"errors": "rate limited"})
        return httpx.Response(200, json={"products": [{"id": 10}]})

    client = ShopifyClient(
        shop_name="example.myshopify.com",
        api_version="2025-04",
        access_token="token",
        transport=httpx.MockTransport(handler),
        sleep_fn=lambda seconds: sleeps.append(seconds),
    )

    data = client.get_shopify_data("products", max_pages=1)

    assert data["count"] == 1
    assert attempts["count"] == 2
    assert sleeps == [0.01]


def test_get_shopify_data_rejects_malformed_payload():
    def handler(_: httpx.Request) -> httpx.Response:
        return httpx.Response(200, text="not json")

    client = make_client(handler)

    with pytest.raises(ShopifyResponseError):
        client.get_shopify_data("customers")


def test_get_shopify_data_rejects_unknown_resource():
    client = make_client(lambda request: httpx.Response(200, json={}))

    with pytest.raises(ValueError):
        client.get_shopify_data("inventory")
