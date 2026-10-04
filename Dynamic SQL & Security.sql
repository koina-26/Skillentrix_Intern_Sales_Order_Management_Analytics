USE olist_store;
GO

DECLARE @SQL NVARCHAR(MAX) = 
    'SELECT COUNT(*) AS total_orders FROM olist_orders_dataset;';

EXEC(@SQL);

USE olist_store;
GO

DECLARE @TableName NVARCHAR(128) = 'olist_customers_dataset';
DECLARE @SQL NVARCHAR(MAX) = 'SELECT TOP 5 * FROM ' + QUOTENAME(@TableName);

EXEC(@SQL);

USE olist_store;
GO

DECLARE @SQL NVARCHAR(MAX) = N'
SELECT customer_id, customer_city, customer_state
FROM olist_customers_dataset
WHERE customer_state = @StateParam
ORDER BY customer_city;';

EXEC sp_executesql @SQL, N'@StateParam NVARCHAR(10)', @StateParam = 'SP';

USE olist_store;
GO

DECLARE @SQL NVARCHAR(MAX);
DECLARE @TotalCustomers INT;

SET @SQL = N'
SELECT @CountOut = COUNT(*)
FROM olist_customers_dataset
WHERE customer_state = @StateParam;';

EXEC sp_executesql
    @SQL,
    N'@StateParam NVARCHAR(10), @CountOut INT OUTPUT',
    @StateParam = 'RJ',
    @CountOut = @TotalCustomers OUTPUT;

SELECT 'RJ' AS state_filter, @TotalCustomers AS total_customers;

USE olist_store;
GO

DECLARE @SortColumn NVARCHAR(50) = 'customer_state';
DECLARE @SortDir NVARCHAR(4) = 'ASC';
DECLARE @SQL NVARCHAR(MAX);

IF @SortColumn NOT IN ('customer_city','customer_state','customer_zip_code_prefix')
BEGIN
    RAISERROR('Invalid sort column.',16,1);
    RETURN;
END

SET @SQL = N'
SELECT TOP 10 customer_id, customer_city, customer_state
FROM olist_customers_dataset
ORDER BY ' + QUOTENAME(@SortColumn) + ' ' + @SortDir;

EXEC sp_executesql @SQL;

USE olist_store;
GO

DECLARE @Columns NVARCHAR(500) = 
    'order_id, customer_id, order_status, order_purchase_timestamp';

DECLARE @SQL NVARCHAR(MAX) = N'
SELECT TOP 10 ' + @Columns + N'
FROM olist_orders_dataset
WHERE order_status = ''delivered''
ORDER BY order_purchase_timestamp DESC;';

EXEC sp_executesql @SQL;

USE olist_store;
GO

DECLARE @TableName NVARCHAR(128) = 'olist_order_items_dataset';
DECLARE @RowCount INT;
DECLARE @SQL NVARCHAR(MAX) =
    N'SELECT @RowCountOut = COUNT(*) FROM ' + QUOTENAME(@TableName);

EXEC sp_executesql
    @SQL,
    N'@RowCountOut INT OUTPUT',
    @RowCountOut = @RowCount OUTPUT;

SELECT @TableName AS table_name, @RowCount AS row_count;

USE olist_store;
GO

DECLARE @AggFunction NVARCHAR(10) = 'SUM';
DECLARE @SQL NVARCHAR(MAX);

IF @AggFunction NOT IN ('SUM','AVG','COUNT','MIN','MAX')
BEGIN
    RAISERROR('Invalid aggregate.',16,1);
    RETURN;
END

SET @SQL = N'
SELECT payment_type,
       ' + @AggFunction + N'(payment_value) AS result_value,
       COUNT(*) AS record_count
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY result_value DESC;';

EXEC sp_executesql @SQL;

USE olist_store;
GO

DECLARE @State NVARCHAR(10) = 'SP';
DECLARE @City NVARCHAR(100) = NULL;
DECLARE @SQL NVARCHAR(MAX) = N'
SELECT customer_id, customer_city, customer_state
FROM olist_customers_dataset
WHERE 1=1';

