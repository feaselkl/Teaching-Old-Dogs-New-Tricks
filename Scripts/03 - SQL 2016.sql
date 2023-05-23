/* Demo 1:  CREATE OR ALTER */
USE [TSQLV6]
GO

CREATE OR ALTER PROCEDURE dbo.ExecuteSomething
(
@InputParameter INT
)
AS
    SELECT @InputParameter AS Result;
GO

EXEC dbo.ExecuteSomething @InputParameter = 42;
GO

CREATE OR ALTER PROCEDURE dbo.ExecuteSomething
(
@InputParameter NVARCHAR(50)
)
AS
    SELECT @InputParameter AS Result;
GO

EXEC dbo.ExecuteSomething @InputParameter = N'42';
GO



/* Demo 2:  DROP IF EXISTS */
DROP PROCEDURE IF EXISTS dbo.ExecuteSomething;
DROP TABLE IF EXISTS dbo.SomeMissingTable;
DROP VIEW IF EXISTS dbo.SomeMissingView;




/* Demo 3:  STRING_SPLIT() */
DECLARE
    @InputString NVARCHAR(4000) = N'123,456,789,Cat,Dog,Fish,782437,18.46,Something with a space.';

SELECT *
FROM
    STRING_SPLIT(@InputString, N',')
GO



/* Demo 4:  FORMATMESSAGE() */
-- Note that FORMATMESSAGE() does not handle dates!  Must convert to a string first.
SELECT
    FORMATMESSAGE('Employee %i received order %i on %s, going to %s, %s',
        o.empid, o.orderid, CONVERT(NVARCHAR, o.orderdate, 112), o.shipcity, o.shipcountry) AS msg
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.orderdate > '2022-01-01';
GO
