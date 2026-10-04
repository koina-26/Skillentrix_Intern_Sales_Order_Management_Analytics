USE olist_store;
GO
-- ============================================================
-- PHASE 7 : ADVANCED SQL
-- ============================================================
/* ============================================================
   SECTION 1 : SUBQUERIES
   ============================================================ */
 
-- Q7.01 Scalar Subquery — compare each payment to the overall average
SELECT
    order_id,
    payment_value,
    (SELECT AVG(payment_value)
     FROM   olist_order_payments_dataset)  AS avg_payment,payment_value
        - (SELECT AVG(payment_value)
           FROM   olist_order_payments_dataset) AS diff_from_avg
FROM olist_order_payments_dataset
ORDER BY diff_from_avg DESC;
GO
 
-- Q7.02  Subquery in WHERE — orders whose payment is above the overall average
SELECT
    order_id,
    payment_type,
    payment_value
FROM olist_order_payments_dataset
WHERE payment_value > (
    SELECT AVG(payment_value)
    FROM   olist_order_payments_dataset
)
ORDER BY payment_value DESC;
GO
 
-- Q7.03  IN Subquery — customers who have placed at least one order
SELECT
    customer_id,
    customer_city,
    customer_state
FROM olist_customers_dataset
WHERE customer_id IN (
    SELECT DISTINCT customer_id
    FROM   olist_orders_dataset
);
GO
 
-- Q7.04  NOT IN Subquery — customers who have never placed an order
SELECT
    customer_id,
    customer_city,
    customer_state
FROM olist_customers_dataset
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id
    FROM   olist_orders_dataset
    WHERE  customer_id IS NOT NULL
);
GO
 
-- Q7.05  EXISTS Subquery — sellers who have made at least one sale
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state
FROM olist_sellers_dataset s
WHERE EXISTS (
    SELECT 1
    FROM   olist_order_items_dataset oi
    WHERE  oi.seller_id = s.seller_id
);
GO
 
-- Q7.06  NOT EXISTS Subquery — sellers who have never made a sale
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state
FROM olist_sellers_dataset s
WHERE NOT EXISTS (
    SELECT 1
    FROM   olist_order_items_dataset oi
    WHERE  oi.seller_id = s.seller_id
);
GO
 
-- Q7.07  Correlated Subquery — each customer's most recent order date
SELECT
    c.customer_id,
    c.customer_city,
    c.customer_state,
    (SELECT MAX(o.order_purchase_timestamp)
     FROM   olist_orders_dataset o
     WHERE  o.customer_id = c.customer_id)   AS last_order_date
FROM olist_customers_dataset c
WHERE EXISTS (
    SELECT 1
    FROM   olist_orders_dataset o
    WHERE  o.customer_id = c.customer_id
)
ORDER BY last_order_date DESC;
GO
 
-- Q7.08  Derived Table (subquery in FROM) — top 10 customers by total spend
SELECT TOP 10
    dt.customer_id,
    c.customer_city,
    c.customer_state,
    dt.total_spent
FROM (
    SELECT
        o.customer_id,
        SUM(p.payment_value)  AS total_spent
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY o.customer_id
) AS dt
INNER JOIN olist_customers_dataset c ON c.customer_id = dt.customer_id
ORDER BY dt.total_spent DESC;
GO
 
-- Q7.09  Correlated Subquery — items priced above their own seller's average
SELECT
    oi.order_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    (SELECT AVG(oi2.price)
     FROM   olist_order_items_dataset oi2
     WHERE  oi2.seller_id = oi.seller_id)    AS seller_avg_price
FROM olist_order_items_dataset oi
WHERE oi.price > (
    SELECT AVG(oi2.price)
    FROM   olist_order_items_dataset oi2
    WHERE  oi2.seller_id = oi.seller_id
)
ORDER BY oi.seller_id, oi.price DESC;
GO
 
-- Q7.10  Subquery in HAVING — states with above-average customer counts
SELECT
    customer_state,
    COUNT(customer_id)  AS customer_count
FROM olist_customers_dataset
GROUP BY customer_state
HAVING COUNT(customer_id) > (
    SELECT AVG(state_count)
    FROM (
        SELECT COUNT(customer_id)  AS state_count
        FROM   olist_customers_dataset
        GROUP  BY customer_state
    ) AS state_summary
)
ORDER BY customer_count DESC;
GO
 
 
/* ============================================================
   SECTION 2 : CTEs (COMMON TABLE EXPRESSIONS)
   ============================================================ */
 