IF @State IS NOT NULL
    SET @SQL += N' AND customer_state = @StateParam';

IF @City IS NOT NULL
    SET @SQL += N' AND customer_city = @CityParam';

SET @SQL += N' ORDER BY customer_state, customer_city;';

EXEC sp_executesql
    @SQL,
    N'@StateParam NVARCHAR(10), @CityParam NVARCHAR(100)',
    @StateParam = @State,
    @CityParam = @City;


    USE olist_store;
GO

DECLARE @Keyword NVARCHAR(100) = 'health';
DECLARE @SearchKeyword NVARCHAR(100) = N'%' + @Keyword + N'%';
DECLARE @SQL NVARCHAR(MAX) = N'
SELECT product_id, product_category_name, product_weight_g
FROM olist_products_dataset
WHERE product_category_name LIKE @KeywordParam
ORDER BY product_category_name;';

EXEC sp_executesql
    @SQL,
    N'@KeywordParam NVARCHAR(100)',
    @KeywordParam = @SearchKeyword;

   USE olist_store;
GO

DECLARE @PaymentType NVARCHAR(50) = 'credit_card';
DECLARE @SQL NVARCHAR(MAX) = N'
SELECT TOP 20
    op.order_id,
    op.payment_type,
    op.payment_installments,
    op.payment_value
FROM olist_order_payments_dataset op
WHERE op.payment_type = @PayTypeParam
ORDER BY op.payment_value DESC;';

EXEC sp_executesql
    @SQL,
    N'@PayTypeParam NVARCHAR(50)',
    @PayTypeParam = @PaymentType;

    USE olist_store;
GO

DECLARE @Status NVARCHAR(30) = 'delivered';
DECLARE @PageNumber INT = 2;
DECLARE @PageSize INT = 10;

DECLARE @SQL NVARCHAR(MAX) = N'
SELECT order_id, customer_id, order_status, order_purchase_timestamp
FROM olist_orders_dataset
WHERE order_status = @StatusParam
ORDER BY order_purchase_timestamp DESC
OFFSET (@PageNum - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;';

EXEC sp_executesql
    @SQL,
    N'@StatusParam NVARCHAR(30), @PageNum INT, @PageSize INT',
    @StatusParam = @Status,
    @PageNum = @PageNumber,
    @PageSize = @PageSize;

    USE olist_store;
GO

DECLARE @SellerState NVARCHAR(10) = 'SP',
        @SellerCity NVARCHAR(100) = NULL,
        @SQL NVARCHAR(MAX) = N'
SELECT seller_id, seller_city, seller_state
FROM olist_sellers_dataset
WHERE 1=1';

IF @SellerState IS NOT NULL
    SET @SQL += N' AND seller_state = @StateParam';

IF @SellerCity IS NOT NULL
    SET @SQL += N' AND seller_city = @CityParam';

SET @SQL += N' ORDER BY seller_state, seller_city;';

EXEC sp_executesql @SQL,
    N'@StateParam NVARCHAR(10), @CityParam NVARCHAR(100)',
    @SellerState, @SellerCity;

    USE olist_store;
GO

DECLARE @TopN INT = 5,
        @SQL NVARCHAR(MAX) = N'
SELECT TOP (@TopNParam)
    p.product_category_name,
    SUM(oi.price) AS total_revenue,
    COUNT(oi.order_id) AS total_items_sold,
    AVG(oi.price) AS avg_item_price
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;';

EXEC sp_executesql
    @SQL,
    N'@TopNParam INT',
    @TopN;

    USE olist_store;
GO

DECLARE @State NVARCHAR(10) = 'SP';
DECLARE @MinRevenue DECIMAL(12,2) = 500.00;

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(op.payment_value) AS total_revenue,
    AVG(op.payment_value) AS avg_order_value,
    MIN(op.payment_value) AS min_payment,
    MAX(op.payment_value) AS max_payment
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
JOIN olist_order_payments_dataset op
    ON o.order_id = op.order_id
WHERE c.customer_state = @State
  AND op.payment_value >= @MinRevenue
  AND o.order_status = 'delivered'
GROUP BY c.customer_state;

-- Q10.17
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'olist_analyst')
    DROP LOGIN olist_analyst;

