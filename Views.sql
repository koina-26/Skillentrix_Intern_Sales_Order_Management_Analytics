USE olist_store;
GO
 
-- --------------------------------------------------------------------
-- Q8.01  vw_monthly_revenue
-- --------------------------------------------------------------------
DROP VIEW IF EXISTS vw_monthly_revenue;
GO
 
CREATE VIEW vw_monthly_revenue AS
SELECT
    YEAR(o.order_purchase_timestamp)            AS order_year,
    MONTH(o.order_purchase_timestamp)           AS order_month,
    DATENAME(MONTH, o.order_purchase_timestamp) AS month_name,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    ROUND(SUM(oi.price), 2)                     AS product_revenue,
    ROUND(SUM(oi.freight_value), 2)             AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2)  AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value), 2)  AS avg_order_value,
    ROUND(MIN(oi.price + oi.freight_value), 2)  AS min_order_value,
    ROUND(MAX(oi.price + oi.freight_value), 2)  AS max_order_value
FROM  olist_orders_dataset         o
JOIN  olist_order_items_dataset    oi  ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp),
    DATENAME(MONTH, o.order_purchase_timestamp);
GO
 
-- Test Q8.01
SELECT * FROM vw_monthly_revenue ORDER BY order_year, order_month;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.02  vw_customer_order_history
-- --------------------------------------------------------------------
DROP VIEW IF EXISTS vw_customer_order_history;
GO
 
CREATE VIEW vw_customer_order_history AS
SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    DATEDIFF(DAY,
             o.order_purchase_timestamp,
             o.order_delivered_customer_date)        AS delivery_days,
    COUNT(oi.order_item_id)                          AS total_items,
    ROUND(SUM(oi.price), 2)                          AS items_subtotal,
    ROUND(SUM(oi.freight_value), 2)                  AS freight_total,
    ROUND(SUM(op.payment_value), 2)                  AS total_paid,
    MAX(op.payment_type)                             AS payment_type,
    MAX(op.payment_installments)                     AS max_installments
FROM  olist_customers_dataset         c
JOIN  olist_orders_dataset            o   ON c.customer_id  = o.customer_id
JOIN  olist_order_items_dataset       oi  ON o.order_id     = oi.order_id
JOIN  olist_order_payments_dataset    op  ON o.order_id     = op.order_id
GROUP BY
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date;
GO
 
-- Test Q8.02
SELECT TOP 10 *
FROM   vw_customer_order_history
ORDER  BY order_purchase_timestamp DESC;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.03  vw_seller_performance
-- --------------------------------------------------------------------
DROP VIEW IF EXISTS vw_seller_performance;
GO
 
CREATE VIEW vw_seller_performance AS
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)                   AS total_orders,
    COUNT(oi.order_item_id)                       AS total_items_sold,
    ROUND(SUM(oi.price), 2)                       AS total_product_revenue,
    ROUND(SUM(oi.freight_value), 2)               AS total_freight,
    ROUND(SUM(oi.price + oi.freight_value), 2)    AS gross_revenue,
    ROUND(AVG(oi.price), 2)                       AS avg_item_price
FROM  olist_sellers_dataset          s
JOIN  olist_order_items_dataset      oi ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state;
GO
 
-- Test Q8.03
SELECT TOP 10 * FROM vw_seller_performance ORDER BY gross_revenue DESC;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.04  vw_delivery_performance
-- --------------------------------------------------------------------
DROP VIEW IF EXISTS vw_delivery_performance;
GO
 
CREATE VIEW vw_delivery_performance AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_estimated_delivery_date,
    o.order_delivered_customer_date,
    DATEDIFF(DAY,
             o.order_purchase_timestamp,
             o.order_delivered_customer_date)       AS actual_delivery_days,
    DATEDIFF(DAY,
             o.order_purchase_timestamp,
             o.order_estimated_delivery_date)       AS estimated_delivery_days,
    DATEDIFF(DAY,
             o.order_estimated_delivery_date,
             o.order_delivered_customer_date)       AS delay_days,
    CASE
        WHEN o.order_delivered_customer_date IS NULL              THEN 'Pending'
        WHEN o.order_delivered_customer_date
           <= o.order_estimated_delivery_date                     THEN 'On Time'
        ELSE                                                           'Late'
    END AS delivery_status
