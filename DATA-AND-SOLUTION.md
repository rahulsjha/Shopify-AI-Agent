# SHOPIFY AI AGENT - DATA & SOLUTION ARCHITECTURE

## 1. DATA SOURCES & STRUCTURE

### Data Categories Used

#### A. **Order Data**
```
Orders Table Schema:
- order_id: unique identifier
- customer_id: buyer reference
- order_date: timestamp
- order_value: total revenue
- item_count: quantity of products
- shipping_address: city/region
- fulfillment_status: pending/shipped/delivered
- payment_method: credit card, PayPal, etc
```

**Typical Values:**
- Daily order volume: 17-32 orders
- Average order value: $347-$471
- Weekly totals: 145 orders, ~$55,000 revenue
- Growth rate: 8-12% week-over-week

#### B. **Product Data**
```
Products Table Schema:
- product_id: unique identifier
- name: product title
- sku: inventory code
- price: unit price
- cost: COGS
- margin: profit margin %
- units_sold: quantity sold
- revenue: total sales
- category: product type
```

**Top Products:**
- Wireless Headphones: 850 units, $42,500 revenue, 38% margin
- Phone Case Bundle: 1,220 units, $28,900 revenue, 45% margin
- USB-C Cable Pack: 2,500 units, $18,750 revenue, 52% margin
- Screen Protector: 1,890 units, $14,175 revenue, 58% margin
- Wireless Charger: 420 units, $12,600 revenue, 42% margin

#### C. **Customer Data**
```
Customers Table Schema:
- customer_id: unique identifier
- email: contact
- first_purchase_date: signup date
- total_purchases: lifetime order count
- total_lifetime_value: LTV
- last_order_date: recency
- city/state: geography
- repeat_status: one-time or repeat
```

**Segments:**
- Repeat Customers (2+ purchases): 342 customers, 38% of revenue
- One-time Customers: 1,855 customers, 62% of revenue
- Top repeat customer: 18 purchases, $8,420 LTV

#### D. **Geographic Data**
```
Cities Table Schema:
- city: location name
- orders: count
- revenue: total sales
- avg_order_value: AOV
- customer_count: unique buyers
```

**Top Cities:**
- New York: 320 orders, $145,200 revenue
- Los Angeles: 285 orders, $128,500 revenue
- Chicago: 218 orders, $98,750 revenue
- Houston: 193 orders, $87,300 revenue
- Phoenix: 156 orders, $71,240 revenue

---

## 2. HOW WE SOLVE (Response Generation Strategy)

### Solution Architecture

```
┌─────────────────────────────────────────────────────────┐
│ User Question: "How many orders in the last 7 days?"   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │ Pattern Matching Engine    │
        │ - Analyze question text    │
        │ - Match intent keywords    │
        │ - Determine output type    │
        └────────────┬───────────────┘
                     │
        ┌────────────▼────────────────────────┐
        │ Response Template Selection:       │
        │ - Table format (rows/columns)      │
        │ - Chart type (line/bar)            │
        │ - Warning messages                 │
        └────────────┬───────────────────────┘
                     │
        ┌────────────▼────────────────────────┐
        │ Data Population:                   │
        │ - Fill tables with realistic data  │
        │ - Generate chart series            │
        │ - Create natural language answer   │
        └────────────┬───────────────────────┘
                     │
                     ▼
    ┌─────────────────────────────────────┐
    │ JSON Response Contract:             │
    │ {                                  │
    │   answer: "Natural language text"  │
    │   table: [{...}, {...}, ...]      │
    │   chart: {type, title, series}    │
    │   warnings: ["Note 1", "Note 2"]  │
    │ }                                  │
    └─────────────────────────────────────┘
```

### Pattern Matching Keywords

| Pattern | Keywords | Response Type |
|---------|----------|---|
| Orders | order, orders, volume, count | table + line chart |
| Products | product, products, sold, top, best | table + bar chart |
| Revenue | revenue, sales, income, money | table + bar chart |
| Customers | customer, repeat, loyalty, segment | table only |
| Trends | trend, aov, average, growth, increase | table + line chart |
| Recommendations | recommend, promote, suggest, boost | table only |
| Volume/Graph | graph, plot, volume, visualization | chart only |

### Data Generation Logic

**For Tables:**
1. Identify metric (orders, revenue, products, etc.)
2. Define time period (7 days, 4 weeks, monthly)
3. Create realistic rows with related values
4. Ensure mathematical consistency (totals, percentages)
5. Add contextual metrics (AOV, margin, growth %)

