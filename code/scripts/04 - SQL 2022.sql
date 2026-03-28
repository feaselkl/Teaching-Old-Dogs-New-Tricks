USE [TSQLV6]
GO

/* Demo 1:  GREATEST() / LEAST() */
-- Uses dbo.WaterSample (created in code/data/TSQLV6.sql)
-- Find the highest and lowest test result for each sample.
SELECT
    ws.WaterSampleID,
    ws.BasinID,
    ws.SampleDateTime,
    ws.BrowningTest,
    ws.RichterTest,
    ws.KelvinTest,
    ws.HarrisTest,
    ws.PatelTest,
    GREATEST(ws.BrowningTest, ws.RichterTest, ws.KelvinTest, ws.HarrisTest, ws.PatelTest) AS HighestResult,
    LEAST(ws.BrowningTest, ws.RichterTest, ws.KelvinTest, ws.HarrisTest, ws.PatelTest) AS LowestResult
FROM dbo.WaterSample ws
ORDER BY
    ws.BasinID,
    ws.SampleDateTime;

-- Find the highest and lowest test result ever recorded per basin.
SELECT
    ws.BasinID,
    MAX(GREATEST(ws.BrowningTest, ws.RichterTest, ws.KelvinTest, ws.HarrisTest, ws.PatelTest)) AS HighestEverResult,
    MIN(LEAST(ws.BrowningTest, ws.RichterTest, ws.KelvinTest, ws.HarrisTest, ws.PatelTest)) AS LowestEverResult
FROM dbo.WaterSample ws
GROUP BY
    ws.BasinID
ORDER BY
    ws.BasinID;


/* Demo 2:  STRING_SPLIT() with enable_ordinal */
DECLARE
    @InputString NVARCHAR(4000) = N'123,456,789,Cat,Dog,Fish,782437,18.46,Something with a space.';

-- Without ordinal (available since 2016)
SELECT *
FROM STRING_SPLIT(@InputString, N',');

-- With ordinal (new in 2022) -- now you know the position of each element.
SELECT *
FROM STRING_SPLIT(@InputString, N',', 1);
GO


/* Demo 3:  DATE_BUCKET() */
SELECT DATE_BUCKET(YEAR, 1, CAST('2022-12-01' AS DATE)) AS StartOfYear;

-- Number of orders by month/year: pre-2022 approach
SELECT
    orderyear,
    ordermonth,
    COUNT(*) AS NumOrders
FROM Sales.Orders
    CROSS APPLY (VALUES(YEAR(orderdate), MONTH(orderdate)))
        AS D(orderyear, ordermonth)
GROUP BY
    orderyear,
    ordermonth
ORDER BY
    orderyear,
    ordermonth;

-- DATE_BUCKET version
SELECT
    YEAR(yearmonthbucket) AS OrderYear,
    MONTH(yearmonthbucket) AS OrderMonth,
    COUNT(*) AS NumOrders
FROM Sales.Orders
    CROSS APPLY (VALUES(DATE_BUCKET(MONTH, 1, orderdate)))
        AS D(yearmonthbucket)
GROUP BY
    yearmonthbucket
ORDER BY
    yearmonthbucket;

-- Orders by week (starting Sunday): pre-2022 approach
SELECT
    startofweek,
    COUNT(*) AS NumOrders
FROM Sales.Orders
    CROSS APPLY (VALUES(DATEADD(WEEK,
        DATEDIFF(WEEK, CAST('19000107' AS DATE), orderdate),
        CAST('19000107' AS DATE)))) AS D(startofweek)
GROUP BY
    startofweek
ORDER BY
    startofweek;

-- DATE_BUCKET version
SELECT
    startofweek,
    COUNT(*) AS NumOrders
FROM Sales.Orders
    CROSS APPLY (VALUES(DATE_BUCKET(WEEK, 1, orderdate, CAST('19000107' AS DATE))))
        AS D(startofweek)
GROUP BY
    startofweek
ORDER BY
    startofweek;
GO


/* Demo 4:  DATETRUNC() */
-- Uses dbo.WaterSample (created in code/data/TSQLV6.sql)

-- Pre-2022: the DATEADD/DATEDIFF truncation trick
SELECT
    DATEADD(HOUR, DATEDIFF(HOUR, 0, ws.SampleDateTime), 0) AS SampleHour,
    COUNT(1) AS SampleCount
FROM dbo.WaterSample ws
GROUP BY
    DATEADD(HOUR, DATEDIFF(HOUR, 0, ws.SampleDateTime), 0)
ORDER BY
    SampleHour;

-- 2022: DATETRUNC()
SELECT
    DATETRUNC(HOUR, ws.SampleDateTime) AS SampleHour,
    COUNT(1) AS SampleCount
FROM dbo.WaterSample ws
GROUP BY
    DATETRUNC(HOUR, ws.SampleDateTime)
ORDER BY
    SampleHour;

-- DATETRUNC supports many date parts.
SELECT
    ws.BasinID,
    ws.SampleDateTime,
    DATETRUNC(HOUR, ws.SampleDateTime) AS ToHour,
    DATETRUNC(MINUTE, ws.SampleDateTime) AS ToMinute,
    DATETRUNC(MILLISECOND, ws.SampleDateTime) AS ToMillisecond,
    DATETRUNC(MONTH, ws.SampleDateTime) AS ToMonth
FROM dbo.WaterSample ws
ORDER BY
    ws.BasinID,
    ws.SampleDateTime;
GO


