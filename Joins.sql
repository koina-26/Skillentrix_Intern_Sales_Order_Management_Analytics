USE olist_store;
GO

-- =============================================================
--  SECTION A — INNER JOINs (2 Tables)
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- A1. Customers with their Orders
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id;
 
-- ─────────────────────────────────────────────────────────────
-- A2. Orders with Payment Details
-- ─────────────────────────────────────────────────────────────
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM olist_orders_dataset o
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id;
 
-- ─────────────────────────────────────────────────────────────
-- A3. Order Items with Product Details
-- ─────────────────────────────────────────────────────────────
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.price,
    oi.freight_value,
    pr.product_id,
    pr.product_category_name,
    pr.product_weight_g
FROM olist_order_items_dataset oi
INNER JOIN olist_products_dataset pr
    ON oi.product_id = pr.product_id;
 
-- ─────────────────────────────────────────────────────────────
-- A4. Order Items with Seller Information
-- ─────────────────────────────────────────────────────────────
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.price,
    oi.freight_value,
    s.seller_id,
    s.seller_city,
    s.seller_state
FROM olist_order_items_dataset oi
INNER JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id;
 
 
-- =============================================================
--  SECTION B — LEFT JOINs
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- B1. ALL Customers — including those with no Orders
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status
FROM olist_customers_dataset c
LEFT JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id;
 
-- ─────────────────────────────────────────────────────────────
-- B2. ALL Orders — including those with no Payment Record
-- ─────────────────────────────────────────────────────────────
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    p.payment_type,
    p.payment_value
FROM olist_orders_dataset o
LEFT JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id;
 
-- ─────────────────────────────────────────────────────────────
-- B3. ALL Products — including those Never Ordered
-- ─────────────────────────────────────────────────────────────
SELECT
    pr.product_id,
    pr.product_category_name,
    oi.order_id,
    oi.price
FROM olist_products_dataset pr
LEFT JOIN olist_order_items_dataset oi
    ON pr.product_id = oi.product_id;
 
-- ─────────────────────────────────────────────────────────────
-- B4. Find Customers Who Have NEVER Placed an Order
--     (LEFT JOIN + WHERE NULL pattern)
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state
FROM olist_customers_dataset c
LEFT JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
 
-- ─────────────────────────────────────────────────────────────
-- B5. Find Products That Have NEVER Been Sold
-- ─────────────────────────────────────────────────────────────
SELECT
    pr.product_id,
    pr.product_category_name
FROM olist_products_dataset pr
LEFT JOIN olist_order_items_dataset oi
    ON pr.product_id = oi.product_id
WHERE oi.order_id IS NULL;
 
 
-- =============================================================
--  SECTION C — RIGHT JOINs
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- C1. ALL Sellers — including those with no Orders Placed
-- ─────────────────────────────────────────────────────────────
SELECT
    oi.order_id,
    oi.price,
    s.seller_id,
    s.seller_city,
    s.seller_state
FROM olist_order_items_dataset oi
RIGHT JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id;
 
-- ─────────────────────────────────────────────────────────────
-- C2. ALL Orders — including those with no Order Items Recorded
-- ─────────────────────────────────────────────────────────────
SELECT
    oi.order_item_id,
    oi.product_id,
    oi.price,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp
FROM olist_order_items_dataset oi
RIGHT JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id;
 
-- ─────────────────────────────────────────────────────────────
-- C3. Find Sellers with NO Sales (RIGHT JOIN + WHERE NULL)
-- ─────────────────────────────────────────────────────────────
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state
FROM olist_order_items_dataset oi
RIGHT JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id
WHERE oi.order_id IS NULL;
 
 
-- =============================================================
--  SECTION D — FULL OUTER JOINs
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- D1. ALL Products AND ALL Order Items (matched + unmatched both sides)
-- ─────────────────────────────────────────────────────────────
SELECT
    pr.product_id,
    pr.product_category_name,
    oi.order_id,
    oi.order_item_id,
    oi.price
FROM olist_products_dataset pr
FULL OUTER JOIN olist_order_items_dataset oi
    ON pr.product_id = oi.product_id;
 
-- ─────────────────────────────────────────────────────────────
-- D2. ALL Sellers AND ALL Order Items
-- ─────────────────────────────────────────────────────────────
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    oi.order_id,
    oi.price,
    oi.freight_value
