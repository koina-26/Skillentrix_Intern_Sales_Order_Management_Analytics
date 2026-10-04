USE olist_store;
GO

BEGIN TRANSACTION;

INSERT INTO olist_customers_dataset
VALUES ('CUST_TEST_001','UNIQUE_TEST_001','01310','sao paulo','SP');

SELECT customer_id, customer_city, customer_state
FROM olist_customers_dataset
WHERE customer_id = 'CUST_TEST_001';

COMMIT;
GO

SELECT customer_id, customer_city, customer_state
FROM olist_customers_dataset
WHERE customer_id = 'CUST_TEST_001';
GO

USE olist_store;
GO

BEGIN TRANSACTION;

INSERT INTO olist_orders_dataset
(order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date)
VALUES
('ORDER_TEST_001','CUST_TEST_001','pending',GETDATE(),DATEADD(DAY,7,GETDATE()));

SELECT order_id, order_status
FROM olist_orders_dataset
WHERE order_id = 'ORDER_TEST_001';

ROLLBACK;
GO

SELECT order_id, order_status
FROM olist_orders_dataset
WHERE order_id = 'ORDER_TEST_001';
GO

USE olist_store;
GO

DECLARE @target_order VARCHAR(50);

SELECT TOP 1 @target_order = order_id
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card'
ORDER BY payment_value DESC;

PRINT 'Updating payment for order: ' + @target_order;

BEGIN TRANSACTION;

UPDATE olist_order_payments_dataset
SET payment_value = payment_value + 10
WHERE order_id = @target_order
AND payment_type = 'credit_card';

SELECT order_id, payment_type, payment_value AS updated_value
FROM olist_order_payments_dataset
WHERE order_id = @target_order;

COMMIT;
GO

USE olist_store;
GO

BEGIN TRANSACTION;

SELECT COUNT(*) AS item_count_before_delete
FROM olist_order_items_dataset;

DELETE FROM olist_order_items_dataset
WHERE order_id = 'ORDER_TEST_001';

SELECT COUNT(*) AS item_count_after_delete
FROM olist_order_items_dataset;

ROLLBACK;
GO

SELECT COUNT(*) AS item_count_after_rollback
FROM olist_order_items_dataset;
GO

USE olist_store;
GO

SELECT @@TRANCOUNT AS trancount_before_begin;

BEGIN TRANSACTION;

SELECT @@TRANCOUNT AS trancount_inside_transaction;

INSERT INTO olist_customers_dataset
VALUES ('CUST_TEST_002','UNIQUE_TEST_002','20040','rio de janeiro','RJ');

COMMIT;

SELECT @@TRANCOUNT AS trancount_after_commit;
GO

DELETE FROM olist_customers_dataset
WHERE customer_id = 'CUST_TEST_002';
GO

USE olist_store;
GO

BEGIN TRANSACTION;

INSERT INTO olist_orders_dataset
(order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date)
VALUES
('ORDER_MULTI_001','CUST_TEST_001','pending',GETDATE(),DATEADD(DAY,7,GETDATE()));

PRINT 'Step 1 done: Order inserted.';

INSERT INTO olist_order_payments_dataset
(order_id, payment_sequential, payment_type, payment_installments, payment_value)
VALUES
('ORDER_MULTI_001',1,'credit_card',1,250.00);

PRINT 'Step 2 done: Payment inserted.';

SELECT o.order_id, o.order_status, p.payment_type, p.payment_value
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE o.order_id = 'ORDER_MULTI_001';

COMMIT;
GO

DELETE FROM olist_order_payments_dataset
WHERE order_id = 'ORDER_MULTI_001';

DELETE FROM olist_orders_dataset
WHERE order_id = 'ORDER_MULTI_001';
GO

USE olist_store;
GO

DECLARE @rows_affected INT;

BEGIN TRANSACTION;

UPDATE olist_orders_dataset
SET order_status = 'shipped'
WHERE order_id = 'ORDER_NONEXISTENT_99999';

SET @rows_affected = @@ROWCOUNT;

IF @rows_affected = 0
BEGIN
    PRINT 'No rows updated — rolling back.';
    ROLLBACK;
END
ELSE
BEGIN
    PRINT CAST(@rows_affected AS VARCHAR) + ' row(s) updated — committing.';
    COMMIT;
END
GO

USE olist_store;
GO

