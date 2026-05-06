# Production-Ready Agent with Real Shopify API Data
import json
import logging
from datetime import datetime, timedelta
from collections import defaultdict
from typing import Any

from .config import load_settings
from .schemas import AskResponse
from .shopify_client import ShopifyClient

logger = logging.getLogger(__name__)


def fetch_orders_data(question: str) -> dict[str, Any] | None:
    """Fetch orders from Shopify API."""
    question_lower = question.lower()
    
    # Check if question is about orders
    if "order" not in question_lower:
        return None
    
    try:
        settings = load_settings()
        client = ShopifyClient(
            shop_name=settings.shop_name,
            api_version=settings.api_version,
            access_token=settings.access_token,
            timeout_seconds=settings.request_timeout_seconds,
            max_retries=settings.max_retries,
        )
        
        # Determine time range
        if "7 day" in question_lower or "last week" in question_lower or "past week" in question_lower:
            since_date = (datetime.now() - timedelta(days=7)).isoformat()
            params = {"created_at_min": since_date, "status": "any"}
        else:
            # Default to last 30 days
            since_date = (datetime.now() - timedelta(days=30)).isoformat()
            params = {"created_at_min": since_date, "status": "any"}
        
        response = client.get_shopify_data(resource="orders", params=params, max_pages=5)
        client.close()
        return response
    except Exception as e:
        logger.error(f"Error fetching orders: {e}", exc_info=True)
        return None


def fetch_products_data(question: str) -> dict[str, Any] | None:
    """Fetch products from Shopify API."""
    question_lower = question.lower()
    
    if "product" not in question_lower:
        return None
    
    try:
        settings = load_settings()
        client = ShopifyClient(
            shop_name=settings.shop_name,
            api_version=settings.api_version,
            access_token=settings.access_token,
            timeout_seconds=settings.request_timeout_seconds,
            max_retries=settings.max_retries,
        )
        response = client.get_shopify_data(resource="products", params={}, max_pages=5)
        client.close()
        return response
    except Exception as e:
        logger.error(f"Error fetching products: {e}", exc_info=True)
        return None


def fetch_customers_data(question: str) -> dict[str, Any] | None:
    """Fetch customers from Shopify API."""
    question_lower = question.lower()
    
    if "customer" not in question_lower and "repeat" not in question_lower:
        return None
    
    try:
        settings = load_settings()
        client = ShopifyClient(
            shop_name=settings.shop_name,
            api_version=settings.api_version,
            access_token=settings.access_token,
            timeout_seconds=settings.request_timeout_seconds,
            max_retries=settings.max_retries,
        )
        response = client.get_shopify_data(resource="customers", params={}, max_pages=5)
        client.close()
        return response
    except Exception as e:
        logger.error(f"Error fetching customers: {e}", exc_info=True)
        return None


def process_orders_response(orders_data: dict[str, Any], question: str) -> dict:
    """Process orders data to answer questions."""
    question_lower = question.lower()
    items = orders_data.get("items", [])
    
    if not items:
        return {
            "answer": "No orders found for the specified period.",
            "table": [],
            "chart": None,
        }
    
    # Calculate metrics
    total_orders = len(items)
    total_revenue = sum(float(order.get("total_price", 0) or 0) for order in items)
    avg_order_value = total_revenue / total_orders if total_orders > 0 else 0
    
    # Group by date for daily metrics
    daily_metrics = defaultdict(lambda: {"orders": 0, "revenue": 0.0})
    for order in items:
        date_str = order.get("created_at", "").split("T")[0]
        if date_str:
            daily_metrics[date_str]["orders"] += 1
            daily_metrics[date_str]["revenue"] += float(order.get("total_price", 0) or 0)
    
    # Sort by date
    sorted_dates = sorted(daily_metrics.keys())
    
    # Build table
    table_data = []
    chart_points = []
    for date in sorted_dates[-7:]:  # Last 7 days
        metrics = daily_metrics[date]
        table_data.append({
            "Date": date,
            "Orders": metrics["orders"],
            "Revenue": f"${metrics['revenue']:,.2f}",
            "Avg Order Value": f"${metrics['revenue']/metrics['orders']:,.2f}" if metrics["orders"] > 0 else "$0",
        })
        chart_points.append({
            "x": date.split("-")[-1],
            "y": metrics["orders"]
        })
    
    answer = f"Based on Shopify data, there were {total_orders} orders with total revenue of ${total_revenue:,.2f}. Average order value was ${avg_order_value:,.2f}."
    
    return {
        "answer": answer,
        "table": table_data,
        "chart": {
            "type": "line",
            "title": "Daily Order Volume",
            "x_label": "Date",
            "y_label": "Orders",
            "series": [{
                "name": "Orders",
                "points": chart_points
            }]
        },
    }


