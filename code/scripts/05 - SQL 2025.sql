USE [TSQLV6]
GO

/* Demo 1:  Regular expressions -- REGEXP_LIKE() */
-- Pre-2025: LIKE and PATINDEX are limited.  Anything complex required CLR or app code.

-- Find orders shipped to cities that start with a vowel and end with a consonant.
-- LIKE can sort of do this, but it's ugly.
SELECT DISTINCT
    o.shipcity
FROM Sales.Orders o
WHERE
    o.shipcity LIKE '[AEIOU]%[^AEIOU]';

-- REGEXP_LIKE makes complex patterns readable.
-- The 'i' flag makes the match case-insensitive, matching LIKE's default collation behavior.
SELECT DISTINCT
    o.shipcity
FROM Sales.Orders o
WHERE
    REGEXP_LIKE(o.shipcity, '^[AEIOU].*[^AEIOU]$', 'i');
GO


/* Demo 2:  Regular expressions -- REGEXP_REPLACE() */
-- Pre-2025: cleaning up strings required nested REPLACE() calls.
DECLARE @messy NVARCHAR(200) = N'Order   shipped   to    123  Main   St';

-- Remove extra whitespace the old way.
SELECT REPLACE(REPLACE(REPLACE(@messy, '   ', ' '), '   ', ' '), '  ', ' ') AS OldWay;

-- REGEXP_REPLACE: one pass, any pattern.
SELECT REGEXP_REPLACE(@messy, '\s+', ' ') AS NewWay;
GO

-- Practical example: strip non-numeric characters from phone numbers.
DECLARE @phone NVARCHAR(50) = N'(555) 867-5309 ext. 42';

SELECT REGEXP_REPLACE(@phone, '[^0-9]', '') AS DigitsOnly;
GO


/* Demo 3:  Regular expressions -- REGEXP_SUBSTR() and REGEXP_COUNT() */
-- Pre-2025: extracting patterns from strings was painful with PATINDEX + SUBSTRING.

-- Extract the first numeric sequence from a string.
DECLARE @val NVARCHAR(100) = N'Order ABC-12345-XY was shipped at 2114 on the 19th of May';

SELECT
    REGEXP_SUBSTR(@val, '[0-9]+') AS FirstNumber,
    REGEXP_COUNT(@val, '[0-9]+') AS NumericSequenceCount;
GO

-- Practical example: extract email domains from a contact field.
DECLARE @contact NVARCHAR(200) = N'Contact: alice@contoso.com or bob@fabrikam.org';

SELECT
    REGEXP_SUBSTR(@contact, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}') AS FirstEmail;
GO


/* Demo 4:  || string concatenation operator */
-- Pre-2025: the + operator propagates NULLs.
SELECT
    'Hello' + ' ' + 'World' AS Concatenated,
    'Hello' + NULL + 'World' AS NullPropagated;

-- 2025: the || operator follows the ANSI standard...which still propagates NULLs.
SELECT
    'Hello' || ' ' || 'World' AS Concatenated,
    'Hello' || NULL || 'World' AS NullHandled;

-- Works with column data too.
SELECT
    o.orderid,
    o.shipcity || ', ' || o.shipcountry AS Destination
FROM Sales.Orders o
WHERE o.empid = 6;

-- Compound assignment operator ||= also works.
DECLARE @msg NVARCHAR(200) = N'Hello';
SET @msg ||= N' World';
SELECT @msg AS Result;
GO


/* Demo 5:  SUBSTRING() with optional length */
-- Pre-2025: getting a substring from a position to the end of the string
-- requires calculating the length.
DECLARE @val NVARCHAR(100) = N'Error: something went wrong';

SELECT
    SUBSTRING(@val, 8, LEN(@val) - 7) AS OldWay;

-- 2025: length parameter is now optional (ANSI compliance).
SELECT
    SUBSTRING(@val, 8) AS NewWay;
GO


/* Demo 6:  CURRENT_DATE */
-- Pre-2025: multiple ways to get today's date, none of them clean.
SELECT
    CAST(GETDATE() AS DATE) AS TodayCast,
    CAST(GETUTCDATE() AS DATE) AS TodayUtcCast,
    CONVERT(DATE, GETDATE()) AS TodayConvert;