BEGIN TRANSACTION;

    INSERT INTO olist_customers_dataset (
        customer_id, customer_unique_id,
        customer_zip_code_prefix, customer_city, customer_state
    )
    VALUES (
        'CUST_TEST_003', 'UNIQUE_TEST_003',
        '30110', 'belo horizonte', 'MG'
    );

    IF @@ERROR <> 0
    BEGIN
        PRINT 'Customer insert failed — rolling back.';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO olist_orders_dataset (
        order_id, customer_id, order_status,
        order_purchase_timestamp,
        order_estimated_delivery_date
    )
    VALUES (
        'ORDER_TEST_003', 'CUST_TEST_003', 'pending',
        GETDATE(),
        DATEADD(DAY, 7, GETDATE())
    );

    IF @@ERROR <> 0
    BEGIN
        PRINT 'Order insert failed — rolling back.';
        ROLLBACK TRANSACTION;
        RETURN;
    END

COMMIT TRANSACTION;
PRINT 'Both inserts committed successfully.';
GO

DELETE FROM olist_orders_dataset
WHERE order_id = 'ORDER_TEST_003';
DELETE FROM olist_customers_dataset
WHERE customer_id = 'CUST_TEST_003';
GO

USE olist_store;
GO

BEGIN TRANSACTION;

INSERT INTO olist_customers_dataset
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES ('CUST_SP_001','UNQ_SP_001','01310','sao paulo','SP');

SAVE TRANSACTION SavePoint1;
PRINT 'Savepoint1 set.';

INSERT INTO olist_customers_dataset
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES ('CUST_SP_002','UNQ_SP_002','20040','rio de janeiro','RJ');

SELECT customer_id
FROM olist_customers_dataset
WHERE customer_id IN ('CUST_SP_001','CUST_SP_002');

ROLLBACK TRANSACTION SavePoint1;

SELECT customer_id
FROM olist_customers_dataset
WHERE customer_id IN ('CUST_SP_001','CUST_SP_002');

COMMIT;
GO

DELETE FROM olist_customers_dataset
WHERE customer_id = 'CUST_SP_001';
GO

USE olist_store;
GO

BEGIN TRANSACTION;

INSERT INTO olist_orders_dataset
(order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date)
VALUES ('ORDER_SP_001','CUST_TEST_001','pending',GETDATE(),DATEADD(DAY,7,GETDATE()));

SAVE TRANSACTION AfterOrderInsert;
PRINT 'Savepoint set after order insert.';

INSERT INTO olist_order_payments_dataset
(order_id, payment_sequential, payment_type, payment_installments, payment_value)
VALUES ('ORDER_SP_001',1,'WRONG_TYPE',3,300.00);

ROLLBACK TRANSACTION AfterOrderInsert;
PRINT 'Wrong payment rolled back.';

INSERT INTO olist_order_payments_dataset
(order_id, payment_sequential, payment_type, payment_installments, payment_value)
VALUES ('ORDER_SP_001',1,'boleto',1,295.00);

PRINT 'Correct payment inserted.';

COMMIT;
GO

DELETE FROM olist_order_payments_dataset
WHERE order_id = 'ORDER_SP_001';

DELETE FROM olist_orders_dataset
WHERE order_id = 'ORDER_SP_001';
GO

USE olist_store;
GO

BEGIN TRANSACTION;

INSERT INTO olist_customers_dataset
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES ('CUST_MSP_001','UNQ_MSP_001','41820','salvador','BA');

SAVE TRANSACTION SP_CustomerCreated;
PRINT 'SP1: Customer inserted.';

INSERT INTO olist_orders_dataset
(order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date)
VALUES ('ORDER_MSP_001','CUST_MSP_001','pending',GETDATE(),DATEADD(DAY,7,GETDATE()));

SAVE TRANSACTION SP_OrderCreated;
PRINT 'SP2: Order inserted.';

INSERT INTO olist_order_items_dataset
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
VALUES (
'ORDER_MSP_001',1,
(SELECT TOP 1 product_id FROM olist_products_dataset),
(SELECT TOP 1 seller_id FROM olist_sellers_dataset),
DATEADD(DAY,7,GETDATE()),-99.00,12.50);

ROLLBACK TRANSACTION SP_OrderCreated;
PRINT 'Bad item rolled back. Re-inserting correctly.';