def process_products_response(products_data: dict[str, Any], question: str) -> dict:
    """Process products data to answer questions."""
    question_lower = question.lower()
    items = products_data.get("items", [])
    
    if not items:
        return {
            "answer": "No products found.",
            "table": [],
            "chart": None,
        }
    
    # For "best selling" - we'd need order data to correlate, so just show top products by inventory
    # In real scenario, you'd correlate with order line items
    top_products = []
    for i, product in enumerate(items[:10], 1):
        variants = product.get("variants", [])
        inventory = sum(int(v.get("inventory_quantity", 0) or 0) for v in variants)
        top_products.append({
            "Rank": i,
            "Product": product.get("title", "Unknown"),
            "Variants": len(variants),
            "Status": product.get("status", "Unknown"),
        })
    
    answer = f"Retrieved {len(items)} products from your store. Showing top 10 products by listing."
    
    return {
        "answer": answer,
        "table": top_products,
        "chart": None,
    }


def process_customers_response(customers_data: dict[str, Any], question: str) -> dict:
    """Process customers data to answer questions."""
    question_lower = question.lower()
    items = customers_data.get("items", [])
    
    if not items:
        return {
            "answer": "No customers found.",
            "table": [],
            "chart": None,
        }
    
    # Calculate repeat customers
    repeat_customers = [c for c in items if c.get("orders_count", 0) > 1]
    one_time_customers = [c for c in items if c.get("orders_count", 0) == 1]
    
    table_data = [
        {
            "Segment": "Repeat Customers (2+)",
            "Count": len(repeat_customers),
            "Avg Orders": f"{sum(c.get('orders_count', 0) for c in repeat_customers) / len(repeat_customers):.1f}" if repeat_customers else "0",
            "Total Spent": f"${sum(float(c.get('total_spent', 0) or 0) for c in repeat_customers):,.2f}"
        },
        {
            "Segment": "One-time Customers",
            "Count": len(one_time_customers),
            "Avg Orders": "1.0",
            "Total Spent": f"${sum(float(c.get('total_spent', 0) or 0) for c in one_time_customers):,.2f}"
        }
    ]
    
    answer = f"Total customers: {len(items)}. Repeat customers (2+ purchases): {len(repeat_customers)}. One-time customers: {len(one_time_customers)}."
    
    return {
        "answer": answer,
        "table": table_data,
        "chart": None,
    }


def invoke_agent(question: str) -> AskResponse:
    """Generate Shopify analytics response using real API data."""
    try:
        question_lower = question.lower()
        result = None
        
        # Try to fetch orders data if question is about orders
        if "order" in question_lower:
            orders_data = fetch_orders_data(question)
            if orders_data:
                result = process_orders_response(orders_data, question)
        
        # Try to fetch products data if question is about products
        elif "product" in question_lower:
            products_data = fetch_products_data(question)
            if products_data:
                result = process_products_response(products_data, question)
        
        # Try to fetch customers data if question is about customers
        elif "customer" in question_lower or "repeat" in question_lower:
            customers_data = fetch_customers_data(question)
            if customers_data:
                result = process_customers_response(customers_data, question)
        
        # Default: try orders data
        if result is None:
            orders_data = fetch_orders_data(question)
            if orders_data:
                result = process_orders_response(orders_data, question)
        
        # If no data found, return error
        if result is None:
            return AskResponse(
                answer="Unable to fetch data from Shopify API. Please check your credentials and try again.",
                table=[],
                chart=None,
                warnings=["API Connection Failed"],
                raw_output="",
            )
        
        return AskResponse(
            answer=result.get("answer", ""),
            table=result.get("table") or [],
            chart=result.get("chart"),
            warnings=result.get("warnings", []),
            raw_output=json.dumps(result),
        )
    
    except Exception as e:
        logger.error(f"Agent error: {e}", exc_info=True)
        return AskResponse(
            answer="",
            table=[],
            chart=None,
            warnings=[f"Error: {str(e)}"],
            raw_output=str(e),
        )
