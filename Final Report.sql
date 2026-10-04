
 
USE olist_store;
GO
 
-- --------------------------------------------------------------
-- Q12.01  Overall Business KPI Summary
-- --------------------------------------------------------------
SELECT
    (SELECT COUNT(DISTINCT order_id)
     FROM   olist_orders_dataset)                                AS total_orders,
    (SELECT COUNT(DISTINCT customer_id)
     FROM   olist_orders_dataset)                                AS total_customers,
    (SELECT ROUND(SUM(payment_value), 2)
     FROM   olist_order_payments_dataset)                        AS total_revenue,
    (SELECT ROUND(AVG(rev), 2)
     FROM  (SELECT order_id, SUM(payment_value) AS rev
            FROM   olist_order_payments_dataset
            GROUP  BY order_id) r)                              AS avg_order_value,
    (SELECT COUNT(DISTINCT seller_id)
     FROM   olist_order_items_dataset)                          AS active_sellers,
    (SELECT COUNT(DISTINCT product_id)
     FROM   olist_order_items_dataset)                          AS products_sold;
GO
 
-- --------------------------------------------------------------
-- Q12.02  Revenue & Order Count by Order Status
-- --------------------------------------------------------------
WITH order_rev AS (
    SELECT order_id, SUM(payment_value) AS revenue
    FROM   olist_order_payments_dataset
    GROUP  BY order_id
)
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id)      AS order_count,
    ROUND(SUM(r.revenue), 2)        AS total_revenue,
    ROUND(AVG(r.revenue), 2)        AS avg_order_value
FROM olist_orders_dataset  o
JOIN order_rev             r ON o.order_id = r.order_id
GROUP  BY o.order_status
ORDER  BY total_revenue DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.03  Total Revenue from Delivered Orders Only
-- --------------------------------------------------------------
WITH order_rev AS (
    SELECT order_id, SUM(payment_value) AS revenue
    FROM   olist_order_payments_dataset
    GROUP  BY order_id
)
SELECT
    COUNT(DISTINCT o.order_id)      AS delivered_orders,
    ROUND(SUM(r.revenue), 2)        AS delivered_revenue,
    ROUND(AVG(r.revenue), 2)        AS avg_delivered_value
FROM olist_orders_dataset  o
JOIN order_rev             r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';
GO
 
-- --------------------------------------------------------------
-- Q12.04  Revenue Split by Payment Type (with % share)
-- --------------------------------------------------------------
SELECT
    payment_type,
    COUNT(DISTINCT order_id)                            AS order_count,
    ROUND(SUM(payment_value), 2)                        AS total_revenue,
    ROUND(AVG(payment_value), 2)                        AS avg_payment,
    ROUND(SUM(payment_value) * 100.0
          / SUM(SUM(payment_value)) OVER (), 2)         AS revenue_pct
FROM olist_order_payments_dataset
GROUP  BY payment_type
ORDER  BY total_revenue DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.05  Average Order Value (AOV) by Year
-- --------------------------------------------------------------
WITH order_rev AS (
    SELECT order_id, SUM(payment_value) AS revenue
    FROM   olist_order_payments_dataset
    GROUP  BY order_id
)
SELECT
    YEAR(o.order_purchase_timestamp)    AS order_year,
    COUNT(DISTINCT o.order_id)          AS total_orders,
    ROUND(SUM(r.revenue), 2)            AS total_revenue,
    ROUND(AVG(r.revenue), 2)            AS avg_order_value
FROM olist_orders_dataset  o
JOIN order_rev             r ON o.order_id = r.order_id
GROUP  BY YEAR(o.order_purchase_timestamp)
ORDER  BY order_year;
GO
 
-- --------------------------------------------------------------
-- Q12.06  Product Revenue vs Freight Revenue (Gross Split)
-- --------------------------------------------------------------
SELECT
    ROUND(SUM(price), 2)                                        AS product_revenue,
    ROUND(SUM(freight_value), 2)                                AS freight_revenue,
    ROUND(SUM(price + freight_value), 2)                        AS gross_revenue,
    ROUND(SUM(freight_value) * 100.0
          / NULLIF(SUM(price + freight_value), 0), 2)           AS freight_pct