FROM olist_sellers_dataset s
FULL OUTER JOIN olist_order_items_dataset oi
    ON s.seller_id = oi.seller_id;
 
-- ─────────────────────────────────────────────────────────────
-- D3. ALL Customers AND ALL Orders (both unmatched sides visible)
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status
FROM olist_customers_dataset c
FULL OUTER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id;
 
 
-- =============================================================
--  SECTION E — Multi-Table JOINs (3 to 6 Tables)
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- E1. 3 Tables : Customers → Orders → Payments
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id;
 
-- ─────────────────────────────────────────────────────────────
-- E2. 4 Tables : Orders → Items → Products → Sellers
-- ─────────────────────────────────────────────────────────────
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    pr.product_category_name,
    oi.price,
    oi.freight_value,
    s.seller_city,
    s.seller_state
FROM olist_orders_dataset o
INNER JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
INNER JOIN olist_products_dataset pr
    ON oi.product_id = pr.product_id
INNER JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id;
 
-- ─────────────────────────────────────────────────────────────
-- E3. 5 Tables : Customers → Orders → Items → Products → Sellers
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_unique_id,
    c.customer_city          AS customer_city,
    c.customer_state         AS customer_state,
    o.order_id,
    o.order_status,
    pr.product_category_name,
    oi.price,
    oi.freight_value,
    s.seller_city            AS seller_city,
    s.seller_state           AS seller_state
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
INNER JOIN olist_products_dataset pr
    ON oi.product_id = pr.product_id
INNER JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id;
 
-- ─────────────────────────────────────────────────────────────
-- E4. ALL 6 TABLES : Complete Order Report
--     Customers → Orders → Items → Products → Sellers → Payments
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_unique_id,
    c.customer_city                 AS customer_city,
    c.customer_state                AS customer_state,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    pr.product_category_name,
    oi.order_item_id,
    oi.price,
    oi.freight_value,
    s.seller_city                   AS seller_city,
    s.seller_state                  AS seller_state,
    pay.payment_type,
    pay.payment_installments,
    pay.payment_value
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
INNER JOIN olist_products_dataset pr
    ON oi.product_id = pr.product_id
INNER JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id
INNER JOIN olist_order_payments_dataset pay
    ON o.order_id = pay.order_id;
 
 
-- =============================================================
--  SECTION F — Business Analytics JOIN Queries
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- F1. Total Revenue & Order Count per Seller
-- ─────────────────────────────────────────────────────────────
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)         AS total_orders,
    SUM(oi.price)                       AS total_revenue,
    SUM(oi.freight_value)               AS total_freight,
    SUM(oi.price + oi.freight_value)    AS gross_total
FROM olist_sellers_dataset s
INNER JOIN olist_order_items_dataset oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC;
 
-- ─────────────────────────────────────────────────────────────
-- F2. Total Spending per Customer
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id)    AS total_orders,
    SUM(p.payment_value)          AS total_spent
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
ORDER BY total_spent DESC;
 
-- ─────────────────────────────────────────────────────────────
-- F3. Top Product Categories by Revenue
-- ─────────────────────────────────────────────────────────────
SELECT
    pr.product_category_name,
    COUNT(oi.order_item_id)       AS units_sold,
    SUM(oi.price)                 AS category_revenue,
    AVG(oi.price)                 AS avg_price
FROM olist_products_dataset pr
INNER JOIN olist_order_items_dataset oi
    ON pr.product_id = oi.product_id
GROUP BY pr.product_category_name
ORDER BY category_revenue DESC;
 
-- ─────────────────────────────────────────────────────────────
-- F4. Payment Type Breakdown by Order Status
-- ─────────────────────────────────────────────────────────────
SELECT
    o.order_status,
    p.payment_type,
    COUNT(*)                      AS payment_count,
    SUM(p.payment_value)          AS total_value,
    AVG(p.payment_value)          AS avg_value
FROM olist_orders_dataset o
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
GROUP BY o.order_status, p.payment_type
ORDER BY o.order_status, total_value DESC;
 
-- ─────────────────────────────────────────────────────────────
-- F5. Sellers with Product Categories and Revenue
-- ─────────────────────────────────────────────────────────────
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    pr.product_category_name,
    COUNT(oi.order_item_id)       AS units_sold,
    SUM(oi.price)                 AS revenue
