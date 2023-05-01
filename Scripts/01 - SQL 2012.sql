/* Demo 1:  use DATE */
--Actually available in SQL Server 2008 and later.
SELECT
    DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETUTCDATE()));

SELECT
    CAST(GETUTCDATE() AS DATE);

--Casting to a DATE type is easier to read, easier to understand,
--and harder to get wrong.  Just make sure your calling code
--handles DATE types correctly!



/* Demo 2:  use CONCAT */
SELECT
    'This is a string.  ' +
    ISNULL(NULL, '') +
    CAST(12 AS VARCHAR(50)) +
    '   .....   ' +
    CAST(31.884 AS VARCHAR(50)) +
    'Some other string.  ';

SELECT
    CONCAT
    (
        'This is a string.  ',
        NULL,
        12,
        '   .....   ',
        31.884,
        'Some other string.  '
    );

--CONCAT takes care of NULL values, converting numeric values,
--and several other string concatenation problems.



/* Demo 3:  Running Totals */
--REQUIRES SQL Server 2012 or later!
USE [TSQLV6]
GO

--Query to show what we're dealing with:
SELECT
    o.orderid,
    o.custid,
    o.empid,
    o.orderdate,
    od.productid,
    od.unitprice,
    od.qty
FROM Sales.Orders o
    INNER JOIN Sales.OrderDetails od
        ON od.orderid = o.orderid
WHERE
    o.orderid IN (10252, 10418)
ORDER BY
    o.orderid,
    od.productid;

--Cursor version
CREATE TABLE #x
(
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    LineTotal MONEY NOT NULL,
    RunningTotal MONEY NULL
);
ALTER TABLE #x ADD CONSTRAINT [PK_x] PRIMARY KEY CLUSTERED(OrderID, ProductID);

INSERT INTO #x
(
    OrderID,
    ProductID,
    LineTotal
)
SELECT
    o.orderid,
    od.productid,
    od.unitprice * od.qty
FROM Sales.Orders o
    INNER JOIN Sales.OrderDetails od
        ON od.orderid = o.orderid
WHERE
    o.orderid IN (10252, 10418)
ORDER BY
    o.orderid,
    od.productid;

DECLARE
    @CurrentOrderID INT = 0,
    @OrderID INT,
    @ProductID INT,
    @LineTotal MONEY,
    @RunningTotal MONEY = 0;

DECLARE c CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY FOR
    SELECT
        OrderID,
        ProductID,
        Linetotal
    FROM #x
    ORDER BY
        OrderID,
        ProductID;

OPEN c;

FETCH c INTO @OrderID, @ProductID, @LineTotal;

WHILE (@@FETCH_STATUS = 0)
BEGIN
    IF (@CurrentOrderID <> @OrderID)
    BEGIN
        SET @RunningTotal = @LineTotal;
        SET @CurrentOrderID = @OrderID;
    END
    ELSE
    BEGIN
        SET @RunningTotal = @RunningTotal + @LineTotal;
    END

    UPDATE #x
    SET RunningTotal = @RunningTotal
    WHERE
        OrderID = @OrderID
        AND ProductID = @ProductID;

    FETCH c INTO @OrderID, @ProductID, @LineTotal;
END

CLOSE c;
DEALLOCATE c;

SELECT
    OrderID,
    ProductID,
    LineTotal,
    RunningTotal
FROM #x;

DROP TABLE #x;
GO


--Self-Join
SELECT
    od.orderid AS OrderID,
    od.productid AS ProductID,
    od.qty * od.unitprice AS LineTotal,
    SUM(od2.qty * od2.unitprice) AS RunningTotal
FROM Sales.OrderDetails od
    LEFT OUTER JOIN Sales.OrderDetails od2
        ON od.orderid = od2.orderid
        AND od2.productid <= od.productid
WHERE
    od.orderid IN (10252, 10418)
GROUP BY
    od.orderid,
    od.productid,
    od.qty * od.unitprice
ORDER BY
    OrderID,
    ProductID;