-- 2025: ANSI standard CURRENT_DATE.
SELECT
    CURRENT_DATE AS Today;
GO


/* Demo 7:  PRODUCT() */
-- Pre-2025: the EXP(SUM(LOG())) trick for multiplying a set of values.
-- Only works for positive numbers and is hard to read.
SELECT
    od.orderid,
    EXP(SUM(LOG(od.unitprice))) AS ProductOfPrices_OldWay
FROM Sales.OrderDetails od
WHERE od.orderid IN (10252, 10418)
GROUP BY
    od.orderid;

-- 2025: PRODUCT() aggregate function.
SELECT
    od.orderid,
    PRODUCT(od.unitprice) AS ProductOfPrices
FROM Sales.OrderDetails od
WHERE od.orderid IN (10252, 10418)
GROUP BY
    od.orderid;
GO


/* Demo 8:  BASE64_ENCODE() / BASE64_DECODE() */
-- Pre-2025: base64 encoding required XML casting tricks.
DECLARE @data VARBINARY(100) = CAST('Hello, World!' AS VARBINARY(100));

-- Old way: XML-based workaround.
SELECT CAST('' AS XML).value('xs:base64Binary(sql:variable("@data"))', 'VARCHAR(200)') AS OldWayEncoded;

-- 2025: built-in functions.
SELECT BASE64_ENCODE(@data) AS Encoded;

-- Decoding the encoded value returns us to the original data.
SELECT
    s.StateProvinceCode,
    s.SalesTerritory,
    enc.Encoded,
    dec.DecodedBinary,
    str.DecodedString
FROM dbo.States s
    CROSS APPLY (SELECT CAST(s.SalesTerritory AS VARBINARY(100)) AS BinaryData) bin
    CROSS APPLY (SELECT BASE64_ENCODE(bin.BinaryData) AS Encoded) enc
    CROSS APPLY (SELECT BASE64_DECODE(enc.Encoded) AS DecodedBinary) dec
    CROSS APPLY (SELECT CAST(dec.DecodedBinary AS VARCHAR(100)) AS DecodedString) str;


/* Demo 9:  Fuzzy string matching */
-- Pre-2025: fuzzy matching required CLR assemblies or SSIS Fuzzy Lookup.
-- 2025 adds Levenshtein and Jaro-Winkler functions natively.

-- As of CU3, this is a preview feature.
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;

-- How similar are these state names?
DECLARE
    @SalesTerritoryToCompare VARCHAR(2) = 'Midwest';

SELECT
    s.StateProvinceCode,
    s.SalesTerritory,
    EDIT_DISTANCE(s.SalesTerritory, @SalesTerritoryToCompare) AS EditDistance,
    EDIT_DISTANCE_SIMILARITY(s.SalesTerritory, @SalesTerritoryToCompare) AS EditDistanceSimilarity,
    JARO_WINKLER_SIMILARITY(s.SalesTerritory, @SalesTerritoryToCompare) AS JaroWinklerSimilarity
FROM dbo.States s
WHERE
    EDIT_DISTANCE_SIMILARITY(s.SalesTerritory, @SalesTerritoryToCompare) > 10
ORDER BY
    EDIT_DISTANCE_SIMILARITY(s.SalesTerritory, @SalesTerritoryToCompare) DESC;
GO


/* Demo 10:  JSON_OBJECTAGG() / JSON_ARRAYAGG() */
-- Pre-2025: building JSON from rows required FOR JSON PATH subqueries.

-- Old way: FOR JSON PATH with a correlated subquery
SELECT DISTINCT
    o.empid,
    (
        SELECT
            o2.orderid
        FROM Sales.Orders o2
        WHERE
            o2.empid = o.empid
        FOR JSON PATH
    ) AS OrdersJson
FROM Sales.Orders o;

-- 2025: JSON_ARRAYAGG builds a JSON array directly.
SELECT
    o.empid,
    JSON_ARRAYAGG(o.orderid ORDER BY o.orderid) AS OrderIds
FROM Sales.Orders o
GROUP BY
    o.empid
ORDER BY
    o.empid;

-- JSON_OBJECTAGG builds a JSON object from key-value pairs.
SELECT
    JSON_OBJECTAGG(s.StateProvinceCode:s.SalesTerritory) AS StateTerritoryMap
FROM dbo.States s;
GO