FROM olist_orders_dataset o;
GO
 
-- Test Q8.04 -- top 10 most delayed orders
SELECT TOP 10 *
FROM   vw_delivery_performance
WHERE  delivery_status = 'Late'
ORDER  BY delay_days DESC;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.05  vw_top_products_by_category
-- --------------------------------------------------------------------
DROP VIEW IF EXISTS vw_top_products_by_category;
GO
 
CREATE VIEW vw_top_products_by_category AS
SELECT
    p.product_id,
    ISNULL(p.product_category_name, 'uncategorized') AS product_category_name,
    COUNT(DISTINCT oi.order_id)                       AS total_orders,
    COUNT(oi.order_item_id)                           AS units_sold,
    ROUND(SUM(oi.price), 2)                           AS total_revenue,
    ROUND(AVG(oi.price), 2)                           AS avg_price,
    RANK() OVER (
        PARTITION BY ISNULL(p.product_category_name, 'uncategorized')
        ORDER BY SUM(oi.price) DESC
    )                                                  AS revenue_rank_in_category
FROM  olist_products_dataset         p
JOIN  olist_order_items_dataset      oi ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_category_name;
GO
 
-- Test Q8.05 -- #1 product per category, best categories first
SELECT *
FROM   vw_top_products_by_category
WHERE  revenue_rank_in_category = 1
ORDER  BY total_revenue DESC;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.06  vw_high_value_orders
-- --------------------------------------------------------------------
DROP VIEW IF EXISTS vw_high_value_orders;
GO
 
CREATE VIEW vw_high_value_orders AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    COUNT(oi.order_item_id)         AS total_items,
    ROUND(SUM(oi.price), 2)         AS product_subtotal,
    ROUND(SUM(oi.freight_value), 2) AS freight_subtotal,
    ROUND(SUM(op.payment_value), 2) AS total_payment,
    MAX(op.payment_type)            AS payment_type,
    MAX(op.payment_installments)    AS installments,
    CASE
        WHEN SUM(op.payment_value) >= 500 THEN 'Premium'
        WHEN SUM(op.payment_value) >= 200 THEN 'High'
        WHEN SUM(op.payment_value) >= 100 THEN 'Medium'
        ELSE                                   'Standard'
    END AS order_value_tier
FROM  olist_orders_dataset             o
JOIN  olist_order_items_dataset        oi ON o.order_id = oi.order_id
JOIN  olist_order_payments_dataset     op ON o.order_id = op.order_id
GROUP BY
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp;
GO
 
-- Test Q8.06 -- top 20 Premium and High-value orders
SELECT TOP 20 *
FROM   vw_high_value_orders
WHERE  order_value_tier IN ('Premium', 'High')
ORDER  BY total_payment DESC;
GO
 
-- --------------------------------------------------------------------
-- Q8.07  Indexes on olist_customers_dataset
-- --------------------------------------------------------------------
 
-- Drop first (safe re-run)
DROP INDEX IF EXISTS idx_cust_unique_id   ON olist_customers_dataset;
DROP INDEX IF EXISTS idx_cust_state       ON olist_customers_dataset;
DROP INDEX IF EXISTS idx_cust_state_city  ON olist_customers_dataset;
GO
 
-- Index A : customer_unique_id -- used in WHERE and sp_customer_order_history
CREATE NONCLUSTERED INDEX idx_cust_unique_id
    ON olist_customers_dataset (customer_unique_id);
GO
 
-- Index B : customer_state -- speeds up WHERE customer_state = 'SP'
CREATE NONCLUSTERED INDEX idx_cust_state
    ON olist_customers_dataset (customer_state);
GO
 
-- Index C : Composite (state, city) -- two-level regional drill-down
CREATE NONCLUSTERED INDEX idx_cust_state_city
    ON olist_customers_dataset (customer_state, customer_city);
GO
 
 
-- --------------------------------------------------------------------
-- Q8.08  Indexes on olist_orders_dataset
-- --------------------------------------------------------------------
 
