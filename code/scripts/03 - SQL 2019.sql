USE [TSQLV6]
GO

/* Demo 1:  APPROX_COUNT_DISTINCT() */
-- Uses dbo.LargeTable (40M rows, created in code/data/TSQLV6.sql)
-- Compare exact vs approximate distinct counts.
SELECT
    COUNT(DISTINCT SomeIntColumn) AS UniqueValues
FROM dbo.LargeTable;

SELECT
    APPROX_COUNT_DISTINCT(SomeIntColumn) AS UniqueValues
FROM dbo.LargeTable;
GO


/* Demo 2:  Improved string truncation error (Msg 2628) */
-- Prior to 2019, truncation errors didn't tell you which column or value caused the problem.
CREATE TABLE #TestTable
(
    Id INT IDENTITY(1,1) NOT NULL,
    SomeString NVARCHAR(10) NOT NULL
);

-- This insert succeeds.
INSERT INTO #TestTable(SomeString)
VALUES ('Test1'), ('Test2'), ('Test3'), ('Test4');
GO

-- This insert fails -- and now the error message tells you which column and value.
INSERT INTO #TestTable(SomeString)
VALUES ('Test1'), ('Test2'), ('Test3 but this one is a bit too long for us'), ('Test4');
GO

-- Also works for updates.
UPDATE #TestTable
SET SomeString = N'This updated string would be too long'
WHERE Id = 4;
GO
