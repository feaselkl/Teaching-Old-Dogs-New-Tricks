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



/* Demo 4:  JSON support */
-- Auto-formatting
SELECT
    o.custid,
    o.empid,
    o.orderdate,
    o.shippeddate
FROM Sales.Orders o
WHERE
    o.empid = 6
ORDER BY
    o.orderid DESC
FOR JSON AUTO;

-- Specific formatting
-- Note that nested elements need to be contiguous
-- Cannot have one group of Order. and then another group of Order.
SELECT
    o.custid AS [Order.CustomerID],
    o.orderdate AS [Order.Date],
    o.shippeddate AS [Order.ShippedDate],
    o.empid AS [Staff.EmployeeID]
FROM Sales.Orders o
WHERE
    o.empid = 6
ORDER BY
    o.orderid DESC
FOR JSON PATH, ROOT('Orders');

-- Convert JSON to SQL
DECLARE
    @SampleJson NVARCHAR(2048) = N'{
    "owner": null,
    "brand": "BMW",
    "year": 2020,
    "status": false,
    "color": [ "red", "white", "yellow" ],
    "Model": {
        "name": "BMW M4",
        "Fuel Type": "Petrol",
        "TransmissionType": "Automatic",
        "Turbo Charger": "true",
        "Number of Cylinder": 4
    }
}';
 
SELECT
    *
FROM OPENJSON(@SampleJson);
GO

DECLARE
    @SampleJson NVARCHAR(2048) = N'{
    "owner": null,
    "brand": "BMW",
    "year": 2020,
    "status": false,
    "color": [ "red", "white", "yellow" ],
    "Model": {
        "name": "BMW M4",
        "Fuel Type": "Petrol",
        "TransmissionType": "Automatic",
        "Turbo Charger": "true",
        "Number of Cylinder": 4
    }
}';
 
SELECT
    *
FROM OPENJSON(@SampleJson)
WITH
(
    Brand VARCHAR(100) '$.brand',
    ModelYear INT '$.year',
    ModelName VARCHAR(100) '$.Model.name',
    ColorList NVARCHAR(MAX) '$.color' AS JSON
)
    CROSS APPLY OPENJSON(ColorList)
    WITH
    (
        Color NVARCHAR(30) '$'
    );
GO



/* Demo 5:  FORMATMESSAGE() */
-- Note that FORMATMESSAGE() does not handle dates!  Must convert to a string first.
SELECT
    FORMATMESSAGE('Employee %i received order %i on %s, going to %s, %s',
        o.empid, o.orderid, CONVERT(NVARCHAR, o.orderdate, 112), o.shipcity, o.shipcountry) AS msg
FROM Sales.Orders o
WHERE
    o.empid = 6
    AND o.orderdate > '2022-01-01';
GO