-- Q7.11  Basic CTE — total revenue by customer state with rank
WITH RevenueByState AS (
    SELECT
        c.customer_state,
        SUM(p.payment_value)  AS total_revenue
    FROM olist_customers_dataset        c
    INNER JOIN olist_orders_dataset          o  ON o.customer_id = c.customer_id
    INNER JOIN olist_order_payments_dataset  p  ON p.order_id    = o.order_id
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC)  AS revenue_rank
FROM RevenueByState
ORDER BY revenue_rank;
GO
 
-- Q7.12  CTE — customer order count, total spend, and average order value
WITH CustomerStats AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)  AS order_count,
        SUM(p.payment_value)         AS total_spent,
        AVG(p.payment_value)         AS avg_order_value
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT
    cs.customer_id,
    c.customer_city,
    c.customer_state,
    cs.order_count,
    cs.total_spent,
    cs.avg_order_value
FROM CustomerStats             cs
INNER JOIN olist_customers_dataset c ON c.customer_id = cs.customer_id
ORDER BY cs.total_spent DESC;
GO
 
-- Q7.13  Multiple CTEs — revenue CTE + order timeline CTE joined together
WITH RevenueCTE AS (
    SELECT
        o.customer_id,
        SUM(p.payment_value)  AS total_revenue
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY o.customer_id
),
OrderTimelineCTE AS (
    SELECT
        customer_id,
        COUNT(order_id)                   AS order_count,
        MIN(order_purchase_timestamp)      AS first_order,
        MAX(order_purchase_timestamp)      AS last_order
    FROM olist_orders_dataset
    GROUP BY customer_id
)
SELECT
    r.customer_id,
    ot.order_count,
    r.total_revenue,
    ot.first_order,
    ot.last_order,
    DATEDIFF(DAY, ot.first_order, ot.last_order)  AS customer_lifespan_days
FROM RevenueCTE         r
INNER JOIN OrderTimelineCTE ot ON ot.customer_id = r.customer_id
ORDER BY r.total_revenue DESC;
GO
 
-- Q7.14  CTE — seller performance: orders served, items sold, revenue
WITH SellerRevenue AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id)  AS orders_served,
        COUNT(oi.order_item_id)      AS items_sold,
        SUM(oi.price)                AS total_revenue,
        SUM(oi.freight_value)        AS total_freight,
        AVG(oi.price)                AS avg_item_price
    FROM olist_order_items_dataset oi
    GROUP BY oi.seller_id
)
SELECT
    sr.seller_id,
    s.seller_city,
    s.seller_state,
    sr.orders_served,
    sr.items_sold,
    sr.total_revenue,
    sr.total_freight,
    sr.avg_item_price
FROM SellerRevenue             sr
INNER JOIN olist_sellers_dataset s ON s.seller_id = sr.seller_id
ORDER BY sr.total_revenue DESC;
GO
 
-- Q7.15  CTE — delivery performance: actual vs estimated delivery days
WITH DeliveryCTE AS (
    SELECT
        order_id,
        order_status,
        order_purchase_timestamp,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)  AS actual_days,
        DATEDIFF(DAY, order_purchase_timestamp, order_estimated_delivery_date)  AS estimated_days
    FROM olist_orders_dataset
    WHERE order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)
SELECT
    order_id,
    order_status,
    actual_days,
    estimated_days,
    estimated_days - actual_days  AS days_ahead,   -- positive = delivered early
    CASE
        WHEN actual_days < estimated_days THEN 'Early'
        WHEN actual_days = estimated_days THEN 'On Time'
        ELSE                                   'Late'
    END AS delivery_performance
FROM DeliveryCTE
ORDER BY days_ahead DESC;
GO
 
-- Q7.16  CTE — product category revenue with % share of total
WITH CategoryRevenue AS (
    SELECT
        pr.product_category_name,
        SUM(oi.price)               AS category_revenue,
        COUNT(DISTINCT oi.order_id) AS order_count,
        AVG(oi.price)               AS avg_item_price
    FROM olist_order_items_dataset    oi
    INNER JOIN olist_products_dataset pr ON pr.product_id = oi.product_id
    GROUP BY pr.product_category_name
)
SELECT
    product_category_name,
    category_revenue,
    order_count,
    avg_item_price,
    ROUND(
        100.0 * category_revenue / NULLIF(SUM(category_revenue) OVER (), 0),
        2
    ) AS pct_of_total_revenue