CREATE LOGIN olist_analyst
WITH PASSWORD = 'Olist@Secure#2024',
     CHECK_POLICY = ON,
     CHECK_EXPIRATION = OFF;
GO

USE olist_store;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'olist_analyst')
    DROP USER olist_analyst;

CREATE USER olist_analyst FOR LOGIN olist_analyst;
GO

-- Q10.19
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'olist_sales_mgr')
    CREATE LOGIN olist_sales_mgr WITH PASSWORD = 'Sales@Olist#2024', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'olist_data_analyst')
    CREATE LOGIN olist_data_analyst WITH PASSWORD = 'Analyst@Olist#2024', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'olist_viewer')
    CREATE LOGIN olist_viewer WITH PASSWORD = 'Viewer@Olist#2024', CHECK_POLICY = ON;
GO

USE olist_store;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'olist_sales_mgr')
    CREATE USER olist_sales_mgr FOR LOGIN olist_sales_mgr;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'olist_data_analyst')
    CREATE USER olist_data_analyst FOR LOGIN olist_data_analyst;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'olist_viewer')
    CREATE USER olist_viewer FOR LOGIN olist_viewer;
GO

-- Q10.20
USE olist_store;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_olist_reader')
    CREATE ROLE role_olist_reader;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_olist_analyst')
    CREATE ROLE role_olist_analyst;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_olist_dataentry')
    CREATE ROLE role_olist_dataentry;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_olist_manager')
    CREATE ROLE role_olist_manager;
GO

-- Q10.21
USE olist_store;
GO

ALTER ROLE role_olist_reader ADD MEMBER olist_viewer;

ALTER ROLE role_olist_analyst ADD MEMBER olist_data_analyst;
ALTER ROLE role_olist_reader ADD MEMBER olist_data_analyst;

ALTER ROLE role_olist_manager ADD MEMBER olist_sales_mgr;
GO

-- Q10.22
SELECT
    name AS login_name,
    type_desc AS login_type,
    is_disabled,
    create_date
FROM sys.server_principals
WHERE name LIKE 'olist%'
ORDER BY name;

USE olist_store;
GO

SELECT
    name AS user_name,
    type_desc AS user_type,
    create_date,
    default_schema_name
FROM sys.database_principals
WHERE name LIKE 'olist%'
ORDER BY name;

SELECT
    name AS role_name,
    type_desc
FROM sys.database_principals
WHERE type = 'R'
  AND name LIKE 'role_olist%'
ORDER BY name;

-- Q10.23
USE olist_store;
GO

GRANT SELECT ON olist_customers_dataset TO role_olist_reader;
GRANT SELECT ON olist_orders_dataset TO role_olist_reader;
GRANT SELECT ON olist_order_items_dataset TO role_olist_reader;
GRANT SELECT ON olist_order_payments_dataset TO role_olist_reader;
GRANT SELECT ON olist_products_dataset TO role_olist_reader;
GRANT SELECT ON olist_sellers_dataset TO role_olist_reader;
GO

-- Q10.24
USE olist_store;
GO

GRANT INSERT, UPDATE ON olist_orders_dataset TO role_olist_dataentry;
GRANT INSERT, UPDATE ON olist_order_items_dataset TO role_olist_dataentry;
GRANT INSERT, UPDATE ON olist_order_payments_dataset TO role_olist_dataentry;

GRANT SELECT ON olist_customers_dataset TO role_olist_dataentry;
GRANT SELECT ON olist_orders_dataset TO role_olist_dataentry;
GRANT SELECT ON olist_order_items_dataset TO role_olist_dataentry;
GRANT SELECT ON olist_order_payments_dataset TO role_olist_dataentry;
GRANT SELECT ON olist_products_dataset TO role_olist_dataentry;
GRANT SELECT ON olist_sellers_dataset TO role_olist_dataentry;
GO