**For Charts:**
1. Determine type (line for trends, bar for categories)
2. Extract data points from table
3. Build series with x/y coordinates
4. Add title, axis labels
5. Format numbers appropriately

**For Answers:**
1. Summarize key finding (number, percentage, trend)
2. Add business insight (growth rate, top performer)
3. Highlight anomalies or opportunities
4. Keep natural and conversational

---

## 3. ORIGINAL 7 SAMPLE QUESTIONS

1. ✅ How many orders in the last 7 days?
2. ✅ Which products sold the most?
3. ✅ Show revenue breakdown by city
4. ✅ Who are my repeat customers?
5. ✅ What is the AOV trend this month?
6. ✅ What products should I promote?
7. ✅ Plot order volume over past 4 weeks

---

## 4. NEW 20 SIMILAR QUESTIONS (Extended Coverage)

### A. ORDER ANALYTICS (5 questions)
8. **What was the order value this week?**
   - Response: Weekly revenue total + daily breakdown table + line chart
   - Table: Date | Orders | Revenue | AOV
   - Chart: Line chart showing daily revenue trend

9. **How many orders from new vs returning customers?**
   - Response: Customer segmentation analysis
   - Table: Customer Type | Orders | Revenue | %
   - Chart: Bar chart comparing segments

10. **What's the highest order value recorded?**
    - Response: Max order details + context
    - Table: Customer | Date | Value | Product Count
    - Chart: N/A (single metric)

11. **Show me daily order trends for the last 14 days**
    - Response: Two-week trend analysis
    - Table: Date | Orders | Revenue | Growth %
    - Chart: Line chart with 14 data points

12. **Which day of the week has the most orders?**
    - Response: Weekly pattern analysis
    - Table: Day | Orders | Revenue | %
    - Chart: Bar chart by day of week

### B. PRODUCT ANALYTICS (5 questions)
13. **What are the lowest performing products?**
    - Response: Bottom 5 products analysis
    - Table: Product | Units | Revenue | Margin | Status
    - Chart: Bar chart (ascending order)

14. **Which products have the highest profit margin?**
    - Response: Margin analysis with recommendations
    - Table: Product | Cost | Price | Margin % | Volume
    - Chart: Bar chart showing margins

15. **What's the average product price?**
    - Response: Price point analysis
    - Table: Price Range | Product Count | Revenue | %
    - Chart: Bar chart by price tier

16. **Show product category performance**
    - Response: Category-level breakdown
    - Table: Category | Units | Revenue | AOV | Top Product
    - Chart: Bar chart by category

17. **Which product has the best sales velocity?**
    - Response: Top accelerating product
    - Table: Product | Week 1 | Week 2 | Week 3 | Growth %
    - Chart: Line chart showing velocity

### C. REVENUE & FINANCIAL (5 questions)
18. **What's our total revenue this month?**
    - Response: Monthly financial summary
    - Table: Week | Orders | Revenue | Growth | Cumulative
    - Chart: Line chart with cumulative line

19. **Which city generates the most revenue per order?**
    - Response: City AOV analysis
    - Table: City | Orders | Revenue | AOV | Rank
    - Chart: Bar chart by AOV

20. **What's the revenue forecast for next week?**
    - Response: Predictive analysis
    - Table: Day | Forecast | Confidence | Range
    - Chart: Line chart with confidence band

21. **Show me revenue breakdown by payment method**
    - Response: Payment channel analysis
    - Table: Method | Orders | Revenue | % | Avg Transaction
    - Chart: Bar chart by method

22. **What's the customer acquisition cost trend?**
    - Response: CAC efficiency analysis
    - Table: Week | New Customers | Marketing Spend | CAC
    - Chart: Line chart showing CAC trend

### D. CUSTOMER INTELLIGENCE (5 questions)
23. **What's the churn rate this month?**
    - Response: Customer retention analysis
    - Table: Month | Active Customers | Churned | Retention %
    - Chart: Line chart showing retention trend

24. **Which customers are at risk of churning?**
    - Response: At-risk customer segment
    - Table: Customer | Last Purchase | Days Since | Spend | Risk Score
    - Chart: N/A

25. **What's the average customer lifetime value?**
    - Response: LTV analysis by cohort
    - Table: Cohort Month | Avg LTV | Purchases | Revenue | Trend
    - Chart: Line chart showing LTV trend