FROM CategoryRevenue
ORDER BY category_revenue DESC;
GO
 
-- Q7.17  CTE — high-value orders (total payment > 500) with customer detail
WITH HighValueOrders AS (
    SELECT
        order_id,
        SUM(payment_value)  AS total_payment
    FROM olist_order_payments_dataset
    GROUP BY order_id
    HAVING SUM(payment_value) > 500
)
SELECT
    hv.order_id,
    hv.total_payment,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_city,
    c.customer_state
FROM HighValueOrders           hv
INNER JOIN olist_orders_dataset     o  ON o.order_id    = hv.order_id
INNER JOIN olist_customers_dataset  c  ON c.customer_id = o.customer_id
ORDER BY hv.total_payment DESC;
GO
 
-- Q7.18  Chained CTEs — classify states as Above / Below Average revenue
WITH StateRevenue AS (
    SELECT
        c.customer_state,
        SUM(p.payment_value)  AS total_revenue
    FROM olist_customers_dataset        c
    INNER JOIN olist_orders_dataset          o  ON o.customer_id = c.customer_id
    INNER JOIN olist_order_payments_dataset  p  ON p.order_id    = o.order_id
    GROUP BY c.customer_state
),
NationalAvg AS (
    SELECT AVG(total_revenue) AS avg_revenue
    FROM StateRevenue
)
SELECT
    sr.customer_state,
    sr.total_revenue,
    na.avg_revenue,
    CASE
        WHEN sr.total_revenue >= na.avg_revenue THEN 'Above Average'
        ELSE                                         'Below Average'
    END AS revenue_tier
FROM StateRevenue   sr
CROSS JOIN NationalAvg na
ORDER BY sr.total_revenue DESC;
GO
 
 
/* ============================================================
   SECTION 3 : CASE EXPRESSIONS
   ============================================================ */
 
-- Q7.19  Simple CASE — friendly payment type labels
SELECT
    order_id,
    payment_type,
    payment_value,
    CASE payment_type
        WHEN 'credit_card' THEN 'Credit Card'
        WHEN 'boleto'      THEN 'Bank Slip (Boleto)'
        WHEN 'voucher'     THEN 'Voucher'
        WHEN 'debit_card'  THEN 'Debit Card'
        ELSE                    'Other'
    END AS payment_label
FROM olist_order_payments_dataset
ORDER BY payment_value DESC;
GO
 
-- Q7.20  Searched CASE — segment orders by payment amount
SELECT
    order_id,
    payment_value,
    CASE
        WHEN payment_value  <   50 THEN 'Low    (< 50)'
        WHEN payment_value  <  200 THEN 'Medium (50–199)'
        WHEN payment_value  <  500 THEN 'High   (200–499)'
        ELSE                            'Premium (500+)'
    END AS value_segment
FROM olist_order_payments_dataset
ORDER BY payment_value DESC;
GO
 
-- Q7.21  CASE in Aggregation — pivot all order statuses into a single row
SELECT
    SUM(CASE WHEN order_status = 'delivered'   THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN order_status = 'shipped'     THEN 1 ELSE 0 END) AS shipped,
    SUM(CASE WHEN order_status = 'processing'  THEN 1 ELSE 0 END) AS processing,
    SUM(CASE WHEN order_status = 'canceled'    THEN 1 ELSE 0 END) AS canceled,
    SUM(CASE WHEN order_status = 'invoiced'    THEN 1 ELSE 0 END) AS invoiced,
    SUM(CASE WHEN order_status = 'approved'    THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN order_status = 'unavailable' THEN 1 ELSE 0 END) AS unavailable,
    COUNT(*)                                                         AS total_orders
FROM olist_orders_dataset;
GO
 
-- Q7.22  CASE — classify every order's delivery timing
SELECT
    order_id,
    order_status,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    CASE
        WHEN order_delivered_customer_date < order_estimated_delivery_date THEN 'Delivered Early'
        WHEN order_delivered_customer_date = order_estimated_delivery_date THEN 'Delivered On Time'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Delivered Late'
        WHEN order_delivered_customer_date IS NULL
             AND order_status = 'canceled'                             THEN 'Canceled'
        ELSE 'Pending / Not Yet Delivered'
    END AS delivery_status
FROM olist_orders_dataset;
GO
 