FROM olist_sellers_dataset s
INNER JOIN olist_order_items_dataset oi
    ON s.seller_id = oi.seller_id
INNER JOIN olist_products_dataset pr
    ON oi.product_id = pr.product_id
GROUP BY s.seller_id, s.seller_city, s.seller_state, pr.product_category_name
ORDER BY revenue DESC;
 
-- ─────────────────────────────────────────────────────────────
-- F6. Delivered Orders: Customer City vs Seller City
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_city               AS customer_city,
    c.customer_state              AS customer_state,
    s.seller_city                 AS seller_city,
    s.seller_state                AS seller_state,
    COUNT(DISTINCT o.order_id)    AS total_delivered_orders,
    SUM(oi.freight_value)         AS total_freight_cost
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
INNER JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_city, c.customer_state, s.seller_city, s.seller_state
ORDER BY total_delivered_orders DESC;
 
 
-- =============================================================
--  SECTION G — CROSS JOINs
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- G1. Every possible combination of Customer State & Seller State
--     (useful for coverage gap analysis)
-- ─────────────────────────────────────────────────────────────
SELECT DISTINCT
    c.customer_state,
    s.seller_state
FROM olist_customers_dataset c
CROSS JOIN olist_sellers_dataset s
ORDER BY c.customer_state, s.seller_state;
 
-- ─────────────────────────────────────────────────────────────
-- G2. Every possible combination of Payment Types & Order Status
--     (to map which combinations actually exist in data)
-- ─────────────────────────────────────────────────────────────
SELECT DISTINCT
    o.order_status,
    p.payment_type
FROM olist_orders_dataset o
CROSS JOIN olist_order_payments_dataset p
ORDER BY o.order_status, p.payment_type;
 
-- ─────────────────────────────────────────────────────────────
-- G3. Every possible combination of Product Category & Seller State
-- ─────────────────────────────────────────────────────────────
SELECT DISTINCT
    pr.product_category_name,
    s.seller_state
FROM olist_products_dataset pr
CROSS JOIN olist_sellers_dataset s
ORDER BY pr.product_category_name, s.seller_state;
 
 
-- =============================================================
--  SECTION H — JOINs with TOP N
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- H1. Top 10 Customers by Total Spending
-- ─────────────────────────────────────────────────────────────
SELECT TOP 10
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id)    AS total_orders,
    SUM(p.payment_value)          AS total_spent
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
ORDER BY total_spent DESC;
 
-- ─────────────────────────────────────────────────────────────
-- H2. Top 10 Best-Selling Products by Units Sold
-- ─────────────────────────────────────────────────────────────
SELECT TOP 10
    pr.product_id,
    pr.product_category_name,
    COUNT(oi.order_item_id)       AS units_sold,
    SUM(oi.price)                 AS total_revenue
FROM olist_products_dataset pr
INNER JOIN olist_order_items_dataset oi
    ON pr.product_id = oi.product_id
GROUP BY pr.product_id, pr.product_category_name
ORDER BY units_sold DESC;
 
-- ─────────────────────────────────────────────────────────────
-- H3. Top 10 Sellers by Total Revenue
-- ─────────────────────────────────────────────────────────────
SELECT TOP 10
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)   AS total_orders,
    SUM(oi.price)                 AS total_revenue
FROM olist_sellers_dataset s
INNER JOIN olist_order_items_dataset oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC;
 
-- ─────────────────────────────────────────────────────────────
-- H4. Top 5 Most Expensive Single Orders (by Payment Value)
-- ─────────────────────────────────────────────────────────────
SELECT TOP 5
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_unique_id,
    c.customer_city,
    p.payment_type,
    p.payment_value
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
ORDER BY p.payment_value DESC;
 
-- ─────────────────────────────────────────────────────────────
-- H5. Top 5 Product Categories with Highest Average Price
-- ─────────────────────────────────────────────────────────────
SELECT TOP 5
    pr.product_category_name,
    COUNT(oi.order_item_id)       AS units_sold,
    AVG(oi.price)                 AS avg_price,
    MAX(oi.price)                 AS max_price,
    MIN(oi.price)                 AS min_price