--SQL Server 2012 version:
SELECT
    od.orderid AS OrderID,
    od.productid AS ProductID,
    od.qty * od.unitprice AS LineTotal,
    SUM(od.qty * od.unitprice) OVER
        (
            PARTITION BY od.orderid
            ORDER BY od.productid
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RunningTotal
FROM Sales.OrderDetails od
WHERE
    od.orderid IN (10252, 10418)
ORDER BY
    OrderID,
    ProductID;
GO



/* Demo 4:  Other expanded window functions */
-- LAG() and LEAD()
SELECT
    o.orderid,
    o.orderdate,
    o.empid,
    LAG(o.orderid) OVER (PARTITION BY o.custid ORDER BY o.orderid ASC) AS PriorOrderID,
    LAG(o.orderid, 1) OVER (PARTITION BY o.custid ORDER BY o.orderid ASC) AS PriorOrderIDAgain,
    LAG(o.orderid, 2) OVER (PARTITION BY o.custid ORDER BY o.orderid ASC) AS TwoOrdersAgoOrderID,
    LEAD(o.orderid) OVER (PARTITION BY o.custid ORDER BY o.orderid ASC) AS NextOrderID,
    LEAD(o.orderid, 1) OVER (PARTITION BY o.custid ORDER BY o.orderid ASC) AS NextOrderIDAgain,
    LEAD(o.orderid, 2) OVER (PARTITION BY o.custid ORDER BY o.orderid ASC) AS TwoOrdersFromNowOrderID
FROM Sales.Orders o
ORDER BY
    o.custid,
    o.orderid DESC;

-- LAG() prior to 2012
SELECT
    o.orderid,
    o.orderdate,
    o.empid,
    p1.orderid AS PriorOrderID,
    p2.orderid AS TwoOrdersAgoOrderID
FROM Sales.Orders o
    OUTER APPLY
    (
        SELECT TOP(1)
            o2.orderid
        FROM Sales.Orders o2
        WHERE
            o2.custid = o.custid
            AND o2.orderid < o.orderid
        ORDER BY
            o2.orderid DESC
    ) p1
    OUTER APPLY
    (
        SELECT
            pi.orderid
        FROM
        (
            SELECT TOP(2)
                o2.orderid,
                ROW_NUMBER() OVER (PARTITION BY o.custid ORDER BY o.orderid DESC) AS rownum
            FROM Sales.Orders o2
            WHERE
                o2.custid = o.custid
                AND o2.orderid < o.orderid
            ORDER BY
                o2.orderid DESC
        ) pi
        WHERE
            pi.rownum = 2
    ) p2
ORDER BY
    o.custid,
    o.orderid DESC;



/* Demo 5:  TRY_*** */
SELECT CAST(12 AS DECIMAL(12,2)) AS ValidCast;
SELECT CAST('12' AS DECIMAL(12,2)) AS AnotherValidCast;
SELECT CAST('UH-OH' AS DECIMAL(12,2)) AS InvalidCast;

SELECT TRY_CAST('UH-OH' AS DECIMAL(12,2)) AS InvalidCastReturnsNull;
SELECT TRY_CONVERT(DECIMAL(12,2), 'UH-OH') AS InvalidConvertReturnsNull;

-- TRY_CAST() and TRY_CONVERT() are just as fast as CAST() and CONVERT()
-- but are NULL-safe.  TRY_PARSE() is much slower but does support neat functionality.

SELECT
    TRY_PARSE('01/13/2019' AS DATE USING 'en-us') AS January13US,
    TRY_PARSE('01/13/2019' AS DATE USING 'fr-fr') AS Smarch1FR;



/* Demo 6:  FETCH and OFFSET */
-- Our app wants to show pages of rows at a time.
-- A page should contain 10 rows.
-- Prior to 2012
DECLARE
    @PageSize INT = 10,
    @PageNumber INT = 4;

-- "Nested top" approach
-- Note that results come in backwards!
SELECT TOP(@PageSize)
    o.*
FROM (
        SELECT TOP(@PageSize * @PageNumber)
            o.orderid,
            o.custid,
            o.orderdate,
            o.shippeddate,
            DATEDIFF(DAY, o.orderdate, o.shippeddate) AS NumberOfDaysToShip
        FROM Sales.Orders o
        WHERE
            o.empid = 6
        ORDER BY
            o.orderid ASC
    ) o
ORDER BY
    o.orderid DESC;
GO

-- "Prior key" approach
-- Assumes the app knows where it wants to start
DECLARE
    @PriorKey INT = 10599,
    @PageSize INT = 10;

SELECT TOP(@PageSize)
    o.orderid,
    o.custid,
    o.orderdate,
    o.shippeddate,
    DATEDIFF(DAY, o.orderdate, o.shippeddate) AS NumberOfDaysToShip
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.orderid > @PriorKey
ORDER BY
    o.orderid ASC;
GO

-- SQL Server 2012 approach
DECLARE
    @PageSize INT = 10,
    @PageNumber INT = 4;

SELECT
    o.orderid,
    o.custid,
    o.orderdate,
    o.shippeddate,
    DATEDIFF(DAY, o.orderdate, o.shippeddate) AS NumberOfDaysToShip
FROM Sales.Orders o
WHERE
    o.empid = 6
ORDER BY
    o.orderid ASC
OFFSET ((@PageNumber-1) * @PageSize) ROWS
FETCH NEXT @PageSize ROWS ONLY;
GO


/* Demo 7:  sp_describe_first_result_set */
-- sp_describe_first_result_set helps out application developers a lot!
-- This is a view.  The operation also works on other ad hoc SQL calls and stored procedures.
EXEC sp_describe_first_result_set
    @tsql = N'SELECT * FROM Sales.CustOrders;'
-- You can also execute this as a dynamic management function.
SELECT
    d.*
FROM sys.dm_exec_describe_first_result_set('SELECT * FROM Sales.CustOrders', NULL, 0) d;
GO



/* Demo 8:  Execute with result sets */
-- Start by creating a stored procedure.
IF (OBJECT_ID('dbo.Orders_GetOrdersByEmployee') IS NOT NULL)
BEGIN
    DROP PROCEDURE dbo.Orders_GetOrdersByEmployee;
END
GO

CREATE PROCEDURE dbo.Orders_GetOrdersByEmployee
(
@empid INT
)
AS
BEGIN
    SELECT
        o.custid,
        o.empid,
        o.orderdate,
        o.shippeddate
    FROM Sales.Orders o
    WHERE
        o.empid = @empid
    ORDER BY
        o.orderid DESC;
END
GO
-- Force those database people to return what you expect in the app.
EXEC dbo.Orders_GetOrdersByEmployee
    @empid = 6
    WITH RESULT SETS
    (
        (custid INT,
        empid INT,
        orderdate DATETIME,
        shippeddate DATETIME)
    );
GO

-- What happens if expectations don't align?
EXEC dbo.Orders_GetOrdersByEmployee
    @empid = 6
    WITH RESULT SETS
    (
        (custid INT,
        empid INT,
        orderdate DATETIME)
    );
GO

-- We can also have multiple response sets.
ALTER PROCEDURE dbo.Orders_GetOrdersByEmployee
(
@empid INT
)
AS
BEGIN
    SELECT
        o.custid,
        o.empid,
        o.orderdate,
        o.shippeddate
    FROM Sales.Orders o
    WHERE
        o.empid = @empid
    ORDER BY
        o.orderid DESC;

    SELECT
        o.custid,
        o.empid,
        o.orderdate
    FROM Sales.Orders o
    WHERE
        o.empid = @empid
        AND o.shippeddate IS NULL
    ORDER BY
        o.orderid DESC;
END
GO

EXEC dbo.Orders_GetOrdersByEmployee
    @empid = 6
    WITH RESULT SETS
    (
        (custid INT,
        empid INT,
        orderdate DATETIME,
        shippeddate DATETIME),

        (custid INT,
        empid INT,
        orderdate DATETIME)
    );
GO
DROP PROCEDURE dbo.Orders_GetOrdersByEmployee;
GO