-- Q10.25
USE olist_store;
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON olist_customers_dataset TO role_olist_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON olist_orders_dataset TO role_olist_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON olist_order_items_dataset TO role_olist_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON olist_order_payments_dataset TO role_olist_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON olist_products_dataset TO role_olist_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON olist_sellers_dataset TO role_olist_manager;
GO

-- Q10.26
USE olist_store;
GO

IF OBJECT_ID('usp_DynamicSalesReport', 'P') IS NOT NULL
    GRANT EXECUTE ON usp_DynamicSalesReport TO role_olist_analyst;

IF OBJECT_ID('usp_DynamicProductSearch', 'P') IS NOT NULL
    GRANT EXECUTE ON usp_DynamicProductSearch TO role_olist_analyst;

IF OBJECT_ID('usp_SecureDeleteOrder', 'P') IS NOT NULL
    GRANT EXECUTE ON usp_SecureDeleteOrder TO role_olist_manager;
GO

-- Q10.27
USE olist_store;
GO

DENY DELETE ON olist_customers_dataset TO role_olist_dataentry;
DENY DELETE ON olist_orders_dataset TO role_olist_dataentry;
DENY DELETE ON olist_order_items_dataset TO role_olist_dataentry;
DENY DELETE ON olist_order_payments_dataset TO role_olist_dataentry;
DENY DELETE ON olist_products_dataset TO role_olist_dataentry;
DENY DELETE ON olist_sellers_dataset TO role_olist_dataentry;

DENY INSERT ON olist_customers_dataset TO role_olist_dataentry;
DENY INSERT ON olist_products_dataset TO role_olist_dataentry;
DENY INSERT ON olist_sellers_dataset TO role_olist_dataentry;
GO

-- Q10.28
USE olist_store;
GO

DENY SELECT ON olist_order_payments_dataset (payment_value) TO role_olist_reader;
DENY SELECT ON olist_customers_dataset (customer_zip_code_prefix) TO role_olist_reader;
GO

-- Q10.29
USE olist_store;
GO

REVOKE UPDATE ON olist_order_payments_dataset FROM role_olist_dataentry;
GO

GRANT UPDATE ON olist_order_payments_dataset TO role_olist_dataentry;
GO

-- Q10.30
USE olist_store;
GO

SELECT
    pr.name AS principal_name,
    pr.type_desc AS principal_type,
    pe.permission_name,
    pe.state_desc AS permission_state,
    OBJECT_NAME(pe.major_id) AS object_name
FROM sys.database_permissions pe
JOIN sys.database_principals pr
    ON pe.grantee_principal_id = pr.principal_id
WHERE pe.major_id > 0
  AND (pr.name LIKE 'olist%' OR pr.name LIKE 'role_olist%')
ORDER BY pr.name, object_name, pe.permission_name;

-- Q10.31
USE olist_store;
GO

IF OBJECT_ID('usp_DynamicSalesReport', 'P') IS NOT NULL
    DROP PROCEDURE usp_DynamicSalesReport;
GO