DROP INDEX IF EXISTS idx_ord_customer_id  ON olist_orders_dataset;
DROP INDEX IF EXISTS idx_ord_status       ON olist_orders_dataset;
DROP INDEX IF EXISTS idx_ord_purchase_ts  ON olist_orders_dataset;
DROP INDEX IF EXISTS idx_ord_status_ts    ON olist_orders_dataset;
GO
 
-- Index A : customer_id -- speeds up JOIN with olist_customers_dataset
CREATE NONCLUSTERED INDEX idx_ord_customer_id
    ON olist_orders_dataset (customer_id);
GO
 
-- Index B : order_status -- WHERE order_status = 'delivered' pattern
CREATE NONCLUSTERED INDEX idx_ord_status
    ON olist_orders_dataset (order_status);
GO
 
-- Index C : order_purchase_timestamp -- date-range and GROUP BY month/year
CREATE NONCLUSTERED INDEX idx_ord_purchase_ts
    ON olist_orders_dataset (order_purchase_timestamp);
GO
 
-- Index D : Composite covering index (status, timestamp)
--           INCLUDE avoids key lookups in delivery and MoM analytics
CREATE NONCLUSTERED INDEX idx_ord_status_ts
    ON olist_orders_dataset (order_status, order_purchase_timestamp)
    INCLUDE (customer_id,
             order_delivered_customer_date,
             order_estimated_delivery_date);
GO
 
 
-- --------------------------------------------------------------------
-- Q8.09  Indexes on olist_order_items_dataset
-- --------------------------------------------------------------------
 
DROP INDEX IF EXISTS idx_oi_order_id     ON olist_order_items_dataset;
DROP INDEX IF EXISTS idx_oi_product_id   ON olist_order_items_dataset;
DROP INDEX IF EXISTS idx_oi_seller_id    ON olist_order_items_dataset;
DROP INDEX IF EXISTS idx_oi_seller_prod  ON olist_order_items_dataset;
GO
 
-- Index A : order_id FK -- JOIN with olist_orders_dataset
CREATE NONCLUSTERED INDEX idx_oi_order_id
    ON olist_order_items_dataset (order_id);
GO
 
-- Index B : product_id FK -- JOIN with olist_products_dataset
CREATE NONCLUSTERED INDEX idx_oi_product_id
    ON olist_order_items_dataset (product_id);
GO
 
-- Index C : seller_id FK -- JOIN with olist_sellers_dataset
CREATE NONCLUSTERED INDEX idx_oi_seller_id
    ON olist_order_items_dataset (seller_id);
GO
 
-- Index D : Composite (seller_id, product_id) with INCLUDE
--           Covers seller-product revenue aggregations without key lookup
CREATE NONCLUSTERED INDEX idx_oi_seller_prod
    ON olist_order_items_dataset (seller_id, product_id)
    INCLUDE (order_id, price, freight_value, order_item_id);
GO
 
 
-- --------------------------------------------------------------------
-- Q8.10  Indexes on olist_order_payments_dataset
-- --------------------------------------------------------------------
 
DROP INDEX IF EXISTS idx_pay_order_id    ON olist_order_payments_dataset;
DROP INDEX IF EXISTS idx_pay_type        ON olist_order_payments_dataset;
DROP INDEX IF EXISTS idx_pay_type_value  ON olist_order_payments_dataset;
GO
 
-- Index A : order_id FK -- JOIN with olist_orders_dataset
CREATE NONCLUSTERED INDEX idx_pay_order_id
    ON olist_order_payments_dataset (order_id);
GO
 
-- Index B : payment_type -- WHERE payment_type = 'credit_card'
CREATE NONCLUSTERED INDEX idx_pay_type
    ON olist_order_payments_dataset (payment_type);
GO
 
-- Index C : Composite (type, value) -- payment-method revenue analytics
CREATE NONCLUSTERED INDEX idx_pay_type_value
    ON olist_order_payments_dataset (payment_type, payment_value);
GO
 
 
-- --------------------------------------------------------------------
-- Q8.11  Indexes on olist_products_dataset
-- --------------------------------------------------------------------
 
DROP INDEX IF EXISTS idx_prod_category ON olist_products_dataset;
GO
 
CREATE NONCLUSTERED INDEX idx_prod_category
    ON olist_products_dataset (product_category_name);
GO
 
 
-- --------------------------------------------------------------------
-- Q8.12  Indexes on olist_sellers_dataset
-- --------------------------------------------------------------------
 
