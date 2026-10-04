USE olist_store;

SELECT 'customers' AS table_name, COUNT(*) AS total_rows 
FROM dbo.olist_customers_dataset
UNION ALL
SELECT 'orders', COUNT(*) 
FROM dbo.olist_orders_dataset
UNION ALL
SELECT 'order_items', COUNT(*) 
FROM dbo.olist_order_items_dataset
UNION ALL
SELECT 'order_payments', COUNT(*) 
FROM dbo.olist_order_payments_dataset
UNION ALL
SELECT 'products', COUNT(*) 
FROM dbo.olist_products_dataset
UNION ALL
SELECT 'sellers', COUNT(*) 
FROM dbo.olist_sellers_dataset;