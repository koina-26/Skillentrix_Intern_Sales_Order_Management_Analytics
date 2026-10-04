USE olist_store;
GO


-- ============================================================
-- SECTION 6A: BASIC AGGREGATE FUNCTIONS
-- ============================================================
 
-- Q1: Total number of orders in the dataset
SELECT COUNT(*) AS total_orders
FROM olist_orders_dataset;
 
-- Q2: Total revenue from all payments
SELECT SUM(payment_value) AS total_revenue
FROM olist_order_payments_dataset;
 
-- Q3: Average payment value per transaction
SELECT ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM olist_order_payments_dataset;
 
-- Q4: Minimum and maximum payment value
SELECT
    MIN(payment_value) AS min_payment,
    MAX(payment_value) AS max_payment
FROM olist_order_payments_dataset;
 
-- Q5: Total distinct customers (by unique ID)
SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_dataset;
 
-- Q6: Total number of products listed
SELECT COUNT(*) AS total_products
FROM olist_products_dataset;
 
-- Q7: Total number of registered sellers
SELECT COUNT(*) AS total_sellers
FROM olist_sellers_dataset;
 
-- Q8: Freight value summary across all order items
SELECT
    SUM(freight_value)  AS total_freight,
    ROUND(AVG(freight_value), 2) AS avg_freight,
    MIN(freight_value)  AS min_freight,
    MAX(freight_value)  AS max_freight
FROM olist_order_items_dataset;
 
-- Q9: Item price summary across all order items
SELECT
    COUNT(*)                     AS total_items_sold,
    ROUND(AVG(price), 2)         AS avg_item_price,
    MIN(price)                   AS min_price,
    MAX(price)                   AS max_price,
    ROUND(SUM(price), 2)         AS total_sales_value
FROM olist_order_items_dataset;
 
-- Q10: Payment installment summary
SELECT
    SUM(payment_installments)        AS total_installments,
    ROUND(AVG(payment_installments * 1.0), 2) AS avg_installments,
    MAX(payment_installments)        AS max_installments,
    MIN(payment_installments)        AS min_installments
FROM olist_order_payments_dataset;
 
 
-- ============================================================
-- SECTION 6B: GROUP BY QUERIES
-- ============================================================
 
-- Q11: Count of orders by order status
SELECT
    order_status,
    COUNT(*) AS order_count
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY order_count DESC;
 
-- Q12: Total revenue and transaction count by payment type
SELECT
    payment_type,
    COUNT(*)                    AS payment_count,
    ROUND(SUM(payment_value), 2) AS total_revenue,
    ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_revenue DESC;
 
-- Q13: Number of customers per state
SELECT
    customer_state,
    COUNT(*) AS customer_count
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY customer_count DESC;
 
-- Q14: Number of sellers per state
SELECT
    seller_state,
    COUNT(*) AS seller_count
FROM olist_sellers_dataset
GROUP BY seller_state
ORDER BY seller_count DESC;
 
-- Q15: Product count per category (excluding NULLs)
SELECT
    product_category_name,
    COUNT(*) AS product_count
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY product_count DESC;
 
-- Q16: Total orders placed per year
SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*)                       AS total_orders
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;
 
-- Q17: Total orders placed per year and month
SELECT
    YEAR(order_purchase_timestamp)  AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*)                        AS total_orders
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)
ORDER BY order_year, order_month;
 
-- Q18: Revenue by payment type with % share of total revenue
SELECT
    payment_type,
    COUNT(*)                    AS transaction_count,
    ROUND(SUM(payment_value), 2) AS total_revenue,
    ROUND(
        SUM(payment_value) * 100.0 /
        SUM(SUM(payment_value)) OVER(), 2
    )                           AS revenue_pct
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_revenue DESC;
 
-- Q19: Average, min, max installments by payment type
SELECT
    payment_type,
    ROUND(AVG(payment_installments * 1.0), 2) AS avg_installments,
    MIN(payment_installments)                 AS min_installments,
    MAX(payment_installments)                 AS max_installments
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY avg_installments DESC;
 
-- Q20: Items sold and revenue per product category (JOIN)
SELECT
    p.product_category_name,
    COUNT(oi.order_item_id)       AS items_sold,
    ROUND(SUM(oi.price), 2)       AS total_revenue,
    ROUND(AVG(oi.price), 2)       AS avg_selling_price,
    ROUND(MIN(oi.price), 2)       AS min_price,
    ROUND(MAX(oi.price), 2)       AS max_price
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;
 
 
-- ============================================================
-- SECTION 6C: GROUP BY WITH HAVING
-- ============================================================
 
-- Q21: States with more than 1000 customers
SELECT
    customer_state,
    COUNT(*) AS customer_count
FROM olist_customers_dataset
GROUP BY customer_state
HAVING COUNT(*) > 1000
ORDER BY customer_count DESC;
 
-- Q22: Payment types where average payment value exceeds 100
SELECT
    payment_type,
    COUNT(*)                    AS payment_count,
    ROUND(AVG(payment_value), 2) AS avg_payment