DROP INDEX IF EXISTS idx_sel_state       ON olist_sellers_dataset;
DROP INDEX IF EXISTS idx_sel_state_city  ON olist_sellers_dataset;
GO
 
-- Index A : seller_state -- WHERE seller_state = 'SP'
CREATE NONCLUSTERED INDEX idx_sel_state
    ON olist_sellers_dataset (seller_state);
GO
 
-- Index B : Composite (state, city) -- regional two-level drill-down
CREATE NONCLUSTERED INDEX idx_sel_state_city
    ON olist_sellers_dataset (seller_state, seller_city);
GO
 
 
-- --------------------------------------------------------------------
-- Q8.13  Advanced Cross-Table Composite Covering Indexes
-- --------------------------------------------------------------------
 
-- Index A : Orders -- covers customer + status + timestamp for MoM,
--           customer segmentation, and delivery analytics
DROP INDEX IF EXISTS idx_ord_cust_status_full ON olist_orders_dataset;
GO
CREATE NONCLUSTERED INDEX idx_ord_cust_status_full
    ON olist_orders_dataset (customer_id, order_status, order_purchase_timestamp)
    INCLUDE (order_delivered_customer_date,
             order_estimated_delivery_date,
             order_approved_at);
GO
 
-- Index B : Order Items -- covers order revenue calculation
--           Avoids key lookup when fetching price & freight per order
DROP INDEX IF EXISTS idx_oi_ord_price_cover ON olist_order_items_dataset;
GO
CREATE NONCLUSTERED INDEX idx_oi_ord_price_cover
    ON olist_order_items_dataset (order_id, seller_id)
    INCLUDE (product_id, price, freight_value, order_item_id);
GO
 
-- Index C : Payments -- covers payment aggregation per order
--           Used by views and procedures that SUM(payment_value)
DROP INDEX IF EXISTS idx_pay_ord_val_cover ON olist_order_payments_dataset;
GO
CREATE NONCLUSTERED INDEX idx_pay_ord_val_cover
    ON olist_order_payments_dataset (order_id, payment_type)
    INCLUDE (payment_value, payment_installments);
GO
 
-- --------------------------------------------------------------------
-- Q8.14  sp_revenue_by_year
-- --------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_revenue_by_year;
GO
 
CREATE PROCEDURE sp_revenue_by_year
    @year INT
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT
        YEAR(o.order_purchase_timestamp)            AS order_year,
        MONTH(o.order_purchase_timestamp)           AS order_month,
        DATENAME(MONTH, o.order_purchase_timestamp) AS month_name,
        COUNT(DISTINCT o.order_id)                  AS total_orders,
        ROUND(SUM(oi.price), 2)                     AS product_revenue,
        ROUND(SUM(oi.freight_value), 2)             AS freight_revenue,
        ROUND(SUM(oi.price + oi.freight_value), 2)  AS total_revenue,
        ROUND(AVG(oi.price + oi.freight_value), 2)  AS avg_order_value,
        ROUND(MIN(oi.price + oi.freight_value), 2)  AS min_order_value,
        ROUND(MAX(oi.price + oi.freight_value), 2)  AS max_order_value
    FROM  olist_orders_dataset         o
    JOIN  olist_order_items_dataset    oi ON o.order_id = oi.order_id
    WHERE
        o.order_status                       = 'delivered'
        AND YEAR(o.order_purchase_timestamp) = @year
    GROUP BY
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp),
        DATENAME(MONTH, o.order_purchase_timestamp)
    ORDER BY
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp);
END;
GO
 
-- Test Q8.14
EXEC sp_revenue_by_year @year = 2017;
GO
EXEC sp_revenue_by_year @year = 2018;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.15  sp_top_sellers_by_state
-- --------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_top_sellers_by_state;
GO
 