FROM olist_products_dataset pr
INNER JOIN olist_order_items_dataset oi
    ON pr.product_id = oi.product_id
GROUP BY pr.product_category_name
ORDER BY avg_price DESC;
 
 
-- =============================================================
--  SECTION I — JOINs with DATE FILTERS
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- I1. Orders Placed in a Specific Year (e.g. 2018)
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    p.payment_value
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
WHERE YEAR(o.order_purchase_timestamp) = 2018;
 
-- ─────────────────────────────────────────────────────────────
-- I2. Orders Placed in a Specific Month & Year (e.g. January 2018)
-- ─────────────────────────────────────────────────────────────
SELECT
    o.order_id,
    o.order_purchase_timestamp,
    o.order_status,
    c.customer_city,
    c.customer_state,
    p.payment_type,
    p.payment_value
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
WHERE YEAR(o.order_purchase_timestamp)  = 2018
  AND MONTH(o.order_purchase_timestamp) = 1;
 
-- ─────────────────────────────────────────────────────────────
-- I3. Orders Placed in the Last 6 Months (relative to latest date in data)
-- ─────────────────────────────────────────────────────────────
SELECT
    o.order_id,
    o.order_purchase_timestamp,
    o.order_status,
    c.customer_city,
    p.payment_value
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
WHERE o.order_purchase_timestamp >= DATEADD(MONTH, -6,
      (SELECT MAX(order_purchase_timestamp) FROM olist_orders_dataset));
 
-- ─────────────────────────────────────────────────────────────
-- I4. Revenue Generated per Month (Monthly Sales Trend)
-- ─────────────────────────────────────────────────────────────
SELECT
    YEAR(o.order_purchase_timestamp)    AS order_year,
    MONTH(o.order_purchase_timestamp)   AS order_month,
    COUNT(DISTINCT o.order_id)          AS total_orders,
    SUM(p.payment_value)                AS monthly_revenue
FROM olist_orders_dataset o
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
GROUP BY
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp)
ORDER BY order_year, order_month;
 
-- ─────────────────────────────────────────────────────────────
-- I5. Orders Delivered Late (delivered after estimated date)
-- ─────────────────────────────────────────────────────────────
SELECT
    o.order_id,
    o.order_purchase_timestamp,
    o.order_estimated_delivery_date,
    o.order_delivered_customer_date,
    c.customer_city,
    c.customer_state,
    DATEDIFF(DAY,
        o.order_estimated_delivery_date,
        o.order_delivered_customer_date) AS days_late
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
ORDER BY days_late DESC;
 
 
-- =============================================================
--  SECTION J — JOINs with HAVING Clause
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- J1. Sellers who have Processed more than 10 Orders
-- ─────────────────────────────────────────────────────────────
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)    AS total_orders,
    SUM(oi.price)                  AS total_revenue
FROM olist_sellers_dataset s
INNER JOIN olist_order_items_dataset oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING COUNT(DISTINCT oi.order_id) > 10
ORDER BY total_orders DESC;
 
-- ─────────────────────────────────────────────────────────────
-- J2. Product Categories with Total Revenue above 50,000
-- ─────────────────────────────────────────────────────────────
SELECT
    pr.product_category_name,
    COUNT(oi.order_item_id)       AS units_sold,
    SUM(oi.price)                 AS total_revenue
FROM olist_products_dataset pr
INNER JOIN olist_order_items_dataset oi
    ON pr.product_id = oi.product_id
GROUP BY pr.product_category_name
HAVING SUM(oi.price) > 50000
ORDER BY total_revenue DESC;
 
-- ─────────────────────────────────────────────────────────────
-- J3. Customers who have Placed more than 2 Orders
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id)    AS total_orders,
    SUM(p.payment_value)          AS total_spent
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
HAVING COUNT(DISTINCT o.order_id) > 2
ORDER BY total_orders DESC;
 
-- ─────────────────────────────────────────────────────────────
-- J4. States with Average Order Payment Value above 200
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id)    AS total_orders,
    AVG(p.payment_value)          AS avg_payment_value,
    SUM(p.payment_value)          AS total_revenue
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
GROUP BY c.customer_state
HAVING AVG(p.payment_value) > 200
ORDER BY avg_payment_value DESC;
 