26. **Show me customer acquisition by source**
    - Response: Channel attribution
    - Table: Source | New Customers | Revenue | CAC | ROI
    - Chart: Bar chart by source

27. **Which customer segments are most profitable?**
    - Response: Segment profitability
    - Table: Segment | Count | Revenue | % | Profit | Margin
    - Chart: Bar chart by segment

---

## 5. RESPONSE EXAMPLES FOR NEW QUESTIONS

### Example 1: Question #8 - Weekly Order Value
```json
{
  "answer": "Total revenue this week: $55,340 across 145 orders. Average order value is $382.07, showing a 3% increase from last week. Tuesday was the strongest day with $8,920 in revenue.",
  "table": [
    {"Date": "2026-04-30", "Orders": 18, "Revenue": "$6,240", "AOV": "$347"},
    {"Date": "2026-05-01", "Orders": 22, "Revenue": "$8,580", "AOV": "$390"},
    {"Date": "2026-05-02", "Orders": 21, "Revenue": "$7,890", "AOV": "$376"},
    {"Date": "2026-05-03", "Orders": 19, "Revenue": "$6,850", "AOV": "$361"},
    {"Date": "2026-05-04", "Orders": 25, "Revenue": "$9,500", "AOV": "$380"},
    {"Date": "2026-05-05", "Orders": 23, "Revenue": "$8,920", "AOV": "$388"},
    {"Date": "2026-05-06", "Orders": 17, "Revenue": "$5,980", "AOV": "$352"}
  ],
  "chart": {
    "type": "line",
    "title": "Daily Revenue This Week",
    "x_label": "Date",
    "y_label": "Revenue ($)",
    "series": [{
      "name": "Revenue",
      "points": [
        {"x": "04-30", "y": 6240},
        {"x": "05-01", "y": 8580},
        {"x": "05-02", "y": 7890},
        {"x": "05-03", "y": 6850},
        {"x": "05-04", "y": 9500},
        {"x": "05-05", "y": 8920},
        {"x": "05-06", "y": 5980}
      ]
    }]
  }
}
```

### Example 2: Question #13 - Lowest Performing Products
```json
{
  "answer": "Your bottom 5 products have underperformed. USB Hub (23 units) and Portable Speaker (31 units) are generating minimal revenue. Consider discontinuing or repositioning these items.",
  "table": [
    {"Rank": 1, "Product": "USB Hub", "Units": 23, "Revenue": "$920", "Margin": "15%"},
    {"Rank": 2, "Product": "Portable Speaker", "Units": 31, "Revenue": "$1,550", "Margin": "22%"},
    {"Rank": 3, "Product": "Screen Cleaner", "Units": 45, "Revenue": "$1,800", "Margin": "18%"},
    {"Rank": 4, "Product": "Cable Organizer", "Units": 52, "Revenue": "$2,080", "Margin": "25%"},
    {"Rank": 5, "Product": "Mouse Pad", "Units": 67, "Revenue": "$2,680", "Margin": "28%"}
  ],
  "chart": {
    "type": "bar",
    "title": "Bottom 5 Products by Revenue",
    "x_label": "Product",
    "y_label": "Revenue ($)",
    "series": [{
      "name": "Revenue",
      "points": [
        {"x": "USB Hub", "y": 920},
        {"x": "Portable Speaker", "y": 1550},
        {"x": "Screen Cleaner", "y": 1800},
        {"x": "Cable Organizer", "y": 2080},
        {"x": "Mouse Pad", "y": 2680}
      ]
    }]
  }
}
```

---

## 6. HOW IT ALL WORKS TOGETHER

**Flow:**
1. User asks question → Frontend sends to backend API
2. Backend receives question string
3. Agent pattern matcher analyzes keywords
4. Appropriate response template selected
5. Realistic data populated based on templates
6. JSON response built (answer + table + chart)
7. Frontend receives JSON and renders:
   - Answer text in hero section
   - Table with responsive columns
   - Chart (SVG line or bar)
   - Warnings if any
8. User sees complete analytics dashboard

**No External API Calls Needed** (for now):
- All data is generated realistically based on templates
- Future: Can integrate with real Shopify API for live data
- Current approach: Perfect for demos, testing, prototypes

---

## 7. IMPLEMENTATION PRIORITY

**Phase 1 (Already Done):** 7 core questions ✅
**Phase 2 (Ready to Implement):** 20 new questions → Extend agent_production.py
**Phase 3:** Real Shopify API integration
**Phase 4:** ML-based predictions & recommendations
**Phase 5:** Multi-language support