CREATE PROCEDURE sp_top_sellers_by_state
    @state  CHAR(2),
    @top_n  INT = 10
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT TOP (@top_n)
        s.seller_id,
        s.seller_city,
        s.seller_state,
        COUNT(DISTINCT oi.order_id)                 AS total_orders,
        COUNT(oi.order_item_id)                     AS total_items_sold,
        ROUND(SUM(oi.price), 2)                     AS total_revenue,
        ROUND(AVG(oi.price), 2)                     AS avg_item_price,
        ROUND(SUM(oi.freight_value), 2)             AS total_freight,
        RANK() OVER (ORDER BY SUM(oi.price) DESC)   AS revenue_rank
    FROM  olist_sellers_dataset          s
    JOIN  olist_order_items_dataset      oi ON s.seller_id  = oi.seller_id
    JOIN  olist_orders_dataset           o  ON oi.order_id  = o.order_id
    WHERE
        s.seller_state     = @state
        AND o.order_status = 'delivered'
    GROUP BY
        s.seller_id,
        s.seller_city,
        s.seller_state
    ORDER BY total_revenue DESC;
END;
GO
 
-- Test Q8.15
EXEC sp_top_sellers_by_state @state = 'SP', @top_n = 5;
GO
EXEC sp_top_sellers_by_state @state = 'RJ';           -- default top 10
GO
EXEC sp_top_sellers_by_state @state = 'MG', @top_n = 3;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.16  sp_customer_order_history
-- --------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_customer_order_history;
GO
 
CREATE PROCEDURE sp_customer_order_history
    @customer_unique_id VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        DATEDIFF(DAY,
                 o.order_purchase_timestamp,
                 o.order_delivered_customer_date)    AS delivery_days,
        COUNT(oi.order_item_id)                      AS total_items,
        ROUND(SUM(oi.price), 2)                      AS items_subtotal,
        ROUND(SUM(oi.freight_value), 2)              AS freight_total,
        ROUND(SUM(op.payment_value), 2)              AS total_paid,
        MAX(op.payment_type)                         AS payment_type,
        MAX(op.payment_installments)                 AS installments,
        CASE
            WHEN o.order_delivered_customer_date IS NULL THEN 'Pending'
            WHEN o.order_delivered_customer_date
               <= o.order_estimated_delivery_date         THEN 'On Time'
            ELSE                                               'Late'
        END AS delivery_flag
    FROM  olist_customers_dataset         c
    JOIN  olist_orders_dataset            o   ON c.customer_id  = o.customer_id
    JOIN  olist_order_items_dataset       oi  ON o.order_id     = oi.order_id
    JOIN  olist_order_payments_dataset    op  ON o.order_id     = op.order_id
    WHERE c.customer_unique_id = @customer_unique_id
    GROUP BY
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    ORDER BY o.order_purchase_timestamp;
END;
GO
 
-- Test Q8.16
-- Replace the ID below with a real value from your data:
-- SELECT TOP 5 customer_unique_id FROM olist_customers_dataset;
EXEC sp_customer_order_history
    @customer_unique_id = '8d50f5eadf50201ccdcedfb9e2ac8455';
GO
 
-- --------------------------------------------------------------------
-- Q8.17  sp_delivery_report_by_status
-- --------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_delivery_report_by_status;
GO
 
CREATE PROCEDURE sp_delivery_report_by_status
    @status VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT
        o.order_status,
        COUNT(o.order_id)                                               AS total_orders,
        ROUND(AVG(CAST(DATEDIFF(DAY,
              o.order_purchase_timestamp,
              o.order_delivered_customer_date) AS FLOAT)), 1)           AS avg_delivery_days,
        ROUND(AVG(CAST(DATEDIFF(DAY,
              o.order_purchase_timestamp,
              o.order_estimated_delivery_date) AS FLOAT)), 1)           AS avg_estimated_days,
        SUM(CASE
                WHEN o.order_delivered_customer_date
                   > o.order_estimated_delivery_date THEN 1 ELSE 0
            END)                                                        AS late_orders,
        ROUND(
            100.0 * SUM(CASE
                            WHEN o.order_delivered_customer_date
                               > o.order_estimated_delivery_date
                            THEN 1 ELSE 0
                        END)
            / NULLIF(COUNT(o.order_id), 0), 2
        )                                                               AS late_pct,
        ROUND(SUM(op.payment_value), 2)                                 AS total_revenue
    FROM  olist_orders_dataset              o
    LEFT JOIN olist_order_payments_dataset  op ON o.order_id = op.order_id
    WHERE (@status IS NULL OR o.order_status = @status)
    GROUP BY o.order_status
    ORDER BY total_orders DESC;