-- Q7.23  CASE — assign customer loyalty tier by lifetime spend
WITH CustomerSpend AS (
    SELECT
        o.customer_id,
        SUM(p.payment_value)  AS total_spent
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    total_spent,
    CASE
        WHEN total_spent >= 1000 THEN 'Platinum'
        WHEN total_spent >=  500 THEN 'Gold'
        WHEN total_spent >=  200 THEN 'Silver'
        ELSE                          'Bronze'
    END AS loyalty_tier
FROM CustomerSpend
ORDER BY total_spent DESC;
GO
 
-- Q7.24  CASE inside GROUP BY — revenue summary grouped by payment category
SELECT
    CASE payment_type
        WHEN 'credit_card' THEN 'Credit Card'
        WHEN 'boleto'      THEN 'Bank Slip'
        WHEN 'voucher'     THEN 'Voucher'
        WHEN 'debit_card'  THEN 'Debit Card'
        ELSE 'Other'
    END                      AS payment_category,
    COUNT(*)                 AS transaction_count,
    SUM(payment_value)       AS total_revenue,
    AVG(payment_value)       AS avg_payment,
    MIN(payment_value)       AS min_payment,
    MAX(payment_value)       AS max_payment
FROM olist_order_payments_dataset
GROUP BY
    CASE payment_type
        WHEN 'credit_card' THEN 'Credit Card'
        WHEN 'boleto'      THEN 'Bank Slip'
        WHEN 'voucher'     THEN 'Voucher'
        WHEN 'debit_card'  THEN 'Debit Card'
        ELSE 'Other'
    END
ORDER BY total_revenue DESC;
GO
 
-- Q7.25  CASE — classify freight cost and compute freight-to-price ratio
SELECT
    oi.order_id,
    oi.product_id,
    oi.price,
    oi.freight_value,
    CASE
        WHEN oi.freight_value  =   0 THEN 'Free Shipping'
        WHEN oi.freight_value  <  20 THEN 'Low Freight'
        WHEN oi.freight_value  <  50 THEN 'Medium Freight'
        ELSE                              'High Freight'
    END AS freight_category,
    ROUND(100.0 * oi.freight_value / NULLIF(oi.price, 0), 2)  AS freight_pct_of_price
FROM olist_order_items_dataset oi
ORDER BY freight_pct_of_price DESC;
GO
 
-- Q7.26  CASE — classify sellers by order volume (size segment)
SELECT
    seller_id,
    COUNT(DISTINCT order_id)  AS orders_count,
    CASE
        WHEN COUNT(DISTINCT order_id) >= 500 THEN 'Large Seller'
        WHEN COUNT(DISTINCT order_id) >= 100 THEN 'Medium Seller'
        WHEN COUNT(DISTINCT order_id) >=  10 THEN 'Small Seller'
        ELSE                                      'Micro Seller'
    END AS seller_size
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY orders_count DESC;
GO
 
 
/* ============================================================
   SECTION 4 : WINDOW FUNCTIONS
   ============================================================ */
 
-- Q7.27  ROW_NUMBER() — global sequence number ordered by purchase date
SELECT
    ROW_NUMBER() OVER (ORDER BY order_purchase_timestamp)  AS row_num,
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
FROM olist_orders_dataset
ORDER BY row_num;
GO
 
-- Q7.28  ROW_NUMBER() PARTITION BY — order sequence number per customer
SELECT
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY     order_purchase_timestamp
    )                            AS order_seq,
    order_id,
    customer_id,
    order_purchase_timestamp,
    order_status
FROM olist_orders_dataset
ORDER BY customer_id, order_seq;
GO
 
-- Q7.29  RANK() — rank sellers by total revenue (ties share the same rank)
SELECT
    seller_id,
    SUM(price)    AS total_revenue,
    RANK()  OVER (ORDER BY SUM(price) DESC)  AS revenue_rank
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY revenue_rank;
GO
 
-- Q7.30  DENSE_RANK() — rank products by items sold (no gaps in ranking)
SELECT
    product_id,
    COUNT(order_item_id)                                       AS items_sold,
    DENSE_RANK() OVER (ORDER BY COUNT(order_item_id) DESC)    AS popularity_rank
FROM olist_order_items_dataset
GROUP BY product_id
ORDER BY popularity_rank;
GO
 
