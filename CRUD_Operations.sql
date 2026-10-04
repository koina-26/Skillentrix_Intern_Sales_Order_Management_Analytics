USE olist_store;

-- PHASE 4: CRUD OPERATIONS
-- olist_store Database

-- ============================================
-- SECTION 1: SELECT (Read Existing Data)
-- ============================================

-- View customers
SELECT TOP 5 * FROM dbo.olist_customers_dataset;

-- View orders
SELECT TOP 5 * FROM dbo.olist_orders_dataset;

-- View order items
SELECT TOP 5 * FROM dbo.olist_order_items_dataset;

-- View payments
SELECT TOP 5 * FROM dbo.olist_order_payments_dataset;

-- View products
SELECT TOP 5 * FROM dbo.olist_products_dataset;

-- View sellers
SELECT TOP 5 * FROM dbo.olist_sellers_dataset;


-- ============================================
-- SECTION 2: INSERT (Add New Test Records)
-- ============================================

-- Insert test customer
INSERT INTO dbo.olist_customers_dataset
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES
('CUST_TEST_001', 'UNIQUE_TEST_001', '10001', 'sao paulo', 'SP');

-- Insert test seller
INSERT INTO dbo.olist_sellers_dataset
(seller_id, seller_zip_code_prefix, seller_city, seller_state)
VALUES
('SELL_TEST_001', '20001', 'rio de janeiro', 'RJ');

-- Insert test order
INSERT INTO dbo.olist_orders_dataset
(order_id, customer_id, order_status, order_purchase_timestamp,
order_approved_at, order_delivered_carrier_date,
order_delivered_customer_date, order_estimated_delivery_date)
VALUES
('ORDER_TEST_001', 'CUST_TEST_001', 'delivered',
'2024-01-01 10:00:00', '2024-01-01 11:00:00',
'2024-01-02 10:00:00', '2024-01-05 10:00:00',
'2024-01-07 10:00:00');

-- Insert test payment
INSERT INTO dbo.olist_order_payments_dataset
(order_id, payment_sequential, payment_type,
payment_installments, payment_value)
VALUES
('ORDER_TEST_001', 1, 'credit_card', 1, 250.00);

--  Verify all inserts
SELECT * FROM dbo.olist_customers_dataset
WHERE customer_id = 'CUST_TEST_001';

SELECT * FROM dbo.olist_sellers_dataset
WHERE seller_id = 'SELL_TEST_001';

SELECT * FROM dbo.olist_orders_dataset
WHERE order_id = 'ORDER_TEST_001';

SELECT * FROM dbo.olist_order_payments_dataset
WHERE order_id = 'ORDER_TEST_001';


-- ============================================
-- SECTION 3: ADVANCED SELECT QUERIES
-- ============================================

-- 1. Filter by condition
SELECT * FROM dbo.olist_orders_dataset
WHERE order_status = 'delivered';

-- 2. Order by latest date
SELECT TOP 10 * FROM dbo.olist_orders_dataset
ORDER BY order_purchase_timestamp DESC;

-- 3. Search using LIKE
SELECT * FROM dbo.olist_customers_dataset
WHERE customer_city LIKE 'sao%';

-- 4. Filter using IN
SELECT * FROM dbo.olist_orders_dataset
WHERE order_status IN ('delivered', 'shipped', 'canceled');

-- 5. Filter using BETWEEN (date range)
SELECT * FROM dbo.olist_orders_dataset
WHERE order_purchase_timestamp
BETWEEN '2017-01-01' AND '2017-12-31';

-- 6. COUNT total orders
SELECT COUNT(*) AS total_orders
FROM dbo.olist_orders_dataset;

-- 7. SUM total revenue
SELECT ROUND(SUM(payment_value), 2) AS total_revenue
FROM dbo.olist_order_payments_dataset;

-- 8. AVG payment value
SELECT ROUND(AVG(payment_value), 2) AS avg_order_value
FROM dbo.olist_order_payments_dataset;

-- 9. Group orders by status
SELECT order_status, COUNT(*) AS total
FROM dbo.olist_orders_dataset
GROUP BY order_status
ORDER BY total DESC;

-- 10. Group customers by state
SELECT customer_state, COUNT(*) AS total_customers
FROM dbo.olist_customers_dataset
GROUP BY customer_state
ORDER BY total_customers DESC;

-- 11. Payment type breakdown
SELECT 
    payment_type, 
    COUNT(*) AS total_transactions,
    ROUND(SUM(payment_value), 2) AS total_value
FROM dbo.olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_transactions DESC;

-- 12. Products by category count
SELECT 
    product_category_name, 
    COUNT(*) AS total_products
FROM dbo.olist_products_dataset
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY total_products DESC;

-- 13. Sellers by state
SELECT 
    seller_state, 
    COUNT(*) AS total_sellers
FROM dbo.olist_sellers_dataset
GROUP BY seller_state
ORDER BY total_sellers DESC;

-- 14. MIN and MAX payment values
SELECT 
    MIN(payment_value) AS min_payment,
    MAX(payment_value) AS max_payment,
    ROUND(AVG(payment_value), 2) AS avg_payment
FROM dbo.olist_order_payments_dataset;

-- 15. Orders per year
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS total_orders
FROM dbo.olist_orders_dataset
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;


-- ============================================
-- SECTION 4: UPDATE (Modify Test Records)
-- ============================================

-- Update customer city
UPDATE dbo.olist_customers_dataset
SET customer_city = 'rio de janeiro',
    customer_state = 'RJ'
WHERE customer_id = 'CUST_TEST_001';

-- Update order status
UPDATE dbo.olist_orders_dataset
SET order_status = 'shipped'
WHERE order_id = 'ORDER_TEST_001';

-- Update payment value
UPDATE dbo.olist_order_payments_dataset
SET payment_value = 300.00,
    payment_installments = 2
WHERE order_id = 'ORDER_TEST_001';

-- Update seller city
UPDATE dbo.olist_sellers_dataset
SET seller_city = 'belo horizonte',
    seller_state = 'MG'
WHERE seller_id = 'SELL_TEST_001';

-- ✅ Verify all updates
SELECT * FROM dbo.olist_customers_dataset
WHERE customer_id = 'CUST_TEST_001';

SELECT * FROM dbo.olist_orders_dataset
WHERE order_id = 'ORDER_TEST_001';

SELECT * FROM dbo.olist_order_payments_dataset
WHERE order_id = 'ORDER_TEST_001';

SELECT * FROM dbo.olist_sellers_dataset
WHERE seller_id = 'SELL_TEST_001';


-- ============================================
-- SECTION 5: DELETE (Remove Test Records)
-- ============================================

-- Delete in correct order (child tables first!)
DELETE FROM dbo.olist_order_payments_dataset
WHERE order_id = 'ORDER_TEST_001';

DELETE FROM dbo.olist_orders_dataset
WHERE order_id = 'ORDER_TEST_001';

DELETE FROM dbo.olist_customers_dataset
WHERE customer_id = 'CUST_TEST_001';

DELETE FROM dbo.olist_sellers_dataset
WHERE seller_id = 'SELL_TEST_001';

-- ✅ Verify all deletions (should return 0 rows)
SELECT * FROM dbo.olist_customers_dataset
WHERE customer_id = 'CUST_TEST_001';

SELECT * FROM dbo.olist_orders_dataset
WHERE order_id = 'ORDER_TEST_001';

SELECT * FROM dbo.olist_order_payments_dataset
WHERE order_id = 'ORDER_TEST_001';

SELECT * FROM dbo.olist_sellers_dataset
WHERE seller_id = 'SELL_TEST_001';

