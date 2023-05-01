USE [TSQLV6]
GO
/* Demo 1:  GREATEST / LEAST */
SELECT
    p.studentid,
    p.[Test ABC],
    p.[Test XYZ],
    GREATEST(p.[Test ABC], p.[Test XYZ]) AS HighestScore,
    LEAST(p.[Test ABC], p.[Test XYZ]) AS LowestScore
FROM Stats.Scores s
    PIVOT
    (
        SUM(score)
        FOR testid IN ([Test ABC], [Test XYZ])
    ) AS p;




/* Demo 2:  STRING_SPLIT (again) */
DECLARE
    @InputString NVARCHAR(4000) = N'123,456,789,Cat,Dog,Fish,782437,18.46,Something with a space.';

SELECT *
FROM
    STRING_SPLIT(@InputString, N',')
GO

--The enable_ordinal option was added in SQL Server 2022.
DECLARE
    @InputString NVARCHAR(4000) = N'123,456,789,Cat,Dog,Fish,782437,18.46,Something with a space.';

SELECT *
FROM
    STRING_SPLIT(@InputString, N',', 1)
GO




/* Demo 3:  DATE_BUCKET */
-- TSQLV6 from https://tsql.lucient.com/SampleDatabases/TSQLV6.zip
USE TSQLV6
GO
SELECT DATE_BUCKET(YEAR, 1, CAST('2022-12-01' AS DATE)) AS startofyear;
GO
-- Number of orders by month and year
SELECT
    orderyear,
    ordermonth,
    COUNT(*) AS numorders
FROM Sales.Orders
    CROSS APPLY (VALUES(YEAR(orderdate), MONTH(orderdate)))
        AS D(orderyear, ordermonth)
GROUP BY
    orderyear,
    ordermonth;
GO
-- Date bucket version
SELECT
    YEAR(yearmonthbucket) AS orderyear, 
    MONTH(yearmonthbucket) AS ordermonth, 
    COUNT(*) AS numorders
FROM Sales.Orders
    CROSS APPLY (VALUES(DATE_BUCKET(month, 1, orderdate)))
        AS D(yearmonthbucket)
GROUP BY
    yearmonthbucket;

-- Number of orders by week, weeks starting on Sundays
SELECT
    startofweek,
    COUNT(*) AS numorders
FROM Sales.Orders
    CROSS APPLY (VALUES(DATEADD(week,
        DATEDIFF(week, CAST('19000107' AS DATE), orderdate),
        CAST('19000107' AS DATE)))) AS D(startofweek)
GROUP BY
    startofweek;
GO
-- Date bucket version
SELECT
    startofweek,
    COUNT(*) AS numorders
FROM Sales.Orders
    CROSS APPLY (VALUES(DATE_BUCKET(week, 1, orderdate, CAST('19000107' AS DATE))))
        AS D(startofweek)
GROUP BY
    startofweek;
GO




/* Demo 4:  DATE_TRUNC */
CREATE TABLE #SomeTable
(
    CustomerID INT,
    CreateDateLTz DATETIME
);

INSERT INTO #SomeTable
(
    CustomerID,
    CreateDateLTz
)
VALUES
(1, '2015-06-11 19:23:06'),
(1, '2015-06-11 19:23:07'),
(1, '2015-06-11 14:23:06'),
(1, '2015-06-11 19:43:06'),
(1, '2015-06-11 19:59:59'),
(2, '2015-06-11 20:23:06'),
(2, '2015-06-11 22:23:06');

-- The pre-2022 option
SELECT
    st.CustomerID,
    DATEADD(HOUR, DATEDIFF(HOUR, 0, st.CreateDateLTz), 0) AS CreateDateLTzRoundedToHour,
    COUNT(1) AS RecordCount
FROM #SomeTable st
GROUP BY
    st.CustomerID,
    DATEADD(HOUR, DATEDIFF(HOUR, 0, st.CreateDateLTz), 0);

-- The 2022 option
SELECT
    st.CustomerID,
    DATETRUNC(HOUR, st.CreateDateLTz) AS CreateDateLTzRoundedToHour,
    COUNT(1) AS RecordCount
FROM #SomeTable st
GROUP BY
    st.CustomerID,
    DATETRUNC(HOUR, st.CreateDateLTz);

-- DATETRUNC() also supports other ranges
SELECT
    st.CustomerID,
    st.CreateDateLTz,
    DATETRUNC(HOUR, st.CreateDateLTz) AS CreateDateLTzRoundedToHour,
    DATETRUNC(MINUTE, st.CreateDateLTz) AS CreateDateLTzRoundedToMinute,
    DATETRUNC(MILLISECOND, st.CreateDateLTz) AS CreateDateLTzRoundedToMS,
    DATETRUNC(MONTH, st.CreateDateLTz) AS CreateDateLTzRoundedToMonth
FROM #SomeTable st;



/* Demo 5:  GENERATE_SERIES */
-- Generate a tally table on the fly.
SELECT *
FROM GENERATE_SERIES(1, 100);

-- You don't always need to move one at a time.
SELECT *
FROM GENERATE_SERIES(1, 100, 5);

SELECT *
FROM GENERATE_SERIES(96, 71, -5);

-- Works for decimal values as well.
SELECT *
FROM GENERATE_SERIES(0.3, 14.9, 0.6);