INSERT INTO olist_order_items_dataset
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
VALUES (
'ORDER_MSP_001',1,
(SELECT TOP 1 product_id FROM olist_products_dataset),
(SELECT TOP 1 seller_id FROM olist_sellers_dataset),
DATEADD(DAY,10,GETDATE()),189.90,10.00);

PRINT 'SP3: Item re-inserted correctly.';

COMMIT;
GO

DELETE FROM olist_order_items_dataset
WHERE order_id = 'ORDER_MSP_001';

DELETE FROM olist_orders_dataset
WHERE order_id = 'ORDER_MSP_001';

DELETE FROM olist_customers_dataset
WHERE customer_id = 'CUST_MSP_001';
GO

USE olist_store;
GO

DECLARE @high_val_rows INT;

BEGIN TRANSACTION BatchPaymentUpdate;

UPDATE olist_order_payments_dataset
SET payment_installments = 1
WHERE payment_value < 100
AND payment_type = 'boleto';

PRINT 'Phase 1 done: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows updated.';

SAVE TRANSACTION SP_Phase1Done;

UPDATE olist_order_payments_dataset
SET payment_installments = 12
WHERE payment_value > 800
AND payment_type = 'credit_card';

SET @high_val_rows = @@ROWCOUNT;

IF @high_val_rows > 10000
BEGIN
    ROLLBACK TRANSACTION SP_Phase1Done;
    PRINT 'Phase 2 rolled back — too many rows: ' + CAST(@high_val_rows AS VARCHAR);
END
ELSE
    PRINT 'Phase 2 accepted: ' + CAST(@high_val_rows AS VARCHAR) + ' rows updated.';

ROLLBACK TRANSACTION BatchPaymentUpdate;
PRINT 'Demo rollback — no permanent changes.';
GO

USE olist_store;
GO

DECLARE @upd_order_id VARCHAR(50);

SELECT TOP 1 @upd_order_id = order_id
FROM olist_orders_dataset
WHERE order_status = 'processing';

BEGIN TRANSACTION OrderAdvancement;

UPDATE olist_orders_dataset
SET order_status = 'shipped'
WHERE order_id = @upd_order_id;

SAVE TRANSACTION SP_Shipped;
PRINT 'Stage 1: Order marked shipped.';

UPDATE olist_orders_dataset
SET order_delivered_carrier_date = GETDATE()
WHERE order_id = @upd_order_id;

SAVE TRANSACTION SP_CarrierDate;
PRINT 'Stage 2: Carrier date recorded.';

UPDATE olist_orders_dataset
SET order_delivered_customer_date = GETDATE()
WHERE order_id = @upd_order_id;

PRINT 'Stage 3: Customer delivery date set.';

ROLLBACK TRANSACTION OrderAdvancement;
PRINT 'Demo rollback — no changes saved.';
GO

USE olist_store;
GO

BEGIN TRY
    DECLARE @result INT = 100 / 0;
    PRINT 'This line will never execute.';
END TRY
BEGIN CATCH
    PRINT '--- ERROR CAUGHT ---';
    PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Message : ' + ERROR_MESSAGE();
    PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
    PRINT 'Error State   : ' + CAST(ERROR_STATE() AS VARCHAR);
    PRINT 'Error Line    : ' + CAST(ERROR_LINE() AS VARCHAR);
END CATCH
GO