-- Q7.31  NTILE(4) — divide customers into spending quartiles
WITH CustomerSpend AS (
    SELECT
        o.customer_id,
        SUM(p.payment_value)  AS total_spent
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    total_spent,
    NTILE(4) OVER (ORDER BY total_spent)   AS spending_quartile,
    CASE NTILE(4) OVER (ORDER BY total_spent)
        WHEN 1 THEN 'Q1 – Low Spenders'
        WHEN 2 THEN 'Q2 – Below Average'
        WHEN 3 THEN 'Q3 – Above Average'
        WHEN 4 THEN 'Q4 – Top Spenders'
    END AS quartile_label
FROM CustomerSpend
ORDER BY total_spent;
GO
 
-- Q7.32  LAG() — compare each payment row to the previous row
SELECT
    order_id,
    payment_type,
    payment_value,
    LAG(payment_value, 1) OVER (ORDER BY order_id)                   AS prev_payment,
    payment_value - LAG(payment_value, 1) OVER (ORDER BY order_id)  AS change_from_prev
FROM olist_order_payments_dataset
ORDER BY order_id;
GO
 
-- Q7.33  LEAD() — days between a customer's consecutive orders
SELECT
    order_id,
    customer_id,
    order_purchase_timestamp,
    LEAD(order_purchase_timestamp, 1) OVER (
        PARTITION BY customer_id
        ORDER BY     order_purchase_timestamp
    )                                                           AS next_order_date,
    DATEDIFF(DAY,
        order_purchase_timestamp,
        LEAD(order_purchase_timestamp, 1) OVER (
            PARTITION BY customer_id
            ORDER BY     order_purchase_timestamp
        )
    )                                                           AS days_between_orders
FROM olist_orders_dataset
ORDER BY customer_id, order_purchase_timestamp;
GO
 
-- Q7.34  FIRST_VALUE() — tag each row with the customer's first order date
SELECT
    order_id,
    customer_id,
    order_purchase_timestamp,
    FIRST_VALUE(order_purchase_timestamp) OVER (
        PARTITION BY customer_id
        ORDER BY     order_purchase_timestamp
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS first_order_date
FROM olist_orders_dataset
ORDER BY customer_id, order_purchase_timestamp;
GO
 
-- Q7.35  LAST_VALUE() — tag each row with the customer's most recent order date
SELECT
    order_id,
    customer_id,
    order_purchase_timestamp,
    LAST_VALUE(order_purchase_timestamp) OVER (
        PARTITION BY customer_id
        ORDER BY     order_purchase_timestamp
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_order_date
FROM olist_orders_dataset
ORDER BY customer_id, order_purchase_timestamp;
GO
 
-- Q7.36  PERCENT_RANK() & CUME_DIST() — payment percentile distribution
SELECT
    order_id,
    payment_value,
    ROUND(PERCENT_RANK() OVER (ORDER BY payment_value) * 100, 2) AS percentile_rank,
    ROUND(CUME_DIST()    OVER (ORDER BY payment_value) * 100, 2) AS cumulative_dist_pct
FROM olist_order_payments_dataset
ORDER BY payment_value;
GO
 
-- Q7.37  Window Function with PARTITION BY — rank customers within each state
WITH StateCustomerRevenue AS (
    SELECT
        c.customer_id,
        c.customer_state,
        SUM(p.payment_value)  AS total_spent
    FROM olist_customers_dataset        c
    INNER JOIN olist_orders_dataset          o  ON o.customer_id = c.customer_id
    INNER JOIN olist_order_payments_dataset  p  ON p.order_id    = o.order_id
    GROUP BY c.customer_id, c.customer_state
)
SELECT
    customer_id,
    customer_state,
    total_spent,
    RANK()       OVER (PARTITION BY customer_state ORDER BY total_spent DESC) AS rank_in_state,
    DENSE_RANK() OVER (PARTITION BY customer_state ORDER BY total_spent DESC) AS dense_rank_in_state,
    ROW_NUMBER() OVER (PARTITION BY customer_state ORDER BY total_spent DESC) AS row_num_in_state
FROM StateCustomerRevenue
ORDER BY customer_state, rank_in_state;
GO
 
 
/* ============================================================
   SECTION 5 : RANKING
   ============================================================ */
 
-- Q7.38  RANK() — customers ranked by lifetime revenue
SELECT
    o.customer_id,
    c.customer_city,
    c.customer_state,
    SUM(p.payment_value)                                      AS total_spent,
    RANK() OVER (ORDER BY SUM(p.payment_value) DESC)          AS revenue_rank
FROM olist_orders_dataset            o
INNER JOIN olist_order_payments_dataset  p ON p.order_id    = o.order_id
INNER JOIN olist_customers_dataset       c ON c.customer_id = o.customer_id
GROUP BY o.customer_id, c.customer_city, c.customer_state
ORDER BY revenue_rank;
GO
 
-- Q7.39  DENSE_RANK() — products ranked by distinct orders (no rank gaps)
SELECT
    oi.product_id,
    pr.product_category_name,
    COUNT(DISTINCT oi.order_id)                                        AS order_count,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT oi.order_id) DESC)     AS popularity_dense_rank
FROM olist_order_items_dataset    oi
LEFT JOIN olist_products_dataset  pr ON pr.product_id = oi.product_id
GROUP BY oi.product_id, pr.product_category_name
ORDER BY popularity_dense_rank;
GO
 
-- Q7.40  ROW_NUMBER() for Pagination — page 1 (rows 1 to 20)
WITH OrderedOrders AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY order_purchase_timestamp DESC)  AS row_num,
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp
    FROM olist_orders_dataset
)
SELECT *
FROM OrderedOrders
WHERE row_num BETWEEN 1 AND 20;
GO
 