END;
GO
 
-- Test Q8.17
EXEC sp_delivery_report_by_status @status = 'delivered';
GO
EXEC sp_delivery_report_by_status;              -- all statuses
GO
EXEC sp_delivery_report_by_status @status = 'shipped';
GO
 
 
-- --------------------------------------------------------------------
-- Q8.18  sp_top_n_products
-- --------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_top_n_products;
GO
 
CREATE PROCEDURE sp_top_n_products
    @top_n    INT          = 10,
    @category VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT TOP (@top_n)
        p.product_id,
        ISNULL(p.product_category_name, 'uncategorized')  AS product_category_name,
        COUNT(DISTINCT oi.order_id)                        AS total_orders,
        COUNT(oi.order_item_id)                            AS units_sold,
        ROUND(SUM(oi.price), 2)                            AS total_revenue,
        ROUND(AVG(oi.price), 2)                            AS avg_price,
        ROUND(SUM(oi.freight_value), 2)                    AS total_freight,
        ROUND(
            100.0 * SUM(oi.price)
                  / NULLIF(SUM(SUM(oi.price)) OVER (), 0)
        , 2)                                               AS revenue_pct_of_total
    FROM  olist_products_dataset       p
    JOIN  olist_order_items_dataset    oi ON p.product_id = oi.product_id
    JOIN  olist_orders_dataset         o  ON oi.order_id  = o.order_id
    WHERE
        o.order_status = 'delivered'
        AND (@category IS NULL
             OR p.product_category_name = @category)
    GROUP BY
        p.product_id,
        p.product_category_name
    ORDER BY total_revenue DESC;
END;
GO
 
-- Test Q8.18
EXEC sp_top_n_products @top_n = 10;
GO
EXEC sp_top_n_products @top_n = 5, @category = 'cama_mesa_banho';
GO
EXEC sp_top_n_products @top_n = 5, @category = 'esporte_lazer';
GO
 
-- --------------------------------------------------------------------
-- Q8.19  SET STATISTICS TIME & IO -- Benchmark a Revenue Query
-- --------------------------------------------------------------------
SET STATISTICS TIME ON;
SET STATISTICS IO   ON;
GO
 
-- Benchmark: monthly revenue (hits idx_ord_status_ts from Q8.08)
SELECT
    YEAR(o.order_purchase_timestamp)            AS order_year,
    MONTH(o.order_purchase_timestamp)           AS order_month,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)  AS total_revenue
FROM  olist_orders_dataset         o
JOIN  olist_order_items_dataset    oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp)
ORDER BY order_year, order_month;
GO
 
SET STATISTICS TIME OFF;
SET STATISTICS IO   OFF;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.20  Before / After Index Comparison
-- --------------------------------------------------------------------
 
-- STEP 1 : Disable idx_ord_status to simulate no-index state
ALTER INDEX idx_ord_status ON olist_orders_dataset DISABLE;
GO
 
-- STEP 2 : Run query -- expect TABLE SCAN / CLUSTERED INDEX SCAN
SET STATISTICS IO ON;
GO
SELECT order_id, customer_id, order_purchase_timestamp
FROM   olist_orders_dataset
WHERE  order_status               = 'delivered'
  AND  order_purchase_timestamp  >= '2018-01-01'
  AND  order_purchase_timestamp   < '2019-01-01';
GO
SET STATISTICS IO OFF;
GO
-- NOTE: Record the "logical reads" value from the Messages tab.
 
-- STEP 3 : Rebuild (re-enable) the index
ALTER INDEX idx_ord_status ON olist_orders_dataset REBUILD;
GO
 
-- STEP 4 : Re-run query -- expect INDEX SEEK (far fewer logical reads)
SET STATISTICS IO ON;
GO
SELECT order_id, customer_id, order_purchase_timestamp
FROM   olist_orders_dataset
WHERE  order_status               = 'delivered'
  AND  order_purchase_timestamp  >= '2018-01-01'
  AND  order_purchase_timestamp   < '2019-01-01';
