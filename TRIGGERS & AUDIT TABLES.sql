
USE olist_store;
GO
 
-- ============================================================
-- PART A: AFTER TRIGGERS (INSERT, UPDATE, DELETE)
-- ============================================================
 
-- Q11.01  Create audit log table for orders
CREATE TABLE order_audit_log (
    audit_id    INT IDENTITY(1,1) PRIMARY KEY,
    order_id    VARCHAR(50),
    action_type VARCHAR(10),
    old_status  VARCHAR(30),
    new_status  VARCHAR(30),
    changed_by  VARCHAR(100) DEFAULT SYSTEM_USER,
    changed_at  DATETIME     DEFAULT GETDATE()
);
GO
 
-- Q11.02  AFTER INSERT -- log every new order
CREATE OR ALTER TRIGGER trg_orders_insert
ON olist_orders_dataset
AFTER INSERT
AS
BEGIN
    INSERT INTO order_audit_log (order_id, action_type, new_status)
    SELECT order_id, 'INSERT', order_status FROM inserted;
END;
GO
 
-- Q11.03  AFTER UPDATE -- log old and new status on each update
CREATE OR ALTER TRIGGER trg_orders_update
ON olist_orders_dataset
AFTER UPDATE
AS
BEGIN
    INSERT INTO order_audit_log (order_id, action_type, old_status, new_status)
    SELECT i.order_id, 'UPDATE', d.order_status, i.order_status
    FROM inserted i JOIN deleted d ON i.order_id = d.order_id;
END;
GO
 
-- Q11.04  AFTER DELETE -- log deleted order with its last status
CREATE OR ALTER TRIGGER trg_orders_delete
ON olist_orders_dataset
AFTER DELETE
AS
BEGIN
    INSERT INTO order_audit_log (order_id, action_type, old_status)
    SELECT order_id, 'DELETE', order_status FROM deleted;
END;
GO
 
-- Q11.05  Create audit table for order items
CREATE TABLE order_items_audit (
    audit_id    INT IDENTITY(1,1) PRIMARY KEY,
    order_id    VARCHAR(50),
    product_id  VARCHAR(50),
    action_type VARCHAR(10),
    price       DECIMAL(10,2),
    logged_at   DATETIME DEFAULT GETDATE()
);
GO
 
-- Q11.06  AFTER INSERT on order items -- log each new item
CREATE OR ALTER TRIGGER trg_items_insert
ON olist_order_items_dataset
AFTER INSERT
AS
BEGIN
    INSERT INTO order_items_audit (order_id, product_id, action_type, price)
    SELECT order_id, product_id, 'INSERT', price FROM inserted;
END;
GO
 
-- Q11.07  Create payments audit table
CREATE TABLE payments_audit (
    audit_id    INT IDENTITY(1,1) PRIMARY KEY,
    order_id    VARCHAR(50),
    old_value   DECIMAL(10,2),
    new_value   DECIMAL(10,2),
    action_type VARCHAR(10),
    logged_at   DATETIME DEFAULT GETDATE()
);
GO
 
-- Q11.08  AFTER UPDATE on payments -- track payment value changes
CREATE OR ALTER TRIGGER trg_payments_update
ON olist_order_payments_dataset
AFTER UPDATE
AS
BEGIN
    INSERT INTO payments_audit (order_id, old_value, new_value, action_type)
    SELECT i.order_id, d.payment_value, i.payment_value, 'UPDATE'
    FROM inserted i JOIN deleted d ON i.order_id = d.order_id;
END;
GO
 
-- ============================================================
-- PART B: INSTEAD OF TRIGGERS
-- ============================================================
 
-- Q11.09  INSTEAD OF DELETE -- block deletion of delivered orders
CREATE OR ALTER TRIGGER trg_orders_instead_del
ON olist_orders_dataset
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM deleted WHERE order_status = 'delivered')
    BEGIN
        RAISERROR('Cannot delete a delivered order.', 16, 1); RETURN;
    END
    DELETE FROM olist_orders_dataset
    WHERE order_id IN (SELECT order_id FROM deleted);
END;
GO
 
-- Q11.10  INSTEAD OF INSERT -- validate customer exists before inserting
CREATE OR ALTER TRIGGER trg_orders_instead_ins
ON olist_orders_dataset
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM olist_customers_dataset c WHERE c.customer_id = i.customer_id
        )
    )
    BEGIN
        RAISERROR('Invalid customer_id. Insert blocked.', 16, 1); RETURN;
    END
    INSERT INTO olist_orders_dataset (
        order_id, customer_id, order_status, order_purchase_timestamp,
        order_approved_at, order_delivered_carrier_date,
        order_delivered_customer_date, order_estimated_delivery_date)
    SELECT
        order_id, customer_id, order_status, order_purchase_timestamp,
        order_approved_at, order_delivered_carrier_date,
        order_delivered_customer_date, order_estimated_delivery_date
    FROM inserted;