/* Demo 5:  GENERATE_SERIES() */
-- Replaces tally tables and recursive CTEs for generating sequences.
SELECT * FROM GENERATE_SERIES(1, 100);

-- Custom step size
SELECT * FROM GENERATE_SERIES(1, 100, 5);

-- Negative steps
SELECT * FROM GENERATE_SERIES(96, 71, -5);

-- Decimal values
SELECT * FROM GENERATE_SERIES(0.3, 14.9, 0.6);

-- Step is in the wrong direction -- returns nothing.
SELECT * FROM GENERATE_SERIES(96, 71, 5);

-- Step is zero -- throws error.
SELECT * FROM GENERATE_SERIES(96, 71, 0);


/* Demo 6:  WINDOW clause */
-- Define named window frames once, reuse across multiple functions.

-- Without WINDOW: the same partition/order/rows clause repeated for each function.
SELECT
    od.orderid AS OrderID,
    od.productid AS ProductID,
    od.qty * od.unitprice AS LineTotal,
    SUM(od.qty * od.unitprice) OVER
        (PARTITION BY od.orderid ORDER BY od.productid
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal,
    AVG(od.qty * od.unitprice) OVER
        (PARTITION BY od.orderid ORDER BY od.productid
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAverage3,
    MIN(od.qty * od.unitprice) OVER
        (PARTITION BY od.orderid ORDER BY od.productid
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Min3,
    MAX(od.qty * od.unitprice) OVER
        (PARTITION BY od.orderid ORDER BY od.productid
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Max3,
    STDEV(od.qty * od.unitprice) OVER
        (PARTITION BY od.orderid ORDER BY od.productid
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Stdev3
FROM Sales.OrderDetails od
WHERE
    od.orderid IN (10252, 10418)
ORDER BY
    OrderID,
    ProductID;

-- With WINDOW: define once, reference by name.
-- Also neat: you can define a window that references another window.
SELECT
    od.orderid AS OrderID,
    od.productid AS ProductID,
    od.qty * od.unitprice AS LineTotal,
    SUM(od.qty * od.unitprice) OVER rowsToNow AS RunningTotal,
    AVG(od.qty * od.unitprice) OVER m3 AS MovingAverage3,
    MIN(od.qty * od.unitprice) OVER m3 AS Min3,
    MAX(od.qty * od.unitprice) OVER m3 AS Max3,
    STDEV(od.qty * od.unitprice) OVER m3 AS Stdev3
FROM Sales.OrderDetails od
WHERE
    od.orderid IN (10252, 10418)
WINDOW
    baseRows AS (PARTITION BY od.orderid ORDER BY od.productid),
    m3 AS (baseRows ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
    rowsToNow AS (baseRows ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
ORDER BY
    OrderID,
    ProductID;
GO


/* Demo 7:  IGNORE NULLS in window functions */
-- LAG() returns NULL when the prior row's value is NULL.
SELECT
    o.orderid,
    o.shippeddate,
    LAG(o.shippeddate, 1) OVER (ORDER BY o.orderid) AS PriorShippedDate
FROM Sales.Orders o
WHERE
    o.empid = 6
ORDER BY
    o.orderid DESC;

-- IGNORE NULLS skips NULLs -- "last observation carried forward."
SELECT
    o.orderid,
    o.shippeddate,
    LAG(o.shippeddate, 1) OVER (ORDER BY o.orderid) AS PriorShippedDate,
    LAG(o.shippeddate, 1) IGNORE NULLS OVER (ORDER BY o.orderid) AS PriorActualShippedDate
FROM Sales.Orders o
WHERE
    o.empid = 6
ORDER BY
    o.orderid DESC;
GO
-- Supported functions: LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE()


/* Demo 8:  APPROX_PERCENTILE_CONT() / APPROX_PERCENTILE_DISC() */
SELECT
    o.empid,
    APPROX_PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY freight ASC) AS LowerQuartile,
    APPROX_PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY freight ASC) AS MedianFreight,
    APPROX_PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY freight ASC) AS UpperQuartile,
    APPROX_PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY freight ASC) AS Percentile95,
    APPROX_PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY freight ASC) AS Percentile99
FROM Sales.Orders o
GROUP BY
    o.empid
ORDER BY
    o.empid;
GO


/* Demo 9:  IS [NOT] DISTINCT FROM */
-- NULL-safe equality comparison. Replaces the (col = @param OR col IS NULL AND @param IS NULL) pattern.

-- Setup: show orders for employee 6 (some have NULL shippeddate).
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
ORDER BY
    o.orderid DESC;
GO

-- Problem: = doesn't match NULLs.
DECLARE @InputShippedDate DATE = NULL;
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.shippeddate = @InputShippedDate  -- returns nothing!
ORDER BY
    o.orderid DESC;
GO

-- Pre-2022 workaround: clunky OR logic.
DECLARE @InputShippedDate DATE = NULL;
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND
    (
        o.shippeddate = @InputShippedDate
        OR (o.shippeddate IS NULL AND @InputShippedDate IS NULL)
    )
ORDER BY o.orderid DESC;
GO

-- 2022: IS NOT DISTINCT FROM handles both NULL and non-NULL correctly.
DECLARE @InputShippedDate DATE = NULL;
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.shippeddate IS NOT DISTINCT FROM @InputShippedDate
ORDER BY
    o.orderid DESC;
GO

-- Works with non-NULL values too.
DECLARE @InputShippedDate DATE = '2022-04-24';
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.shippeddate IS NOT DISTINCT FROM @InputShippedDate
ORDER BY
    o.orderid DESC;
GO