-- Q7.41  ROW_NUMBER() — each customer's single highest-value order
WITH RankedOrders AS (
    SELECT
        o.customer_id,
        o.order_id,
        SUM(p.payment_value)   AS order_total,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY     SUM(p.payment_value) DESC
        ) AS rn
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY o.customer_id, o.order_id
)
SELECT
    customer_id,
    order_id,
    order_total  AS highest_order_value
FROM RankedOrders
WHERE rn = 1
ORDER BY highest_order_value DESC;
GO
 
-- Q7.42  DENSE_RANK() — top 3 sellers per state by revenue
WITH SellerStateRevenue AS (
    SELECT
        s.seller_state,
        oi.seller_id,
        SUM(oi.price)   AS total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY s.seller_state
            ORDER BY     SUM(oi.price) DESC
        ) AS state_rank
    FROM olist_order_items_dataset  oi
    INNER JOIN olist_sellers_dataset     s ON s.seller_id = oi.seller_id
    GROUP BY s.seller_state, oi.seller_id
)
SELECT
    seller_state,
    seller_id,
    total_revenue,
    state_rank
FROM SellerStateRevenue
WHERE state_rank <= 3
ORDER BY seller_state, state_rank;
GO
 
-- Q7.43  All three ranking functions compared — payment types by revenue
SELECT
    payment_type,
    SUM(payment_value)                                         AS total_revenue,
    COUNT(*)                                                   AS transaction_count,
    RANK()       OVER (ORDER BY SUM(payment_value) DESC)      AS [rank],
    DENSE_RANK() OVER (ORDER BY SUM(payment_value) DESC)      AS dense_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(payment_value) DESC)      AS row_number
FROM olist_order_payments_dataset
GROUP BY payment_type;
GO
 
-- Q7.44  RANK() within partition — top-earning category per seller state
WITH CategoryStateSales AS (
    SELECT
        s.seller_state,
        pr.product_category_name,
        SUM(oi.price)  AS revenue,
        RANK() OVER (
            PARTITION BY s.seller_state
            ORDER BY     SUM(oi.price) DESC
        ) AS cat_rank_in_state
    FROM olist_order_items_dataset   oi
    INNER JOIN olist_sellers_dataset      s  ON s.seller_id  = oi.seller_id
    INNER JOIN olist_products_dataset     pr ON pr.product_id = oi.product_id
    GROUP BY s.seller_state, pr.product_category_name
)
SELECT
    seller_state,
    product_category_name,
    revenue,
    cat_rank_in_state
FROM CategoryStateSales
WHERE cat_rank_in_state = 1          -- only the #1 category per state
ORDER BY seller_state;
GO
 
 
/* ============================================================
   SECTION 6 : RUNNING TOTALS
   ============================================================ */
 