FROM olist_order_items_dataset;
GO
 
-- --------------------------------------------------------------
-- Q12.07  Average Delivery Time (Purchase to Delivery in Days)
-- --------------------------------------------------------------
SELECT
    ROUND(AVG(CAST(DATEDIFF(DAY,
          order_purchase_timestamp,
          order_delivered_customer_date) AS FLOAT)), 1)         AS avg_delivery_days,
    MIN(DATEDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date))                          AS min_days,
    MAX(DATEDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date))                          AS max_days
FROM olist_orders_dataset
WHERE order_status                  = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp      IS NOT NULL;
GO
 
-- --------------------------------------------------------------
-- Q12.08  On-Time Delivery Rate
--         Actual delivery date vs estimated delivery date
-- --------------------------------------------------------------
SELECT
    COUNT(*)                                                    AS delivered_orders,
    SUM(CASE WHEN order_delivered_customer_date
                  <= order_estimated_delivery_date
             THEN 1 ELSE 0 END)                                AS on_time_count,
    SUM(CASE WHEN order_delivered_customer_date
                  >  order_estimated_delivery_date
             THEN 1 ELSE 0 END)                                AS late_count,
    ROUND(SUM(CASE WHEN order_delivered_customer_date
                        <= order_estimated_delivery_date
                   THEN 1.0 ELSE 0 END)
          * 100.0 / COUNT(*), 2)                               AS on_time_rate_pct
FROM olist_orders_dataset
WHERE order_status                  = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
GO
 
-- --------------------------------------------------------------
-- Q12.09  Top 10 Product Categories by Revenue
-- --------------------------------------------------------------
SELECT TOP 10
    ISNULL(p.product_category_name, 'Unknown')  AS category,
    COUNT(oi.order_item_id)                      AS units_sold,
    ROUND(SUM(oi.price), 2)                      AS total_revenue,
    ROUND(AVG(oi.price), 2)                      AS avg_price
FROM olist_order_items_dataset   oi
JOIN olist_products_dataset      p  ON oi.product_id = p.product_id
GROUP  BY p.product_category_name
ORDER  BY total_revenue DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.10  Top 10 Product Categories by Units Sold
-- --------------------------------------------------------------
SELECT TOP 10
    ISNULL(p.product_category_name, 'Unknown')  AS category,
    COUNT(oi.order_item_id)                      AS units_sold,
    ROUND(SUM(oi.price), 2)                      AS total_revenue
FROM olist_order_items_dataset   oi
JOIN olist_products_dataset      p  ON oi.product_id = p.product_id
GROUP  BY p.product_category_name
ORDER  BY units_sold DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.11  Top 10 Sellers by Total Revenue
-- --------------------------------------------------------------
SELECT TOP 10
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)     AS orders_fulfilled,
    COUNT(oi.order_item_id)         AS items_sold,
    ROUND(SUM(oi.price), 2)         AS total_revenue
FROM olist_order_items_dataset   oi
JOIN olist_sellers_dataset       s  ON oi.seller_id = s.seller_id
GROUP  BY oi.seller_id, s.seller_city, s.seller_state
ORDER  BY total_revenue DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.12  Top 10 Sellers by Order Volume
-- --------------------------------------------------------------
SELECT TOP 10
    oi.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)     AS total_orders,
    COUNT(oi.order_item_id)         AS items_sold,
    ROUND(SUM(oi.price), 2)         AS total_revenue
FROM olist_order_items_dataset   oi
JOIN olist_sellers_dataset       s  ON oi.seller_id = s.seller_id
GROUP  BY oi.seller_id, s.seller_state
ORDER  BY total_orders DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.13  Seller Performance by State
-- --------------------------------------------------------------
SELECT
    s.seller_state,
    COUNT(DISTINCT s.seller_id)     AS total_sellers,
    COUNT(DISTINCT oi.order_id)     AS total_orders,
    COUNT(oi.order_item_id)         AS items_sold,
    ROUND(SUM(oi.price), 2)         AS total_revenue,
    ROUND(AVG(oi.price), 2)         AS avg_item_price
