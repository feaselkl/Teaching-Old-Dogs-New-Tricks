USE [TSQLV6]
GO

/****************************************************
    SQL SERVER 2008
****************************************************/

/* Demo 1:  DATE data type */
-- The DATE type replaces the old DATEADD/DATEDIFF truncation trick.
SELECT
    DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETUTCDATE()));

SELECT
    CAST(GETUTCDATE() AS DATE);

-- Casting to a DATE type is easier to read, easier to understand,
-- and harder to get wrong.  Just make sure your calling code
-- handles DATE types correctly!



/****************************************************
    SQL SERVER 2012
****************************************************/

/* Demo 2:  CONCAT() */
-- Before CONCAT, we needed ISNULL() for NULLs and CAST() for non-string types.
SELECT
    'This is a string.  ' +
    ISNULL(NULL, '') +
    CAST(12 AS VARCHAR(50)) +
    '   .....   ' +
    CAST(31.884 AS VARCHAR(50)) +
    'Some other string.  ';

-- CONCAT handles NULLs and type conversion automatically.
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


/* Demo 3:  LAG() and LEAD() */
-- The 2012 approach: simple and readable.
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

-- The pre-2012 approach: OUTER APPLY with correlated subqueries.
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


/* Demo 4:  TRY_CAST() and TRY_CONVERT() */
SELECT CAST(12 AS DECIMAL(12,2)) AS ValidCast;
SELECT CAST('12' AS DECIMAL(12,2)) AS AnotherValidCast;
SELECT CAST('UH-OH' AS DECIMAL(12,2)) AS InvalidCast;

-- TRY_CAST() and TRY_CONVERT() return NULL instead of raising an error.
SELECT TRY_CAST('UH-OH' AS DECIMAL(12,2)) AS InvalidCastReturnsNull;
SELECT TRY_CONVERT(DECIMAL(12,2), 'UH-OH') AS InvalidConvertReturnsNull;

-- TRY_PARSE() is slower but supports culture-aware parsing.
SELECT
    TRY_PARSE('01/13/2019' AS DATE USING 'en-us') AS January13US,
    TRY_PARSE('01/13/2019' AS DATE USING 'fr-fr') AS Smarch1FR;


/****************************************************
    SQL SERVER 2014
****************************************************/

/* Demo 5:  Inline index definitions */
-- Define nonclustered indexes directly in the CREATE TABLE statement,
-- including filtered indexes and INCLUDE columns.
CREATE TABLE #TestTable
(
    TestID INT NOT NULL CONSTRAINT [PK_TestTable] PRIMARY KEY CLUSTERED,
    SomeID INT NOT NULL CONSTRAINT [DF_TestTable_SomeID] DEFAULT(0),
    SomeString NVARCHAR(72) NOT NULL,
    INDEX [IX_TestTable_SomeID] NONCLUSTERED(SomeID) INCLUDE (SomeString)
);
GO



/****************************************************
    SQL SERVER 2016
****************************************************/

/* Demo 6:  CREATE OR ALTER */
CREATE OR ALTER PROCEDURE dbo.ExecuteSomething
(
@InputParameter INT
)
AS
    SELECT @InputParameter AS Result;
GO

EXEC dbo.ExecuteSomething @InputParameter = 42;
GO

-- Change the parameter type without needing DROP IF EXISTS + CREATE.
CREATE OR ALTER PROCEDURE dbo.ExecuteSomething
(
@InputParameter NVARCHAR(50)
)
AS
    SELECT @InputParameter AS Result;
GO

EXEC dbo.ExecuteSomething @InputParameter = N'42';
GO


/* Demo 7:  DROP IF EXISTS */
DROP PROCEDURE IF EXISTS dbo.ExecuteSomething;
DROP FUNCTION IF EXISTS dbo.ExecuteSomethingFunctional;
DROP TABLE IF EXISTS dbo.SomeMissingTable;
DROP VIEW IF EXISTS dbo.SomeMissingView;


/* Demo 8:  STRING_SPLIT() */
DECLARE
    @InputString NVARCHAR(4000) = N'123,456,789,Cat,Dog,Fish,782437,18.46,Something with a space.';

SELECT *
FROM
    STRING_SPLIT(@InputString, N',')
GO


/* Demo 9:  FORMATMESSAGE() */
-- Note: FORMATMESSAGE() does not handle dates directly -- convert to string first.
SELECT
    FORMATMESSAGE('Employee %i received order %i on %s, going to %s, %s',
        o.empid, o.orderid, CONVERT(NVARCHAR, o.orderdate, 112), o.shipcity, o.shipcountry) AS msg
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.orderdate > '2022-01-01';
GO