-- Q7.45  Running daily revenue total (expanding window)
WITH DailyRevenue AS (
    SELECT
        CAST(o.order_purchase_timestamp AS DATE)  AS order_date,
        SUM(p.payment_value)                       AS daily_revenue
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY CAST(o.order_purchase_timestamp AS DATE)
)
SELECT
    order_date,
    daily_revenue,
    SUM(daily_revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue
FROM DailyRevenue
ORDER BY order_date;
GO
 
-- Q7.46  Monthly running total with 3-month rolling average
WITH MonthlyRevenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp)   AS yr,
        MONTH(o.order_purchase_timestamp)  AS mo,
        SUM(p.payment_value)               AS monthly_revenue
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
)
SELECT
    yr,
    mo,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        ORDER BY yr, mo
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                   AS running_total,
    ROUND(AVG(monthly_revenue) OVER (
        ORDER BY yr, mo
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                               AS rolling_3mo_avg
FROM MonthlyRevenue
ORDER BY yr, mo;
GO
 
-- Q7.47  Cumulative order count over time
WITH DailyOrders AS (
    SELECT
        CAST(order_purchase_timestamp AS DATE)  AS order_date,
        COUNT(order_id)                          AS daily_orders
    FROM olist_orders_dataset
    GROUP BY CAST(order_purchase_timestamp AS DATE)
)
SELECT
    order_date,
    daily_orders,
    SUM(daily_orders) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_orders
FROM DailyOrders
ORDER BY order_date;
GO
 
-- Q7.48  Running revenue and item count per seller (partitioned)
SELECT
    seller_id,
    order_id,
    order_item_id,
    price,
    SUM(price) OVER (
        PARTITION BY seller_id
        ORDER BY     order_item_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_seller_revenue,
    COUNT(order_item_id) OVER (
        PARTITION BY seller_id
        ORDER BY     order_item_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_item_count
FROM olist_order_items_dataset
ORDER BY seller_id, order_item_id;
GO
 
-- Q7.49  Monthly running revenue with cumulative % of grand total
WITH MonthlyRevenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp)   AS yr,
        MONTH(o.order_purchase_timestamp)  AS mo,
        SUM(p.payment_value)               AS monthly_revenue
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
)
SELECT
    yr,
    mo,
    monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY yr, mo)   AS running_total,
    SUM(monthly_revenue) OVER ()                   AS grand_total,
    ROUND(
        100.0
        * SUM(monthly_revenue) OVER (ORDER BY yr, mo)
        / NULLIF(SUM(monthly_revenue) OVER (), 0),
        2
    ) AS cumulative_pct_of_total
FROM MonthlyRevenue
ORDER BY yr, mo;
GO
 
-- Q7.50  Running min / max / avg payment value (expanding window)
SELECT
    order_id,
    payment_value,
    ROUND(AVG(payment_value) OVER (
        ORDER BY order_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS running_avg,
    MIN(payment_value) OVER (
        ORDER BY order_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )     AS running_min,
    MAX(payment_value) OVER (
        ORDER BY order_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )     AS running_max
FROM olist_order_payments_dataset
ORDER BY order_id;
GO
 
 
/* ============================================================
   SECTION 7 : MONTH-OVER-MONTH ANALYSIS
   ============================================================ */
 
-- Q7.51  Monthly revenue with MoM change (amount and %) using LAG()
WITH MonthlyRevenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp)   AS yr,
        MONTH(o.order_purchase_timestamp)  AS mo,
        SUM(p.payment_value)               AS monthly_revenue
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
)
SELECT
    yr,
    mo,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY yr, mo)               AS prev_month_revenue,
    monthly_revenue
        - LAG(monthly_revenue, 1) OVER (ORDER BY yr, mo)         AS mom_change,
    ROUND(
        100.0
        * (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY yr, mo))
        / NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY yr, mo), 0),
        2
    )                                                             AS mom_pct_change
FROM MonthlyRevenue
ORDER BY yr, mo;
GO
 
-- Q7.52  Monthly order count with MoM change using LAG()
WITH MonthlyOrders AS (
    SELECT
        YEAR(order_purchase_timestamp)   AS yr,
        MONTH(order_purchase_timestamp)  AS mo,
        COUNT(order_id)                  AS order_count
    FROM olist_orders_dataset
    GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
)
SELECT
    yr,
    mo,
    order_count,
    LAG(order_count, 1) OVER (ORDER BY yr, mo)                AS prev_month_orders,
    order_count
        - LAG(order_count, 1) OVER (ORDER BY yr, mo)          AS mom_order_change,
    ROUND(
        100.0
        * (order_count - LAG(order_count, 1) OVER (ORDER BY yr, mo))
        / NULLIF(LAG(order_count, 1) OVER (ORDER BY yr, mo), 0),
        2
    )                                                          AS mom_order_pct_change
FROM MonthlyOrders
ORDER BY yr, mo;
GO
 