FROM olist_sellers_dataset        s
JOIN olist_order_items_dataset    oi ON s.seller_id = oi.seller_id
GROUP  BY s.seller_state
ORDER  BY total_revenue DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.14  Average Product Price by Category  (Top 15, min 100 items)
-- --------------------------------------------------------------
SELECT TOP 15
    ISNULL(p.product_category_name, 'Unknown')  AS category,
    COUNT(oi.order_item_id)                      AS items_sold,
    ROUND(AVG(oi.price), 2)                      AS avg_price,
    ROUND(MIN(oi.price), 2)                      AS min_price,
    ROUND(MAX(oi.price), 2)                      AS max_price
FROM olist_order_items_dataset   oi
JOIN olist_products_dataset      p  ON oi.product_id = p.product_id
GROUP  BY p.product_category_name
HAVING COUNT(oi.order_item_id) >= 100
ORDER  BY avg_price DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.15  Top 5 Highest Average Freight Cost Categories
-- --------------------------------------------------------------
SELECT TOP 5
    ISNULL(p.product_category_name, 'Unknown')  AS category,
    COUNT(oi.order_item_id)                      AS items_shipped,
    ROUND(AVG(oi.freight_value), 2)              AS avg_freight,
    ROUND(SUM(oi.freight_value), 2)              AS total_freight
FROM olist_order_items_dataset   oi
JOIN olist_products_dataset      p  ON oi.product_id = p.product_id
GROUP  BY p.product_category_name
HAVING COUNT(oi.order_item_id) >= 50
ORDER  BY avg_freight DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.16  Seller Revenue Tier Classification
--         Gold (50k+) | Silver (10k-50k) | Bronze (1k-10k) | Starter
-- --------------------------------------------------------------
WITH seller_rev AS (
    SELECT seller_id,
           ROUND(SUM(price), 2) AS total_revenue
    FROM   olist_order_items_dataset
    GROUP  BY seller_id
)
SELECT
    CASE
        WHEN total_revenue >= 50000 THEN 'Gold   (50k+)'
        WHEN total_revenue >= 10000 THEN 'Silver (10k-50k)'
        WHEN total_revenue >= 1000  THEN 'Bronze (1k-10k)'
        ELSE                             'Starter (<1k)'
    END                                 AS tier,
    COUNT(*)                            AS seller_count,
    ROUND(SUM(total_revenue), 2)        AS tier_revenue,
    ROUND(AVG(total_revenue), 2)        AS avg_seller_revenue
FROM seller_rev
GROUP  BY
    CASE
        WHEN total_revenue >= 50000 THEN 'Gold   (50k+)'
        WHEN total_revenue >= 10000 THEN 'Silver (10k-50k)'
        WHEN total_revenue >= 1000  THEN 'Bronze (1k-10k)'
        ELSE                             'Starter (<1k)'
    END
ORDER  BY tier_revenue DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.17  Product Category Revenue Share % (Top 10 of All)
-- --------------------------------------------------------------
WITH cat_rev AS (
    SELECT
        ISNULL(p.product_category_name, 'Unknown')  AS category,
        ROUND(SUM(oi.price), 2)                      AS cat_revenue
    FROM olist_order_items_dataset   oi
    JOIN olist_products_dataset      p  ON oi.product_id = p.product_id
    GROUP  BY p.product_category_name
)
SELECT TOP 10
    category,
    cat_revenue,
    ROUND(cat_revenue * 100.0
          / SUM(cat_revenue) OVER (), 2)             AS revenue_share_pct,
    RANK() OVER (ORDER BY cat_revenue DESC)          AS revenue_rank
FROM cat_rev
ORDER  BY cat_revenue DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.18  Customer Count & Orders by State
-- --------------------------------------------------------------
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id)                        AS unique_customers,
    COUNT(DISTINCT o.order_id)                                  AS total_orders,
    ROUND(COUNT(DISTINCT o.order_id) * 1.0
          / NULLIF(COUNT(DISTINCT c.customer_unique_id), 0), 2) AS orders_per_customer