-- ─────────────────────────────────────────────────────────────
-- J5. Sellers Selling more than 3 Different Product Categories
-- ─────────────────────────────────────────────────────────────
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT pr.product_category_name)  AS distinct_categories,
    COUNT(DISTINCT oi.order_id)               AS total_orders
FROM olist_sellers_dataset s
INNER JOIN olist_order_items_dataset oi
    ON s.seller_id = oi.seller_id
INNER JOIN olist_products_dataset pr
    ON oi.product_id = pr.product_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING COUNT(DISTINCT pr.product_category_name) > 3
ORDER BY distinct_categories DESC;
 
 
-- =============================================================
--  SECTION K — JOINs with Multiple WHERE Conditions
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- K1. Delivered Orders from a Specific State Paid by Credit Card
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    p.payment_type,
    p.payment_value
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
WHERE o.order_status   = 'delivered'
  AND p.payment_type   = 'credit_card'
  AND c.customer_state = 'SP';
 
-- ─────────────────────────────────────────────────────────────
-- K2. High-Value Orders (payment > 500) That Are Still Pending/Processing
-- ─────────────────────────────────────────────────────────────
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_unique_id,
    c.customer_city,
    p.payment_type,
    p.payment_value
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
WHERE p.payment_value > 500
  AND o.order_status IN ('processing', 'pending')
ORDER BY p.payment_value DESC;
 
-- ─────────────────────────────────────────────────────────────
-- K3. Products in a Specific Category Sold by Sellers from a Specific State
-- ─────────────────────────────────────────────────────────────
SELECT
    pr.product_id,
    pr.product_category_name,
    oi.order_id,
    oi.price,
    oi.freight_value,
    s.seller_id,
    s.seller_city,
    s.seller_state
FROM olist_products_dataset pr
INNER JOIN olist_order_items_dataset oi
    ON pr.product_id = oi.product_id
INNER JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id
WHERE pr.product_category_name = 'cama_mesa_banho'  -- Change category as needed
  AND s.seller_state            = 'SP';
 
-- ─────────────────────────────────────────────────────────────
-- K4. Customers who Paid in Installments (> 3) for Delivered Orders above 300
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
INNER JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
WHERE p.payment_installments > 3
  AND p.payment_value         > 300
  AND o.order_status          = 'delivered'
ORDER BY p.payment_installments DESC;
 
-- ─────────────────────────────────────────────────────────────
-- K5. Order Items with High Freight Cost Relative to Price (> 20% of Price)
-- ─────────────────────────────────────────────────────────────
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.price,
    oi.freight_value,
    pr.product_category_name,
    s.seller_city,
    s.seller_state,
    ROUND((oi.freight_value / oi.price) * 100, 2)  AS freight_percentage
FROM olist_order_items_dataset oi
INNER JOIN olist_products_dataset pr
    ON oi.product_id = pr.product_id
INNER JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id
WHERE oi.price            > 0
  AND oi.freight_value    > 0
  AND (oi.freight_value / oi.price) > 0.20
ORDER BY freight_percentage DESC;
 
 
-- =============================================================
--  STEP 0 — CREATE INDEXES (Run Once Before Section L Queries)
--  These speed up self join lookups significantly
-- =============================================================
 
CREATE INDEX idx_customer_city_state
    ON olist_customers_dataset (customer_city, customer_state);
 
CREATE INDEX idx_seller_state
    ON olist_sellers_dataset (seller_state);
 
CREATE INDEX idx_product_category
    ON olist_products_dataset (product_category_name);
 
CREATE INDEX idx_order_customer_date
    ON olist_orders_dataset (customer_id, order_purchase_timestamp);
 
 
-- =============================================================
--  SECTION L — SELF JOINs (OPTIMIZED)
-- =============================================================
 
-- ─────────────────────────────────────────────────────────────
-- L1. Customers from the Same City
--     FIX : TOP 100 + filter to one city prevents pairing
--           every customer with every other customer
-- ─────────────────────────────────────────────────────────────
SELECT TOP 100
    c1.customer_unique_id   AS customer_1,
    c2.customer_unique_id   AS customer_2,
    c1.customer_city        AS shared_city,
    c1.customer_state       AS shared_state