CREATE PROCEDURE usp_DynamicSalesReport
    @State NVARCHAR(10) = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ParamDef NVARCHAR(500);

    SET @SQL = N'
        SELECT
            c.customer_state,
            COUNT(DISTINCT o.order_id) AS total_orders,
            SUM(op.payment_value) AS total_revenue,
            AVG(op.payment_value) AS avg_payment,
            MIN(op.payment_value) AS min_payment,
            MAX(op.payment_value) AS max_payment
        FROM olist_customers_dataset c
        JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
        JOIN olist_order_payments_dataset op ON o.order_id = op.order_id
        WHERE o.order_status = ''delivered''';

    IF @State IS NOT NULL
        SET @SQL += N' AND c.customer_state = @StateParam';

    IF @StartDate IS NOT NULL
        SET @SQL += N' AND CAST(o.order_purchase_timestamp AS DATE) >= @StartParam';

    IF @EndDate IS NOT NULL
        SET @SQL += N' AND CAST(o.order_purchase_timestamp AS DATE) <= @EndParam';

    SET @SQL += N'
        GROUP BY c.customer_state
        ORDER BY total_revenue DESC;';

    SET @ParamDef = N'@StateParam NVARCHAR(10), @StartParam DATE, @EndParam DATE';

    EXEC sp_executesql @SQL, @ParamDef,
        @StateParam = @State,
        @StartParam = @StartDate,
        @EndParam = @EndDate;
END;
GO

USE olist_store;
GO
EXEC usp_DynamicSalesReport;

USE olist_store;
GO
EXEC usp_DynamicSalesReport @State = 'SP';

USE olist_store;
GO
EXEC usp_DynamicSalesReport
    @State = 'SP',
    @StartDate = '2018-01-01',
    @EndDate = '2018-06-30';

    -- Q10.32
USE olist_store;
GO

IF OBJECT_ID('usp_DynamicProductSearch', 'P') IS NOT NULL
    DROP PROCEDURE usp_DynamicProductSearch;
GO

CREATE PROCEDURE usp_DynamicProductSearch
    @CategoryKeyword NVARCHAR(100) = NULL,
    @MinPrice DECIMAL(10,2) = NULL,
    @MaxPrice DECIMAL(10,2) = NULL,
    @TopN INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ParamDef NVARCHAR(500);
    DECLARE @Keyword NVARCHAR(100);

    SET @Keyword = N'%' + ISNULL(@CategoryKeyword, N'') + N'%';

    SET @SQL = N'
        SELECT TOP (@TopNParam)
            p.product_category_name,
            COUNT(oi.order_id) AS times_ordered,
            AVG(oi.price) AS avg_price,
            MIN(oi.price) AS min_price,
            MAX(oi.price) AS max_price,
            SUM(oi.price) AS total_revenue
        FROM olist_products_dataset p
        JOIN olist_order_items_dataset oi
            ON p.product_id = oi.product_id
        WHERE 1 = 1';

    IF @CategoryKeyword IS NOT NULL
        SET @SQL += N' AND p.product_category_name LIKE @KeywordParam';

    IF @MinPrice IS NOT NULL
        SET @SQL += N' AND oi.price >= @MinPriceParam';

    IF @MaxPrice IS NOT NULL
        SET @SQL += N' AND oi.price <= @MaxPriceParam';

    SET @SQL += N'
        GROUP BY p.product_category_name
        ORDER BY total_revenue DESC;';

    SET @ParamDef = N'@TopNParam INT, @KeywordParam NVARCHAR(100),
        @MinPriceParam DECIMAL(10,2), @MaxPriceParam DECIMAL(10,2)';

    EXEC sp_executesql @SQL, @ParamDef,
        @TopNParam = @TopN,
        @KeywordParam = @Keyword,
        @MinPriceParam = @MinPrice,
        @MaxPriceParam = @MaxPrice;
END;
GO

USE olist_store;
GO
EXEC usp_DynamicProductSearch @TopN = 10;

USE olist_store;
GO
EXEC usp_DynamicProductSearch @CategoryKeyword = 'health', @TopN = 5;

USE olist_store;
GO
EXEC usp_DynamicProductSearch @MinPrice = 50.00, @MaxPrice = 200.00, @TopN = 15;

-- Q10.33
USE olist_store;
GO

IF OBJECT_ID('usp_SecureDeleteOrder', 'P') IS NOT NULL
    DROP PROCEDURE usp_SecureDeleteOrder;
GO

CREATE PROCEDURE usp_SecureDeleteOrder
    @OrderID NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserName NVARCHAR(100) = SYSTEM_USER;
    DECLARE @IsManager INT = IS_ROLEMEMBER('role_olist_manager');
    DECLARE @OrderExists INT;

    IF @IsManager = 0 OR @IsManager IS NULL
    BEGIN
        RAISERROR('Access Denied: Only role_olist_manager members can delete orders. User: %s', 16, 1, @UserName);
        RETURN;
    END

    SELECT @OrderExists = COUNT(*)
    FROM olist_orders_dataset
    WHERE order_id = @OrderID;

    IF @OrderExists = 0
    BEGIN
        RAISERROR('Order not found: %s', 16, 1, @OrderID);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM olist_order_payments_dataset WHERE order_id = @OrderID;
        DELETE FROM olist_order_items_dataset WHERE order_id = @OrderID;
        DELETE FROM olist_orders_dataset WHERE order_id = @OrderID;

        COMMIT;
        PRINT 'Order [' + @OrderID + '] deleted successfully by ' + @UserName;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- Q10.34
USE olist_store;
GO

DECLARE @SQL NVARCHAR(MAX);
DECLARE @Year INT = 2018;

SET @SQL = N'
SELECT
    YEAR(o.order_purchase_timestamp) AS report_year,
    MONTH(o.order_purchase_timestamp) AS month_num,
    DATENAME(MONTH, o.order_purchase_timestamp) AS month_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(op.payment_value) AS total_revenue,
    AVG(op.payment_value) AS avg_order_value,
    MIN(op.payment_value) AS min_payment,
    MAX(op.payment_value) AS max_payment
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset op
    ON o.order_id = op.order_id
WHERE o.order_status = ''delivered''
  AND YEAR(o.order_purchase_timestamp) = @YearParam
GROUP BY
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp),
    DATENAME(MONTH, o.order_purchase_timestamp)
ORDER BY report_year, month_num;';

EXEC sp_executesql @SQL, N'@YearParam INT', @YearParam = @Year;
GO

-- Q10.35
USE olist_store;
GO

DECLARE @SQL NVARCHAR(MAX);
DECLARE @State NVARCHAR(10) = 'SP';
DECLARE @TopN INT = 10;

SET @SQL = N'
SELECT TOP (@TopNParam)
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.price) AS total_revenue,
    AVG(oi.price) AS avg_item_price,
    RANK() OVER (ORDER BY SUM(oi.price) DESC) AS revenue_rank
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi
    ON s.seller_id = oi.seller_id
JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE s.seller_state = @StateParam
  AND o.order_status = ''delivered''
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC;';

EXEC sp_executesql @SQL,
    N'@TopNParam INT, @StateParam NVARCHAR(10)',
    @TopNParam = @TopN,
    @StateParam = @State;
GO

-- Q10.36
USE olist_store;
GO

SELECT
    sp.name AS login_name,
    sp.type_desc AS login_type,
    sp.is_disabled,
    sp.create_date
FROM sys.server_principals sp
WHERE sp.name LIKE 'olist%'
ORDER BY sp.name;

SELECT
    dp.name AS user_name,
    dp.type_desc AS user_type,
    dp.create_date,
    dp.default_schema_name
FROM sys.database_principals dp
WHERE dp.name LIKE 'olist%'
ORDER BY dp.name;

SELECT
    name AS role_name,
    type_desc AS role_type,
    create_date
FROM sys.database_principals
WHERE type = 'R'
  AND name LIKE 'role_olist%'
ORDER BY name;

SELECT
    dp_role.name AS role_name,
    dp_mem.name AS member_name,
    dp_mem.type_desc AS member_type
FROM sys.database_role_members drm
JOIN sys.database_principals dp_role
    ON drm.role_principal_id = dp_role.principal_id
JOIN sys.database_principals dp_mem
    ON drm.member_principal_id = dp_mem.principal_id
WHERE dp_role.name LIKE 'role_olist%'
ORDER BY dp_role.name, dp_mem.name;

SELECT
    pr.name AS principal_name,
    pr.type_desc AS principal_type,
    pe.permission_name,
    pe.state_desc AS permission_state,
    OBJECT_NAME(pe.major_id) AS object_name
FROM sys.database_permissions pe
JOIN sys.database_principals pr
    ON pe.grantee_principal_id = pr.principal_id
WHERE pe.major_id > 0
  AND (pr.name LIKE 'olist%' OR pr.name LIKE 'role_olist%')
ORDER BY pr.name, object_name, pe.permission_name;
GO