FROM olist_customers_dataset   c
JOIN olist_orders_dataset      o ON c.customer_id = o.customer_id
GROUP  BY c.customer_state
ORDER  BY unique_customers DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.19  Repeat vs One-Time Customers
-- --------------------------------------------------------------
WITH cust_orders AS (
    SELECT c.customer_unique_id,
           COUNT(o.order_id) AS order_count
    FROM   olist_customers_dataset  c
    JOIN   olist_orders_dataset     o ON c.customer_id = o.customer_id
    GROUP  BY c.customer_unique_id
)
SELECT
    CASE WHEN order_count > 1 THEN 'Repeat Customer'
         ELSE                      'One-Time Customer'
    END                                                     AS customer_type,
    COUNT(*)                                                AS customer_count,
    ROUND(COUNT(*) * 100.0
          / SUM(COUNT(*)) OVER (), 2)                       AS pct_of_total
FROM cust_orders
GROUP  BY CASE WHEN order_count > 1 THEN 'Repeat Customer'
               ELSE                      'One-Time Customer' END;
GO
 
-- --------------------------------------------------------------
-- Q12.20  Top 10 Customer Cities by Order Volume
-- --------------------------------------------------------------
SELECT TOP 10
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id)    AS unique_customers,
    COUNT(DISTINCT o.order_id)              AS total_orders
FROM olist_customers_dataset   c
JOIN olist_orders_dataset      o ON c.customer_id = o.customer_id
GROUP  BY c.customer_city, c.customer_state
ORDER  BY unique_customers DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.21  Customer Spend Segmentation (Low / Mid / High Value)
-- --------------------------------------------------------------
WITH cust_spend AS (
    SELECT
        c.customer_unique_id,
        SUM(op.payment_value)   AS total_spend
    FROM olist_customers_dataset       c
    JOIN olist_orders_dataset          o  ON c.customer_id = o.customer_id
    JOIN olist_order_payments_dataset  op ON o.order_id    = op.order_id
    GROUP  BY c.customer_unique_id
)
SELECT
    CASE
        WHEN total_spend >= 1000 THEN 'High Value  (BRL 1000+)'
        WHEN total_spend >= 300  THEN 'Mid Value   (BRL 300-999)'
        ELSE                          'Low Value   (BRL < 300)'
    END                             AS spend_segment,
    COUNT(*)                        AS customer_count,
    ROUND(AVG(total_spend), 2)      AS avg_spend,
    ROUND(SUM(total_spend), 2)      AS segment_revenue
FROM cust_spend
GROUP  BY
    CASE
        WHEN total_spend >= 1000 THEN 'High Value  (BRL 1000+)'
        WHEN total_spend >= 300  THEN 'Mid Value   (BRL 300-999)'
        ELSE                          'Low Value   (BRL < 300)'
    END
ORDER  BY avg_spend DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.22  Average, Min, Max Items per Order
-- --------------------------------------------------------------
SELECT
    ROUND(AVG(CAST(items_per_order AS FLOAT)), 2)   AS avg_items_per_order,
    MIN(items_per_order)                             AS min_items,
    MAX(items_per_order)                             AS max_items
FROM (
    SELECT order_id,
           COUNT(order_item_id) AS items_per_order
    FROM   olist_order_items_dataset
    GROUP  BY order_id
) sub;
GO
 
-- --------------------------------------------------------------
-- Q12.23  Credit Card Installment Preference Breakdown
-- --------------------------------------------------------------
SELECT
    CASE
        WHEN payment_installments = 1   THEN '01 - Single Payment'
        WHEN payment_installments <= 3  THEN '02-03 Installments'
        WHEN payment_installments <= 6  THEN '04-06 Installments'
        WHEN payment_installments <= 12 THEN '07-12 Installments'
        ELSE                                 '13+ Installments'
    END                                 AS installment_group,
    COUNT(*)                            AS transactions,
    ROUND(SUM(payment_value), 2)        AS total_value,
    ROUND(AVG(payment_value), 2)        AS avg_value
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card'
GROUP  BY
    CASE
        WHEN payment_installments = 1   THEN '01 - Single Payment'
        WHEN payment_installments <= 3  THEN '02-03 Installments'
        WHEN payment_installments <= 6  THEN '04-06 Installments'
        WHEN payment_installments <= 12 THEN '07-12 Installments'
        ELSE                                 '13+ Installments'
    END