END;
GO
 
-- Q11.11  INSTEAD OF UPDATE -- block reverting a delivered order status
CREATE OR ALTER TRIGGER trg_orders_instead_upd
ON olist_orders_dataset
INSTEAD OF UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM deleted d JOIN inserted i ON d.order_id = i.order_id
        WHERE d.order_status = 'delivered' AND i.order_status <> 'delivered'
    )
    BEGIN
        RAISERROR('Cannot revert a delivered order status.', 16, 1); RETURN;
    END
    UPDATE o SET
        o.order_status                 = i.order_status,
        o.order_approved_at            = i.order_approved_at,
        o.order_delivered_carrier_date = i.order_delivered_carrier_date,
        o.order_delivered_customer_date= i.order_delivered_customer_date,
        o.order_estimated_delivery_date= i.order_estimated_delivery_date
    FROM olist_orders_dataset o JOIN inserted i ON o.order_id = i.order_id;
END;
GO
 
-- Q11.12  INSTEAD OF DELETE on payments -- block if order is delivered
CREATE OR ALTER TRIGGER trg_pay_instead_del
ON olist_order_payments_dataset
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM deleted d
        JOIN olist_orders_dataset o ON d.order_id = o.order_id
        WHERE o.order_status = 'delivered'
    )
    BEGIN
        RAISERROR('Cannot delete payments for a delivered order.', 16, 1); RETURN;
    END
    DELETE FROM olist_order_payments_dataset
    WHERE order_id IN (SELECT order_id FROM deleted);
END;
GO
 
-- Q11.13  INSTEAD OF INSERT on payments -- block negative payment values
CREATE OR ALTER TRIGGER trg_pay_instead_ins
ON olist_order_payments_dataset
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE payment_value < 0)
    BEGIN
        RAISERROR('Payment value cannot be negative.', 16, 1); RETURN;
    END
    INSERT INTO olist_order_payments_dataset
        (order_id, payment_sequential, payment_type, payment_installments, payment_value)
    SELECT order_id, payment_sequential, payment_type, payment_installments, payment_value
    FROM inserted;
END;
GO
 
-- ============================================================
-- PART C: AUDIT LOG TABLES
-- ============================================================
 
-- Q11.14  Create master audit log -- central log for all key tables
CREATE TABLE master_audit_log (
    log_id      INT IDENTITY(1,1) PRIMARY KEY,
    table_name  VARCHAR(100),
    action_type VARCHAR(10),
    record_id   VARCHAR(100),
    changed_by  VARCHAR(100) DEFAULT SYSTEM_USER,
    changed_at  DATETIME     DEFAULT GETDATE()
);
GO
 
-- Q11.15  Master audit trigger -- fires on all DML on orders table
CREATE OR ALTER TRIGGER trg_master_audit_orders
ON olist_orders_dataset
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO master_audit_log (table_name, action_type, record_id)
        SELECT 'olist_orders_dataset', 'INSERT', order_id FROM inserted;
    ELSE IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO master_audit_log (table_name, action_type, record_id)
        SELECT 'olist_orders_dataset', 'DELETE', order_id FROM deleted;
    ELSE
        INSERT INTO master_audit_log (table_name, action_type, record_id)
        SELECT 'olist_orders_dataset', 'UPDATE', order_id FROM inserted;
END;
GO
 
-- Q11.16  View latest 20 order audit entries
SELECT TOP 20 * FROM order_audit_log ORDER BY changed_at DESC;
GO
 
-- Q11.17  Audit summary -- count by action type
SELECT action_type, COUNT(*) AS total
FROM master_audit_log
GROUP BY action_type ORDER BY total DESC;
GO
 
-- Q11.18  View all payment changes
SELECT * FROM payments_audit ORDER BY logged_at DESC;
GO
 
-- Q11.19  List all triggers in olist_store with their parent table
SELECT t.name AS trigger_name,
       OBJECT_NAME(t.parent_id) AS on_table,
       t.is_disabled
FROM sys.triggers t
WHERE t.parent_class = 1
ORDER BY on_table;
GO
 
-- ============================================================
-- PART D: REAL BUSINESS SCENARIOS (Olist Data)
-- ============================================================
 
-- Q11.20  Create high-value order alert table
CREATE TABLE high_value_alerts (
    alert_id      INT IDENTITY(1,1) PRIMARY KEY,
    order_id      VARCHAR(50),
    payment_value DECIMAL(10,2),
    alert_msg     VARCHAR(200),
    logged_at     DATETIME DEFAULT GETDATE()
);
GO
 