FROM olist_customers_dataset c1
INNER JOIN olist_customers_dataset c2
    ON  c1.customer_city       = c2.customer_city
    AND c1.customer_state      = c2.customer_state
    AND c1.customer_unique_id  < c2.customer_unique_id
WHERE c1.customer_city = 'sao paulo'          -- Change city as needed
ORDER BY c1.customer_city;
 
-- ─────────────────────────────────────────────────────────────
-- L1B. Cities with More than 1 Customer (Fast Summary Alternative)
-- ─────────────────────────────────────────────────────────────
SELECT
    customer_city,
    customer_state,
    COUNT(customer_unique_id)   AS total_customers
FROM olist_customers_dataset
GROUP BY customer_city, customer_state
HAVING COUNT(customer_unique_id) > 1
ORDER BY total_customers DESC;
 
-- ─────────────────────────────────────────────────────────────
-- L2. Sellers from the Same State
--     FIX : TOP 100 + filter to one state
-- ─────────────────────────────────────────────────────────────
SELECT TOP 100
    s1.seller_id       AS seller_1,
    s2.seller_id       AS seller_2,
    s1.seller_city     AS seller_city,
    s1.seller_state    AS shared_state
FROM olist_sellers_dataset s1
INNER JOIN olist_sellers_dataset s2
    ON  s1.seller_state   = s2.seller_state
    AND s1.seller_id      < s2.seller_id
WHERE s1.seller_state = 'SP'                  -- Change state as needed
ORDER BY s1.seller_state;
 
-- ─────────────────────────────────────────────────────────────
-- L2B. States with More than 1 Seller (Fast Summary Alternative)
-- ─────────────────────────────────────────────────────────────
SELECT
    seller_state,
    COUNT(seller_id)    AS total_sellers
FROM olist_sellers_dataset
GROUP BY seller_state
HAVING COUNT(seller_id) > 1
ORDER BY total_sellers DESC;
 
-- ─────────────────────────────────────────────────────────────
-- L3. Products in the Same Category with Different Prices
--     FIX : CTE pre-aggregates avg price per product first
--           so raw order_items rows are not joined directly
-- ─────────────────────────────────────────────────────────────
WITH product_avg_price AS (
    SELECT
        product_id,
        AVG(price)  AS avg_price
    FROM olist_order_items_dataset
    GROUP BY product_id
)
SELECT TOP 50
    pr1.product_id               AS product_1,
    pr2.product_id               AS product_2,
    pr1.product_category_name    AS shared_category,
    ROUND(p1.avg_price, 2)       AS avg_price_product_1,
    ROUND(p2.avg_price, 2)       AS avg_price_product_2,
    ROUND(ABS(p1.avg_price
            - p2.avg_price), 2)  AS price_difference
FROM olist_products_dataset pr1
INNER JOIN olist_products_dataset pr2
    ON  pr1.product_category_name  = pr2.product_category_name
    AND pr1.product_id             < pr2.product_id
INNER JOIN product_avg_price p1
    ON pr1.product_id = p1.product_id
INNER JOIN product_avg_price p2
    ON pr2.product_id = p2.product_id
WHERE ABS(p1.avg_price - p2.avg_price) > 100
ORDER BY price_difference DESC;
 
-- ─────────────────────────────────────────────────────────────
-- L4. Orders Placed by the Same Customer on Different Dates
--     FIX : CTE pre-filters to repeat customers only
--           so single-order customers are excluded early
-- ─────────────────────────────────────────────────────────────
WITH repeat_customers AS (
    SELECT customer_id
    FROM olist_orders_dataset
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
)
SELECT TOP 100
    o1.customer_id,
    o1.order_id                      AS first_order_id,
    o1.order_purchase_timestamp      AS first_order_date,
    o2.order_id                      AS second_order_id,
    o2.order_purchase_timestamp      AS second_order_date,
    DATEDIFF(DAY,
        o1.order_purchase_timestamp,
        o2.order_purchase_timestamp)  AS days_between_orders
FROM olist_orders_dataset o1
INNER JOIN olist_orders_dataset o2
    ON  o1.customer_id   = o2.customer_id
    AND o1.order_id     <> o2.order_id
    AND o1.order_purchase_timestamp < o2.order_purchase_timestamp
INNER JOIN repeat_customers rc
    ON o1.customer_id = rc.customer_id
ORDER BY days_between_orders;