ORDER  BY transactions DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.24  Total Customer Revenue by State
-- --------------------------------------------------------------
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id)    AS unique_customers,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    ROUND(SUM(op.payment_value), 2)         AS total_revenue,
    ROUND(AVG(op.payment_value), 2)         AS avg_payment
FROM olist_customers_dataset       c
JOIN olist_orders_dataset          o  ON c.customer_id = o.customer_id
JOIN olist_order_payments_dataset  op ON o.order_id    = op.order_id
GROUP  BY c.customer_state
ORDER  BY total_revenue DESC;
GO
 
-- --------------------------------------------------------------
-- Q12.25  Top 10 High-Value Customers by Total Spend
-- --------------------------------------------------------------
SELECT TOP 10
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    ROUND(SUM(op.payment_value), 2)         AS total_spend
FROM olist_customers_dataset       c
JOIN olist_orders_dataset          o  ON c.customer_id = o.customer_id
JOIN olist_order_payments_dataset  op ON o.order_id    = op.order_id
GROUP  BY c.customer_unique_id, c.customer_city, c.customer_state
ORDER  BY total_spend DESC;
GO

-- --------------------------------------------------------------
-- Q12.26  Monthly Revenue Trend  (Delivered Orders Only)
-- --------------------------------------------------------------
 SELECT
    LEFT(o.order_purchase_timestamp, 7) AS year_month,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(op.payment_value), 2) AS monthly_revenue
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset op
    ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY LEFT(o.order_purchase_timestamp, 7)
ORDER BY year_month;
-- --------------------------------------------------------------
-- Q12.27  Monthly Order Volume Trend  (All Statuses Breakdown)
-- --------------------------------------------------------------
 SELECT
    FORMAT(TRY_CONVERT(datetime, order_purchase_timestamp), 'yyyy-MM') AS year_month,
    COUNT(order_id) AS total_orders,
    SUM(IIF(order_status = 'delivered', 1, 0)) AS delivered,
    SUM(IIF(order_status = 'canceled', 1, 0)) AS canceled,
    SUM(IIF(order_status = 'shipped', 1, 0)) AS shipped,
    SUM(IIF(order_status = 'processing', 1, 0)) AS processing
FROM olist_orders_dataset
WHERE TRY_CONVERT(datetime, order_purchase_timestamp) IS NOT NULL
GROUP BY FORMAT(TRY_CONVERT(datetime, order_purchase_timestamp), 'yyyy-MM')
ORDER BY year_month;

-- --------------------------------------------------------------
-- Q12.28  Month-over-Month Revenue Growth (%)
--         Uses LAG() to compare current vs prior month
-- --------------------------------------------------------------
WITH monthly_rev AS (
    SELECT
        LEFT(o.order_purchase_timestamp, 7) AS yr_mo,
        ROUND(SUM(op.payment_value), 2) AS revenue
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset op
        ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY LEFT(o.order_purchase_timestamp, 7)
),
x AS (
    SELECT *, LAG(revenue) OVER (ORDER BY yr_mo) AS prev_month
    FROM monthly_rev
)
SELECT
    yr_mo,
    revenue,
    prev_month,
    ROUND((revenue - prev_month) * 100.0 / NULLIF(prev_month, 0), 2) AS mom_growth_pct
FROM x
ORDER BY yr_mo;
GO
-- --------------------------------------------------------------
-- Q12.29  Quarterly Revenue Summary
-- --------------------------------------------------------------
SELECT
    YEAR(o.order_purchase_timestamp) AS yr,
    CONCAT('Q', DATEPART(QUARTER, o.order_purchase_timestamp)) AS quarter,
    COUNT(*) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS quarterly_revenue
FROM olist_orders_dataset o
JOIN (
    SELECT order_id, SUM(payment_value) AS payment_value
    FROM olist_order_payments_dataset
    GROUP BY order_id
) p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY YEAR(o.order_purchase_timestamp),
         DATEPART(QUARTER, o.order_purchase_timestamp)
ORDER BY yr, quarter;