GO
SET STATISTICS IO OFF;
GO
-- NOTE: Compare logical reads.  Index Seek typically cuts reads by 60-90%.
 
 
-- --------------------------------------------------------------------
-- Q8.21  Execution Plan -- Table Scan vs Index Seek
-- --------------------------------------------------------------------
 
-- Query A -- Full table read, no filter: expect Clustered Index Scan
SELECT *
FROM   olist_orders_dataset;
GO
 
-- Query B -- Filtered by status: expect Index Seek on idx_ord_status
SELECT order_id, customer_id, order_purchase_timestamp
FROM   olist_orders_dataset
WHERE  order_status = 'delivered';
GO
 
-- Query C -- Status + date range: expect Index Seek on idx_ord_status_ts
SELECT order_id, customer_id, order_purchase_timestamp
FROM   olist_orders_dataset
WHERE  order_status               = 'delivered'
  AND  order_purchase_timestamp  >= '2017-01-01'
  AND  order_purchase_timestamp   < '2018-01-01';
GO
 
-- Query D -- Multi-table JOIN: check for Index Seeks on FK indexes
--           idx_ord_customer_id, idx_pay_order_id should both fire
SELECT
    o.order_id,
    c.customer_state,
    SUM(op.payment_value) AS total_payment
FROM   olist_orders_dataset            o
JOIN   olist_customers_dataset         c  ON o.customer_id = c.customer_id
JOIN   olist_order_payments_dataset    op ON o.order_id    = op.order_id
WHERE  c.customer_state = 'SP'
  AND  o.order_status   = 'delivered'
GROUP BY o.order_id, c.customer_state;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.22  sp_helpindex -- Inspect All Indexes on Each Table
-- --------------------------------------------------------------------
EXEC sp_helpindex 'olist_customers_dataset';
GO
EXEC sp_helpindex 'olist_orders_dataset';
GO
EXEC sp_helpindex 'olist_order_items_dataset';
GO
EXEC sp_helpindex 'olist_order_payments_dataset';
GO
EXEC sp_helpindex 'olist_products_dataset';
GO
EXEC sp_helpindex 'olist_sellers_dataset';
GO
 
 
-- --------------------------------------------------------------------
-- Q8.23  Index Usage Statistics
-- --------------------------------------------------------------------
SELECT
    OBJECT_NAME(i.object_id)    AS table_name,
    i.name                      AS index_name,
    i.type_desc                 AS index_type,
    ISNULL(ius.user_seeks,   0) AS user_seeks,
    ISNULL(ius.user_scans,   0) AS user_scans,
    ISNULL(ius.user_lookups, 0) AS user_lookups,
    ISNULL(ius.user_updates, 0) AS user_updates,
    ius.last_user_seek,
    ius.last_user_scan
FROM       sys.indexes                    i
LEFT JOIN  sys.dm_db_index_usage_stats   ius
        ON  i.object_id    = ius.object_id
        AND i.index_id     = ius.index_id
        AND ius.database_id = DB_ID()
WHERE  OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
  AND  i.name IS NOT NULL
ORDER BY
    table_name,
    ISNULL(ius.user_seeks, 0) + ISNULL(ius.user_scans, 0) DESC;
GO
 
 
-- --------------------------------------------------------------------
-- Q8.24  Catalog Verification
-- --------------------------------------------------------------------
 
-- A : All Phase 8 views (prefix vw_)
SELECT
    name                      AS view_name,
    SCHEMA_NAME(schema_id)    AS schema_name,
    create_date,
    modify_date
FROM  sys.views
WHERE name LIKE 'vw_%'
ORDER BY name;
GO
 
-- B : All Phase 8 stored procedures (prefix sp_)
SELECT
    name                      AS procedure_name,
    SCHEMA_NAME(schema_id)    AS schema_name,
    create_date,
    modify_date
FROM  sys.procedures
WHERE name LIKE 'sp_%'
ORDER BY name;
GO
 
-- C : All non-clustered indexes created in Phase 8
SELECT
    OBJECT_NAME(object_id)  AS table_name,
    name                    AS index_name,
    type_desc,
    is_unique,
    is_disabled
FROM  sys.indexes
WHERE type_desc  = 'NONCLUSTERED'
  AND OBJECTPROPERTY(object_id, 'IsUserTable') = 1
ORDER BY OBJECT_NAME(object_id), name;
GO
 