-- Q7.53  Monthly unique customers with MoM change
WITH MonthlyCustomers AS (
    SELECT
        YEAR(order_purchase_timestamp)   AS yr,
        MONTH(order_purchase_timestamp)  AS mo,
        COUNT(DISTINCT customer_id)      AS unique_customers
    FROM olist_orders_dataset
    GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
)
SELECT
    yr,
    mo,
    unique_customers,
    LAG(unique_customers, 1) OVER (ORDER BY yr, mo)               AS prev_month_customers,
    unique_customers
        - LAG(unique_customers, 1) OVER (ORDER BY yr, mo)         AS mom_customer_change,
    ROUND(
        100.0
        * (unique_customers - LAG(unique_customers, 1) OVER (ORDER BY yr, mo))
        / NULLIF(LAG(unique_customers, 1) OVER (ORDER BY yr, mo), 0),
        2
    )                                                              AS mom_customer_pct_change
FROM MonthlyCustomers
ORDER BY yr, mo;
GO
 
-- Q7.54  Year-over-Year (YoY) revenue — same month prior year via LAG(12)
WITH MonthlyRevenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp)   AS yr,
        MONTH(o.order_purchase_timestamp)  AS mo,
        SUM(p.payment_value)               AS monthly_revenue
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
)
SELECT
    yr,
    mo,
    monthly_revenue,
    LAG(monthly_revenue, 12) OVER (ORDER BY yr, mo)               AS same_month_prior_year,
    monthly_revenue
        - LAG(monthly_revenue, 12) OVER (ORDER BY yr, mo)         AS yoy_change,
    ROUND(
        100.0
        * (monthly_revenue - LAG(monthly_revenue, 12) OVER (ORDER BY yr, mo))
        / NULLIF(LAG(monthly_revenue, 12) OVER (ORDER BY yr, mo), 0),
        2
    )                                                              AS yoy_pct_change
FROM MonthlyRevenue
ORDER BY yr, mo;
GO
 
-- Q7.55  3-month and 6-month rolling average revenue
WITH MonthlyRevenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp)   AS yr,
        MONTH(o.order_purchase_timestamp)  AS mo,
        SUM(p.payment_value)               AS monthly_revenue
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
)
SELECT
    yr,
    mo,
    monthly_revenue,
    ROUND(AVG(monthly_revenue) OVER (
        ORDER BY yr, mo
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3mo_avg,
    ROUND(AVG(monthly_revenue) OVER (
        ORDER BY yr, mo
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_6mo_avg
FROM MonthlyRevenue
ORDER BY yr, mo;
GO
 
-- Q7.56  MoM revenue breakdown by payment type (PARTITION BY payment_type)
WITH MonthlyPaymentRevenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp)   AS yr,
        MONTH(o.order_purchase_timestamp)  AS mo,
        p.payment_type,
        SUM(p.payment_value)               AS revenue
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp),
        p.payment_type
)
SELECT
    yr,
    mo,
    payment_type,
    revenue,
    LAG(revenue, 1) OVER (
        PARTITION BY payment_type
        ORDER BY     yr, mo
    )                                         AS prev_month_revenue,
    ROUND(
        100.0
        * (revenue - LAG(revenue, 1) OVER (PARTITION BY payment_type ORDER BY yr, mo))
        / NULLIF(LAG(revenue, 1) OVER (PARTITION BY payment_type ORDER BY yr, mo), 0),
        2
    )                                         AS mom_pct_change
FROM MonthlyPaymentRevenue
ORDER BY yr, mo, payment_type;
GO
 
-- Q7.57  Monthly trend flag — Growth / Decline / Flat + best and worst month
WITH MonthlyRevenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp)   AS yr,
        MONTH(o.order_purchase_timestamp)  AS mo,
        SUM(p.payment_value)               AS monthly_revenue
    FROM olist_orders_dataset            o
    INNER JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
    GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
)
SELECT
    yr,
    mo,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY yr, mo)    AS prev_month_revenue,
    CASE
        WHEN monthly_revenue > LAG(monthly_revenue) OVER (ORDER BY yr, mo) THEN 'Growth'
        WHEN monthly_revenue < LAG(monthly_revenue) OVER (ORDER BY yr, mo) THEN 'Decline'
        ELSE 'Flat / No Prior Month'
    END                                            AS trend_flag,
    MAX(monthly_revenue) OVER ()                   AS best_month_ever,
    MIN(monthly_revenue) OVER ()                   AS worst_month_ever
FROM MonthlyRevenue
ORDER BY yr, mo;
GO
 