-- Q11.21  Trigger: flag any payment above R$1000 as high-value
CREATE OR ALTER TRIGGER trg_high_value_alert
ON olist_order_payments_dataset
AFTER INSERT
AS
BEGIN
    INSERT INTO high_value_alerts (order_id, payment_value, alert_msg)
    SELECT order_id, payment_value,
           'High-value payment: R$ ' + CAST(payment_value AS VARCHAR(20))
    FROM inserted WHERE payment_value > 1000;
END;
GO
 
-- Q11.22  Create cancelled orders tracking table
CREATE TABLE cancelled_orders_log (
    log_id       INT IDENTITY(1,1) PRIMARY KEY,
    order_id     VARCHAR(50),
    customer_id  VARCHAR(50),
    cancelled_at DATETIME DEFAULT GETDATE()
);
GO
 
-- Q11.23  Trigger: auto-log orders changed to 'canceled'
CREATE OR ALTER TRIGGER trg_flag_cancelled
ON olist_orders_dataset
AFTER UPDATE
AS
BEGIN
    INSERT INTO cancelled_orders_log (order_id, customer_id)
    SELECT i.order_id, i.customer_id
    FROM inserted i JOIN deleted d ON i.order_id = d.order_id
    WHERE i.order_status = 'canceled' AND d.order_status <> 'canceled';
END;
GO
 
-- Q11.24  Create freight value change log table
CREATE TABLE freight_change_log (
    log_id      INT IDENTITY(1,1) PRIMARY KEY,
    order_id    VARCHAR(50),
    old_freight DECIMAL(10,2),
    new_freight DECIMAL(10,2),
    changed_at  DATETIME DEFAULT GETDATE()
);
GO
 
-- Q11.25  Trigger: log freight value changes on order items
CREATE OR ALTER TRIGGER trg_freight_change
ON olist_order_items_dataset
AFTER UPDATE
AS
BEGIN
    INSERT INTO freight_change_log (order_id, old_freight, new_freight)
    SELECT i.order_id, d.freight_value, i.freight_value
    FROM inserted i JOIN deleted d
         ON i.order_id = d.order_id AND i.order_item_id = d.order_item_id
    WHERE i.freight_value <> d.freight_value;
END;
GO
 
-- Q11.26  INSTEAD OF DELETE on sellers -- block if seller has active orders
CREATE OR ALTER TRIGGER trg_sellers_instead_del
ON olist_sellers_dataset
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM deleted d
        JOIN olist_order_items_dataset oi ON d.seller_id  = oi.seller_id
        JOIN olist_orders_dataset o        ON oi.order_id = o.order_id
        WHERE o.order_status NOT IN ('delivered','canceled')
    )
    BEGIN
        RAISERROR('Seller has active orders. Delete blocked.', 16, 1); RETURN;
    END
    DELETE FROM olist_sellers_dataset WHERE seller_id IN (SELECT seller_id FROM deleted);
END;
GO
 
-- Q11.27  Maintenance -- disable order audit triggers for bulk load
DISABLE TRIGGER trg_orders_insert ON olist_orders_dataset;
DISABLE TRIGGER trg_orders_update ON olist_orders_dataset;
DISABLE TRIGGER trg_orders_delete ON olist_orders_dataset;
GO
 
-- Q11.28  Maintenance -- re-enable all order audit triggers after bulk load
ENABLE TRIGGER trg_orders_insert ON olist_orders_dataset;
ENABLE TRIGGER trg_orders_update ON olist_orders_dataset;
ENABLE TRIGGER trg_orders_delete ON olist_orders_dataset;
GO
 
-- Q11.29  Business report -- cancelled orders joined with customer city
SELECT cl.order_id, cl.customer_id, c.customer_city, cl.cancelled_at
FROM cancelled_orders_log cl
JOIN olist_customers_dataset c ON cl.customer_id = c.customer_id
ORDER BY cl.cancelled_at DESC;
GO
 
-- Q11.30  Business report -- high-value alert summary stats
SELECT COUNT(*)           AS total_alerts,
       AVG(payment_value) AS avg_value,
       MAX(payment_value) AS max_value
FROM high_value_alerts;
GO
 
 USE olist_store;
SELECT TOP 1 order_id, order_status FROM olist_orders_dataset;

USE olist_store;
UPDATE olist_orders_dataset
SET order_status = 'canceled'
WHERE order_id = (SELECT TOP 1 order_id FROM olist_orders_dataset WHERE order_status = 'shipped');

USE olist_store;
SELECT * FROM order_audit_log ORDER BY changed_at DESC;

USE olist_store;
SELECT * FROM cancelled_orders_log;