-- Make sure it doesn't fail on simple cases.
SELECT *
FROM GENERATE_SERIES(96, 71, 5);

SELECT *
FROM GENERATE_SERIES(96, 71, 0);




/* Demo 6:  WINDOW */
-- An example of a window function.
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

-- But what happens if we have a bunch of analytical functions
-- over the same window?
SELECT
    od.orderid AS OrderID,
    od.productid AS ProductID,
    od.qty * od.unitprice AS LineTotal,
    SUM(od.qty * od.unitprice) OVER
        (
            PARTITION BY od.orderid
            ORDER BY od.productid
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RunningTotal,
    AVG(od.qty * od.unitprice) OVER
        (
            PARTITION BY od.orderid
            ORDER BY od.productid
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS MovingAverage3,
    MIN(od.qty * od.unitprice) OVER
        (
            PARTITION BY od.orderid
            ORDER BY od.productid
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS Min3,
    MAX(od.qty * od.unitprice) OVER
        (
            PARTITION BY od.orderid
            ORDER BY od.productid
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS Max3,
    STDEV(od.qty * od.unitprice) OVER
        (
            PARTITION BY od.orderid
            ORDER BY od.productid
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS Stdev3
FROM Sales.OrderDetails od
WHERE
    od.orderid IN (10252, 10418)
ORDER BY
    OrderID,
    ProductID;
GO

-- Enter the WINDOW
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
    m3 AS (PARTITION BY od.orderid ORDER BY od.productid ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
    rowsToNow AS (PARTITION BY od.orderid ORDER BY od.productid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
ORDER BY
    OrderID,
    ProductID;
GO





/* Demo 6:  Windows which respect/ignore NULL */
SELECT
    o.orderid,
    o.shippeddate,
    LAG(o.shippeddate, 1) OVER (ORDER BY o.orderid) AS PriorShippedDate
FROM Sales.Orders o
WHERE
    o.empid = 6
ORDER BY
    o.orderid DESC;
GO

-- This is otherwise known as "last observation carried forward"
SELECT
    o.orderid,
    o.shippeddate,
    LAG(o.shippeddate, 1) OVER (ORDER BY o.orderid) AS PriorShippedDate,
	LAG(o.shippeddate, 1) IGNORE NULLS OVER (ORDER BY o.orderid ) AS PriorActualShippedDate
FROM Sales.Orders o
WHERE
    o.empid = 6
ORDER BY
    o.orderid DESC;
GO

-- Supported functions:  LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE()







/* Demo 7:  APPROX_PERCENTILE_CONT and APPROX_PERCENTILE_DISC */
USE TSQLV6
GO
SELECT
    o.empid,
    APPROX_PERCENTILE_CONT (0.25)
        WITHIN GROUP (ORDER BY freight ASC) AS LowerQuartile,
    APPROX_PERCENTILE_CONT (0.5)
        WITHIN GROUP (ORDER BY freight ASC) AS MedianFreight,
    APPROX_PERCENTILE_CONT (0.75)
        WITHIN GROUP (ORDER BY freight ASC) AS UpperQuartile,
    APPROX_PERCENTILE_CONT (0.95)
        WITHIN GROUP (ORDER BY freight ASC) AS Percentile95,
    APPROX_PERCENTILE_CONT (0.99)
        WITHIN GROUP (ORDER BY freight ASC) AS Percentile99
FROM Sales.Orders o
GROUP BY
    o.empid
ORDER BY
    o.empid;
GO




/* Demo 8:  IS [NOT] DISTINCT FROM */
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.requireddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
ORDER BY
    o.orderid DESC;

-- A simple example
DECLARE
    @InputShippedDate DATE = '2022-04-24';
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.requireddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.shippeddate = @InputShippedDate
ORDER BY
    o.orderid DESC;
GO

-- A simple example breaks down
DECLARE
    @InputShippedDate DATE = NULL;
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.requireddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.shippeddate = @InputShippedDate
ORDER BY
    o.orderid DESC;
GO

-- A simple example got a bit more complicated
DECLARE
    @InputShippedDate DATE = NULL;
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.requireddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND
    (
        o.shippeddate = @InputShippedDate
        OR o.shippeddate IS NULL AND @InputShippedDate IS NULL
    )
ORDER BY
    o.orderid DESC;
GO

-- Decomplicate things
DECLARE
    @InputShippedDate DATE = '2022-04-24';
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.requireddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.shippeddate IS NOT DISTINCT FROM @InputShippedDate
ORDER BY
    o.orderid DESC;
GO

DECLARE
    @InputShippedDate DATE = NULL;
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.requireddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.shippeddate IS NOT DISTINCT FROM @InputShippedDate
ORDER BY
    o.orderid DESC;
GO

-- IS DISTINCT FROM does a similar check for NULL and is the binary negation of IS NOT DISTINCT FROM.
DECLARE
    @InputShippedDate DATE = '2022-04-24';
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.requireddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.shippeddate IS DISTINCT FROM @InputShippedDate
ORDER BY
    o.orderid DESC;
GO

DECLARE
    @InputShippedDate DATE = NULL;
SELECT
    o.orderid,
    o.orderdate,
    o.shippeddate,
    o.requireddate,
    o.custid
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.shippeddate IS DISTINCT FROM @InputShippedDate
ORDER BY
    o.orderid DESC;
GO