FROM olist_order_payments_dataset
GROUP BY payment_type
HAVING AVG(payment_value) > 100
ORDER BY avg_payment DESC;
 
-- Q23: Product categories with more than 100 products listed
SELECT
    product_category_name,
    COUNT(*) AS product_count
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
HAVING COUNT(*) > 100
ORDER BY product_count DESC;
 
-- Q24: Sellers with more than 50 order items fulfilled
SELECT
    seller_id,
    COUNT(*)              AS items_fulfilled,
    ROUND(SUM(price), 2)  AS total_revenue
FROM olist_order_items_dataset
GROUP BY seller_id
HAVING COUNT(*) > 50
ORDER BY total_revenue DESC;
 
-- Q25: Year-Month periods with more than 500 orders placed
SELECT
    YEAR(order_purchase_timestamp)  AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*)                        AS order_count
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)
HAVING COUNT(*) > 500
ORDER BY order_year, order_month;
 
-- Q26: Product categories generating total revenue above 100,000
SELECT
    p.product_category_name,
    COUNT(oi.order_item_id)  AS items_sold,
    ROUND(SUM(oi.price), 2)  AS total_revenue
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
HAVING SUM(oi.price) > 100000
ORDER BY total_revenue DESC;
 
 
-- ============================================================
-- SECTION 6D: MULTI-COLUMN GROUP BY
-- ============================================================
 
-- Q27: Order count by status and year
SELECT
    order_status,
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*)                       AS order_count
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY
    order_status,
    YEAR(order_purchase_timestamp)
ORDER BY order_year, order_status;
 
-- Q28: Revenue by seller state and payment type
SELECT
    s.seller_state,
    pay.payment_type,
    COUNT(DISTINCT o.order_id)        AS order_count,
    ROUND(SUM(pay.payment_value), 2)  AS total_revenue
FROM olist_order_items_dataset oi
JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id
JOIN olist_order_payments_dataset pay
    ON oi.order_id = pay.order_id
JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
GROUP BY s.seller_state, pay.payment_type
ORDER BY total_revenue DESC;
 
-- Q29: Items sold and revenue by product category and year
SELECT
    p.product_category_name,
    YEAR(o.order_purchase_timestamp) AS order_year,
    COUNT(oi.order_item_id)          AS items_sold,
    ROUND(SUM(oi.price), 2)          AS total_revenue
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE p.product_category_name IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY
    p.product_category_name,
    YEAR(o.order_purchase_timestamp)
ORDER BY order_year, total_revenue DESC;
 
-- Q30: Customer cities with 50+ orders — order and spend summary
SELECT
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id)       AS total_orders,
    ROUND(SUM(pay.payment_value), 2) AS total_spent,
    ROUND(AVG(pay.payment_value), 2) AS avg_order_value
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
JOIN olist_order_payments_dataset pay
    ON o.order_id = pay.order_id
GROUP BY c.customer_city, c.customer_state
HAVING COUNT(DISTINCT o.order_id) > 50
ORDER BY total_spent DESC;
 
 
-- ============================================================
-- SECTION 6E: BUSINESS ANALYTICS AGGREGATIONS
-- ============================================================
 
-- Q31: Top 10 revenue-generating product categories
SELECT TOP 10
    p.product_category_name,
    COUNT(oi.order_item_id)       AS units_sold,
    ROUND(SUM(oi.price), 2)       AS total_revenue,
    ROUND(AVG(oi.price), 2)       AS avg_selling_price
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;
 
-- Q32: Top 10 sellers by total revenue
SELECT TOP 10
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(oi.order_item_id)   AS items_sold,
    ROUND(SUM(oi.price), 2)   AS total_revenue,
    ROUND(AVG(oi.price), 2)   AS avg_price_per_item
FROM olist_order_items_dataset oi
JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id
GROUP BY oi.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC;
 
-- Q33: Monthly revenue trend (all years combined)
SELECT
    YEAR(o.order_purchase_timestamp)  AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    COUNT(DISTINCT o.order_id)         AS total_orders,
    ROUND(SUM(pay.payment_value), 2)   AS monthly_revenue,
    ROUND(AVG(pay.payment_value), 2)   AS avg_order_value
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset pay
    ON o.order_id = pay.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp)
ORDER BY order_year, order_month;
 
-- Q34: Average, min, and max items per order (subquery aggregate)
SELECT
    ROUND(AVG(items_per_order * 1.0), 2) AS avg_items_per_order,
    MIN(items_per_order)                 AS min_items_in_order,
    MAX(items_per_order)                 AS max_items_in_order
FROM (
    SELECT order_id, COUNT(*) AS items_per_order
    FROM olist_order_items_dataset
    GROUP BY order_id
) AS order_summary;
 
-- Q35: Average delivery days by customer state (delivered orders only)
SELECT
    c.customer_state,
    COUNT(o.order_id)  AS delivered_orders,
    ROUND(AVG(DATEDIFF(DAY,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    )), 1)             AS avg_delivery_days,
    MIN(DATEDIFF(DAY,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    ))                 AS min_delivery_days,
    MAX(DATEDIFF(DAY,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    ))                 AS max_delivery_days
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days ASC;
 