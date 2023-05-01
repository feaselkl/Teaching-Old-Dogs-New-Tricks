/* Demo 1:  APPROX_COUNT_DISTINCT */
DROP TABLE IF EXISTS dbo.LargeTable;
GO
CREATE TABLE dbo.LargeTable
(
    Id INT IDENTITY(1,1) NOT NULL,
    SomeIntColumn INT NOT NULL,
    CONSTRAINT [PK_LargeTable] PRIMARY KEY CLUSTERED(Id)
);
GO

INSERT INTO dbo.LargeTable
(
    SomeIntColumn
)
SELECT TOP(40000000)
    checksum(newid())
FROM sys.all_columns c1
    CROSS JOIN sys.all_columns c2
GO

SELECT
    COUNT(DISTINCT SomeIntColumn) AS UniqueValues
FROM dbo.LargeTable;

SELECT
    APPROX_COUNT_DISTINCT(SomeIntColumn) AS UniqueValues
FROM dbo.LargeTable;
GO




/* Demo 2:  The worst error message ever (Msg 2628) got a lot less worse. */
CREATE TABLE #TestTable
(
    Id INT IDENTITY(1,1) NOT NULL,
    SomeString NVARCHAR(10) NOT NULL
);

-- Everything looks great
INSERT INTO #TestTable
(
    SomeString
)
VALUES
    ('Test1'),
    ('Test2'),
    ('Test3'),
    ('Test4');
GO

-- Everything looks not so great
INSERT INTO #TestTable
(
    SomeString
)
VALUES
    ('Test1'),
    ('Test2'),
    ('Test3 but this one is a bit too long for us'),
    ('Test4');
GO

-- Also works for updates
UPDATE #TestTable
SET SomeString = N'This updated string would be too long'
WHERE
    Id = 4;
GO