USE olist_store;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO olist_customers_dataset
    (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
    VALUES ('CUST_TC_001','UNQ_TC_001','80010','curitiba','PR');

    PRINT 'First insert succeeded.';

    INSERT INTO olist_customers_dataset
    (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
    VALUES ('CUST_TC_001','UNQ_TC_001','80010','curitiba','PR');

    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;

    PRINT '--- TRANSACTION ROLLED BACK ---';
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;
GO

USE olist_store;
GO

DECLARE @payment_value DECIMAL(10,2) = -50.00,
        @msg VARCHAR(100);

BEGIN TRY
    IF @payment_value <= 0
    BEGIN
        SET @msg = 'Invalid payment value: ' + CAST(@payment_value AS VARCHAR(20))
                 + '. Must be greater than zero.';
        RAISERROR(@msg, 16, 1);
    END

    PRINT 'Payment value is valid.';
END TRY
BEGIN CATCH
    PRINT '--- RAISERROR CAUGHT ---';
    PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Message : ' + ERROR_MESSAGE();
    PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
END CATCH;
GO

USE olist_store;
GO

DECLARE @order_status VARCHAR(20) = 'invalid_status';

BEGIN TRY
    IF @order_status NOT IN
    ('pending','approved','processing','shipped','delivered','canceled','unavailable')
    BEGIN
        THROW 50001,
        'Invalid order status. Allowed: pending, approved, processing, shipped, delivered, canceled.',
        1;
    END

    PRINT 'Order status is valid.';
END TRY
BEGIN CATCH
    PRINT '--- THROW CAUGHT ---';
    PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Error Message : ' + ERROR_MESSAGE();
    PRINT 'Error State   : ' + CAST(ERROR_STATE() AS VARCHAR);
END CATCH;
GO

USE olist_store;
GO

BEGIN TRY
    DECLARE @bad_cast INT = CAST('NOT_A_NUMBER' AS INT);
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error_number,
           ERROR_MESSAGE() AS error_message,
           ERROR_SEVERITY() AS error_severity,
           ERROR_STATE() AS error_state,
           ERROR_LINE() AS error_line,
           ERROR_PROCEDURE() AS error_procedure;
END CATCH;
GO

USE olist_store;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO olist_orders_dataset
    (order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date)
    VALUES
    ('ORD_RETHROW_001','CUSTOMER_DOES_NOT_EXIST_XYZ','pending',
     GETDATE(),DATEADD(DAY,7,GETDATE()));

    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;

    PRINT 'LOG: Error at line ' + CAST(ERROR_LINE() AS VARCHAR)
          + ' — ' + ERROR_MESSAGE();

    THROW;
END CATCH;
GO

USE olist_store;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    PRINT 'OUTER TRY: Transaction started.';

    BEGIN TRY
        INSERT INTO olist_customers_dataset
        (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
        VALUES ('CUST_NESTED_001','UNQ_NESTED_001','69050','manaus','AM');

        PRINT 'INNER TRY: Customer inserted.';
    END TRY
    BEGIN CATCH
        PRINT 'INNER CATCH: Customer insert failed — ' + ERROR_MESSAGE();
    END CATCH

    INSERT INTO olist_orders_dataset
    (order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date)
    VALUES
    ('ORD_NESTED_001',
     (SELECT TOP 1 customer_id FROM olist_customers_dataset),
     'pending',GETDATE(),DATEADD(DAY,7,GETDATE()));

    PRINT 'OUTER TRY: Order inserted.';

    COMMIT;
    PRINT 'OUTER TRY: Transaction committed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    PRINT 'OUTER CATCH: ' + ERROR_MESSAGE();
END CATCH;
GO

DELETE FROM olist_orders_dataset
WHERE order_id = 'ORD_NESTED_001';

DELETE FROM olist_customers_dataset
WHERE customer_id = 'CUST_NESTED_001';
GO

USE olist_store;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT XACT_STATE() AS xact_state_inside;

    DECLARE @x TINYINT = 200;
    SET @x = @x + 200;

    COMMIT;
END TRY
BEGIN CATCH
    IF XACT_STATE() = -1
    BEGIN
        PRINT 'Transaction is DOOMED — must rollback.';
        ROLLBACK;
    END
    ELSE IF XACT_STATE() = 1
    BEGIN
        PRINT 'Transaction is active — rolling back.';
        ROLLBACK;
    END
    ELSE
        PRINT 'No active transaction.';

    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;
GO

USE olist_store;
GO

IF OBJECT_ID('tempdb..#ErrorLog') IS NOT NULL DROP TABLE #ErrorLog;

CREATE TABLE #ErrorLog (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    batch_name VARCHAR(100),
    error_number INT,
    error_message NVARCHAR(4000),
    error_severity INT,
    error_state INT,
    error_line INT,
    logged_at DATETIME DEFAULT GETDATE()
);

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @bad_value INT = CAST('OLIST_NOT_A_NUMBER' AS INT);

    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;

    INSERT INTO #ErrorLog
    (batch_name, error_number, error_message, error_severity, error_state, error_line)
    VALUES
    ('Q9.23 Demo',ERROR_NUMBER(),ERROR_MESSAGE(),
     ERROR_SEVERITY(),ERROR_STATE(),ERROR_LINE());

    PRINT 'Error logged to #ErrorLog.';
END CATCH;

SELECT * FROM #ErrorLog;
GO

USE olist_store
GO

BEGIN TRY
    BEGIN TRANSACTION PlaceNewOrder

    DECLARE @new_order_id VARCHAR(50) = 'ORD_NEW_0001',
            @cust_id VARCHAR(50),
            @prod_id VARCHAR(50),
            @sell_id VARCHAR(50)

    SELECT TOP 1 @cust_id = customer_id
    FROM olist_customers_dataset
    ORDER BY NEWID()

    SELECT TOP 1 @prod_id = product_id
    FROM olist_products_dataset
    ORDER BY NEWID()

    SELECT TOP 1 @sell_id = seller_id
    FROM olist_sellers_dataset
    ORDER BY NEWID()

    INSERT INTO olist_orders_dataset
    (order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date)
    VALUES
    (@new_order_id, @cust_id, 'pending', GETDATE(), DATEADD(DAY, 7, GETDATE()))

    SAVE TRANSACTION SP_OrderHeader
    PRINT 'Step 1: Order created.'

    INSERT INTO olist_order_items_dataset
    (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
    VALUES
    (@new_order_id, 1, @prod_id, @sell_id, DATEADD(DAY, 5, GETDATE()), 149.90, 15.00)

    PRINT 'Step 2: Item added.'

    INSERT INTO olist_order_payments_dataset
    (order_id, payment_sequential, payment_type, payment_installments, payment_value)
    VALUES
    (@new_order_id, 1, 'credit_card', 3, 164.90)

    PRINT 'Step 3: Payment recorded.'

    COMMIT TRANSACTION PlaceNewOrder

    PRINT '=== ORDER PLACED: ' + @new_order_id + ' ==='

    SELECT o.order_id, o.order_status,
           i.price, i.freight_value,
           p.payment_type, p.payment_value
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset i ON o.order_id = i.order_id
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_id = @new_order_id

    DELETE FROM olist_order_payments_dataset
    WHERE order_id = @new_order_id

    DELETE FROM olist_order_items_dataset
    WHERE order_id = @new_order_id

    DELETE FROM olist_orders_dataset
    WHERE order_id = @new_order_id

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT 'Order placement FAILED: ' + ERROR_MESSAGE()
END CATCH
GO

USE olist_store
GO

DECLARE @order_id VARCHAR(50),
        @current_status VARCHAR(20),
        @new_status VARCHAR(20) = 'shipped'

SELECT TOP 1
    @order_id = order_id,
    @current_status = order_status
FROM olist_orders_dataset
WHERE order_status = 'processing'

BEGIN TRY
    BEGIN TRANSACTION UpdateOrderStatus

    IF @order_id IS NULL
        THROW 50010, 'No processing orders found.', 1

    IF NOT (
        (@current_status = 'processing' AND @new_status = 'shipped') OR
        (@current_status = 'pending' AND @new_status = 'processing') OR
        (@current_status = 'shipped' AND @new_status = 'delivered') OR
        (@current_status IN ('pending','processing','shipped') AND @new_status = 'canceled')
    )
    BEGIN
        THROW 50011, 'Invalid status transition. Orders can only move forward.', 1
    END

    UPDATE olist_orders_dataset
    SET order_status = @new_status
    WHERE order_id = @order_id

    COMMIT TRANSACTION UpdateOrderStatus

    PRINT 'Order ' + @order_id + ': [' + @current_status +
          '] to [' + @new_status + '] — done.'

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT 'Status update failed: ' + ERROR_MESSAGE()
END CATCH
GO

USE olist_store
GO

DECLARE @target_order VARCHAR(50),
        @item_total DECIMAL(10,2),
        @freight_total DECIMAL(10,2),
        @payment_total DECIMAL(10,2)

SELECT TOP 1 @target_order = o.order_id
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i ON o.order_id = i.order_id
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'

BEGIN TRY
    BEGIN TRANSACTION PaymentCorrection

    IF @target_order IS NULL
        THROW 50020, 'No delivered orders found.', 1

    SELECT @item_total = SUM(price),
           @freight_total = SUM(freight_value)
    FROM olist_order_items_dataset
    WHERE order_id = @target_order

    SELECT @payment_total = SUM(payment_value)
    FROM olist_order_payments_dataset
    WHERE order_id = @target_order

    PRINT 'Order         : ' + @target_order
    PRINT 'Expected Total: R$ ' + CAST(@item_total + @freight_total AS VARCHAR)
    PRINT 'Payment Total : R$ ' + CAST(@payment_total AS VARCHAR)

    IF ABS(@payment_total - (@item_total + @freight_total))
       / NULLIF(@item_total + @freight_total, 0) > 0.10
        THROW 50021, 'Payment mismatch exceeds 10% tolerance.', 1

    COMMIT TRANSACTION PaymentCorrection
    PRINT 'Payment verified successfully.'

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT 'Payment check failed: ' + ERROR_MESSAGE()
END CATCH
GO

USE olist_store
GO

DECLARE @cancel_order VARCHAR(50)

SELECT TOP 1 @cancel_order = o.order_id
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE o.order_status = 'processing'

BEGIN TRY
    BEGIN TRANSACTION CancelOrder

    IF @cancel_order IS NULL
        THROW 50030, 'No processing orders found to cancel.', 1

    UPDATE olist_orders_dataset
    SET order_status = 'canceled'
    WHERE order_id = @cancel_order
      AND order_status = 'processing'

    IF @@ROWCOUNT = 0
        THROW 50031, 'Order not found or already canceled.', 1

    SAVE TRANSACTION SP_OrderCanceled
    PRINT 'Step 1: Order status set to canceled.'

    UPDATE olist_order_payments_dataset
    SET payment_value = 0.00,
        payment_type = 'voucher'
    WHERE order_id = @cancel_order

    PRINT 'Step 2: ' + CAST(@@ROWCOUNT AS VARCHAR)
        + ' payment(s) marked for refund.'

    COMMIT TRANSACTION CancelOrder
    PRINT 'Order ' + @cancel_order + ' canceled successfully.'

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT 'Cancellation failed: ' + ERROR_MESSAGE()
END CATCH
GO

USE olist_store
GO

DECLARE @cutoff_date DATETIME = DATEADD(DAY,-30,GETDATE()),
        @rows_canceled INT

BEGIN TRY
    BEGIN TRANSACTION BulkCancelStale

    PRINT 'Canceling orders older than: ' + CONVERT(VARCHAR,@cutoff_date,120)

    SAVE TRANSACTION SP_BeforeBulkCancel

    UPDATE olist_orders_dataset
    SET order_status = 'canceled'
    WHERE order_status = 'pending'
      AND order_purchase_timestamp < @cutoff_date

    SET @rows_canceled = @@ROWCOUNT
    PRINT 'Rows matched: ' + CAST(@rows_canceled AS VARCHAR)

    IF @rows_canceled > 5000
    BEGIN
        ROLLBACK TRANSACTION SP_BeforeBulkCancel;
        THROW 50040,'Exceeded safety limit of 5000 orders. Aborted.',1;
    END

    ROLLBACK TRANSACTION BulkCancelStale
    PRINT 'Demo rollback — no real data changed.'

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT 'Bulk cancel failed: ' + ERROR_MESSAGE()
END CATCH
GO

USE olist_store
GO

IF OBJECT_ID('tempdb..#PriceAudit') IS NOT NULL
    DROP TABLE #PriceAudit

CREATE TABLE #PriceAudit (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    audited_at DATETIME DEFAULT GETDATE()
)

BEGIN TRY
    BEGIN TRANSACTION PriceIncrease

    UPDATE oi
    SET price = ROUND(price * 1.05,2)
    OUTPUT
        deleted.order_id,
        deleted.product_id,
        deleted.price,
        inserted.price
    INTO #PriceAudit (order_id, product_id, old_price, new_price)
    FROM olist_order_items_dataset oi
    JOIN olist_products_dataset p
        ON oi.product_id = p.product_id
    WHERE p.product_category_name = 'cama_mesa_banho'
      AND oi.price BETWEEN 10 AND 500

    DECLARE @rows INT = @@ROWCOUNT

    PRINT 'Audit log created: ' + CAST(@rows AS VARCHAR) + ' rows.'
    SAVE TRANSACTION SP_AuditLogged
    PRINT 'Price increase applied: ' + CAST(@rows AS VARCHAR) + ' rows.'

    IF EXISTS (
        SELECT 1
        FROM olist_order_items_dataset
        WHERE price < 0
    )
    BEGIN
        THROW 50050, 'Negative price detected. Rolling back.', 1;
    END

    ROLLBACK TRANSACTION PriceIncrease
    PRINT 'Demo rollback applied.'

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT 'Price update failed: ' + ERROR_MESSAGE()
END CATCH

SELECT *
FROM #PriceAudit
ORDER BY old_price DESC
GO

USE olist_store
GO

DECLARE @old_seller VARCHAR(50),
        @new_seller VARCHAR(50)

SELECT TOP 1 @old_seller = seller_id
FROM olist_order_items_dataset
GROUP BY seller_id
HAVING COUNT(*) BETWEEN 5 AND 50
ORDER BY NEWID()

SELECT TOP 1 @new_seller = seller_id
FROM olist_sellers_dataset
WHERE seller_id <> @old_seller

BEGIN TRY
    BEGIN TRANSACTION SellerDeactivation

    IF @old_seller IS NULL OR @new_seller IS NULL
        THROW 50060, 'Could not find old or new seller.', 1;

    PRINT 'Deactivating : ' + @old_seller
    PRINT 'Replacing with: ' + @new_seller

    SAVE TRANSACTION SP_PreReassignment

    UPDATE oi
    SET oi.seller_id = @new_seller
    FROM olist_order_items_dataset oi
    JOIN olist_orders_dataset o ON oi.order_id = o.order_id
    WHERE oi.seller_id = @old_seller
      AND o.order_status IN ('pending','approved','processing','shipped')

    PRINT 'Reassigned: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' items.'

    ROLLBACK TRANSACTION SellerDeactivation
    PRINT 'Demo rollback — seller data unchanged.'

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT 'Seller deactivation failed: ' + ERROR_MESSAGE()
END CATCH
GO

USE olist_store
GO

DECLARE @suspect_order VARCHAR(50),
        @suspect_value DECIMAL(10,2),
        @suspect_inst INT

SELECT TOP 1
    @suspect_order = order_id,
    @suspect_value = payment_value,
    @suspect_inst = payment_installments
FROM olist_order_payments_dataset
WHERE payment_installments >= 5
  AND payment_value >= 500
ORDER BY payment_value DESC

BEGIN TRY
    BEGIN TRANSACTION FraudCheck

    IF @suspect_order IS NULL
    BEGIN
        PRINT 'No suspicious orders found.'
        ROLLBACK TRANSACTION FraudCheck
        RETURN
    END

    PRINT 'Checking order : ' + @suspect_order
    PRINT 'Payment Value  : R$' + CAST(@suspect_value AS VARCHAR)
    PRINT 'Installments   : ' + CAST(@suspect_inst AS VARCHAR)

    IF @suspect_inst > 5 AND @suspect_value > 2000
    BEGIN
        THROW 50070,
        'FRAUD ALERT: Order blocked — exceeds both thresholds.',
        1;
    END

    PRINT 'Order passed fraud check.'

    COMMIT TRANSACTION FraudCheck
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT '!!! ' + ERROR_MESSAGE()
    PRINT '!!! Blocked Order: ' + ISNULL(@suspect_order,'N/A')
END CATCH
GO

USE olist_store
GO

BEGIN TRY
    BEGIN TRANSACTION OrderLifecycle

    DECLARE @lc_order VARCHAR(50) = 'ORD_LC_0001',
            @lc_cust VARCHAR(50),
            @lc_prod VARCHAR(50),
            @lc_sell VARCHAR(50)

    SELECT TOP 1 @lc_cust = customer_id
    FROM olist_customers_dataset
    ORDER BY NEWID()

    SELECT TOP 1 @lc_prod = product_id
    FROM olist_products_dataset
    ORDER BY NEWID()

    SELECT TOP 1 @lc_sell = seller_id
    FROM olist_sellers_dataset
    ORDER BY NEWID()

    INSERT INTO olist_orders_dataset
    (order_id, customer_id, order_status,
     order_purchase_timestamp, order_estimated_delivery_date)
    VALUES
    (@lc_order, @lc_cust, 'pending', GETDATE(), DATEADD(DAY,10,GETDATE()))

    SAVE TRANSACTION SP_Stage1
    PRINT '[Stage 1] Order placed.'

    UPDATE olist_orders_dataset
    SET order_status = 'approved',
        order_approved_at = GETDATE()
    WHERE order_id = @lc_order

    SAVE TRANSACTION SP_Stage2
    PRINT '[Stage 2] Order approved.'

    INSERT INTO olist_order_items_dataset
    (order_id, order_item_id, product_id, seller_id,
     shipping_limit_date, price, freight_value)
    VALUES
    (@lc_order,1,@lc_prod,@lc_sell,DATEADD(DAY,7,GETDATE()),299.90,22.00)

    SAVE TRANSACTION SP_Stage3
    PRINT '[Stage 3] Item added.'

    INSERT INTO olist_order_payments_dataset
    (order_id, payment_sequential, payment_type,
     payment_installments, payment_value)
    VALUES
    (@lc_order,1,'credit_card',6,321.90)

    SAVE TRANSACTION SP_Stage4
    PRINT '[Stage 4] Payment recorded.'

    UPDATE olist_orders_dataset
    SET order_status = 'shipped',
        order_delivered_carrier_date = GETDATE()
    WHERE order_id = @lc_order

    SAVE TRANSACTION SP_Stage5
    PRINT '[Stage 5] Order shipped.'

    UPDATE olist_orders_dataset
    SET order_status = 'delivered',
        order_delivered_customer_date = GETDATE()
    WHERE order_id = @lc_order

    PRINT '[Stage 6] Order delivered.'

    COMMIT TRANSACTION OrderLifecycle
    PRINT '=== ALL 6 STAGES COMPLETE ==='

    SELECT o.order_id, o.order_status, i.price, p.payment_value
    FROM olist_orders_dataset o
    LEFT JOIN olist_order_items_dataset i ON o.order_id = i.order_id
    LEFT JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_id = @lc_order

    DELETE FROM olist_order_payments_dataset
    WHERE order_id = @lc_order

    DELETE FROM olist_order_items_dataset
    WHERE order_id = @lc_order

    DELETE FROM olist_orders_dataset
    WHERE order_id = @lc_order

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    PRINT '=== LIFECYCLE FAILED ==='
    PRINT 'Error: ' + ERROR_MESSAGE()
END CATCH
GO

USE olist_store
GO

IF OBJECT_ID('tempdb..#BatchResults') IS NOT NULL
    DROP TABLE #BatchResults

CREATE TABLE #BatchResults (
    result_id INT IDENTITY(1,1),
    order_id VARCHAR(50),
    old_value DECIMAL(10,2),
    new_value DECIMAL(10,2),
    status VARCHAR(10),
    error_msg NVARCHAR(4000)
)

DECLARE @b_order VARCHAR(50),
        @b_val DECIMAL(10,2),
        @new_val DECIMAL(10,2)

DECLARE batch_cursor CURSOR FOR
SELECT TOP 10 order_id, payment_value
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card'
  AND payment_installments > 1
ORDER BY payment_value DESC

OPEN batch_cursor
FETCH NEXT FROM batch_cursor INTO @b_order, @b_val

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @new_val = ROUND(@b_val * 1.02,2)

    BEGIN TRY
        BEGIN TRANSACTION RowItem

        UPDATE olist_order_payments_dataset
        SET payment_value = @new_val
        WHERE order_id = @b_order
          AND payment_type = 'credit_card'

        INSERT INTO #BatchResults
        VALUES (@b_order,@b_val,@new_val,'SUCCESS',NULL)

        ROLLBACK TRANSACTION RowItem
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

        INSERT INTO #BatchResults
        VALUES (@b_order,@b_val,@new_val,'FAILED',ERROR_MESSAGE())
    END CATCH

    FETCH NEXT FROM batch_cursor INTO @b_order, @b_val
END

CLOSE batch_cursor
DEALLOCATE batch_cursor

SELECT result_id, order_id, old_value, new_value,
       new_value - old_value AS fee_applied,
       status, error_msg
FROM #BatchResults
ORDER BY status, result_id
GO

USE olist_store
GO

DELETE FROM olist_customers_dataset
WHERE customer_id IN (
'CUST_TEST_001','CUST_TEST_002','CUST_TEST_003',
'CUST_SP_001','CUST_SP_002','CUST_MSP_001',
'CUST_TC_001','CUST_NESTED_001'
)

DELETE FROM olist_orders_dataset
WHERE order_id IN (
'ORDER_TEST_001','ORDER_TEST_003','ORDER_MULTI_001',
'ORDER_SP_001','ORDER_MSP_001','ORD_NESTED_001',
'ORD_VER_001','ORD_VER_002','ORD_VER_003',
'ORD_NEW_0001','ORD_LC_0001'
)

GO