-- --------------------------------------------------------------
-- Q12.30  Peak Sales Month  (Highest Revenue Month Ever)
-- --------------------------------------------------------------
 SELECT TOP 1
    CONVERT(char(7), TRY_CONVERT(datetime, o.order_purchase_timestamp), 120) AS peak_month,
    COUNT(DISTINCT o.order_id) AS peak_orders,
    ROUND(SUM(op.payment_value), 2) AS peak_revenue
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset op
    ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY CONVERT(char(7), TRY_CONVERT(datetime, o.order_purchase_timestamp), 120)
ORDER BY peak_revenue DESC;
-- --------------------------------------------------------------
-- Q12.31  Executive Dashboard Summary  
-- --------------------------------------------------------------
SELECT
    (SELECT COUNT(DISTINCT order_id)
     FROM   olist_orders_dataset)                                AS total_orders,
    (SELECT COUNT(DISTINCT order_id)
     FROM   olist_orders_dataset
     WHERE  order_status = 'delivered')                          AS delivered_orders,
    (SELECT COUNT(DISTINCT customer_unique_id)
     FROM   olist_customers_dataset)                             AS unique_customers,
    (SELECT ROUND(SUM(payment_value), 2)
     FROM   olist_order_payments_dataset)                        AS total_revenue,
    (SELECT COUNT(DISTINCT product_id)
     FROM   olist_products_dataset)                              AS total_products,
    (SELECT COUNT(DISTINCT product_category_name)
     FROM   olist_products_dataset)                              AS total_categories,
    (SELECT COUNT(DISTINCT seller_id)
     FROM   olist_sellers_dataset)                               AS total_sellers,
    (SELECT COUNT(DISTINCT seller_state)
     FROM   olist_sellers_dataset)                               AS seller_states;
GO
 
-- --------------------------------------------------------------
-- Q12.32  Business Performance Scorecard
--         Delivery rate | Cancellation rate | Avg delivery days
-- --------------------------------------------------------------
SELECT
    COUNT(order_id)                                              AS total_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN order_status = 'canceled'  THEN 1 ELSE 0 END) AS canceled,
    SUM(CASE WHEN order_status = 'shipped'   THEN 1 ELSE 0 END) AS shipped,
    ROUND(SUM(CASE WHEN order_status = 'delivered'
                   THEN 1.0 ELSE 0 END)
          * 100.0 / COUNT(order_id), 2)                         AS delivery_rate_pct,
    ROUND(SUM(CASE WHEN order_status = 'canceled'
                   THEN 1.0 ELSE 0 END)
          * 100.0 / COUNT(order_id), 2)                         AS cancellation_rate_pct,
    ROUND(AVG(CAST(DATEDIFF(DAY,
          order_purchase_timestamp,
          order_delivered_customer_date) AS FLOAT)), 1)         AS avg_delivery_days
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL;
GO
 
-- --------------------------------------------------------------
-- Q12.33    All 6 Tables at a Glance
--         10 key metrics from every table in one result row
-- --------------------------------------------------------------
SELECT
    (SELECT COUNT(DISTINCT customer_unique_id)
     FROM olist_customers_dataset)                               AS unique_customers,
    (SELECT COUNT(DISTINCT customer_state)
     FROM olist_customers_dataset)                               AS customer_states,
    (SELECT COUNT(*)
     FROM olist_orders_dataset)                                  AS total_orders,
    (SELECT COUNT(*)
     FROM olist_orders_dataset
     WHERE  order_status = 'delivered')                          AS delivered_orders,
    (SELECT COUNT(*)
     FROM olist_order_items_dataset)                             AS total_items_sold,
    (SELECT ROUND(SUM(payment_value), 2)
     FROM olist_order_payments_dataset)                          AS total_revenue,
    (SELECT COUNT(DISTINCT product_id)
     FROM olist_products_dataset)                                AS total_products,
    (SELECT COUNT(DISTINCT product_category_name)
     FROM olist_products_dataset)                                AS categories,
    (SELECT COUNT(DISTINCT seller_id)
     FROM olist_sellers_dataset)                                 AS total_sellers,
    (SELECT COUNT(DISTINCT seller_state)
     FROM olist_sellers_dataset)                                 AS seller_states;
GO
