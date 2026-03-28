USE [TSQLV6]
GO

/* Demo 1:  CONCAT_WS() */
-- CONCAT_WS adds a separator between non-NULL values.
-- Compare to CONCAT, which has no separator support.
SELECT
    CONCAT
    (
        'This is a string.  ',
        NULL,
        12,
        '   .....   ',
        31.884,
        'Some other string.  '
    ),
    CONCAT_WS
    (
        ' ||| ',
        'This is a string.  ',
        NULL,
        12,
        '   .....   ',
        31.884,
        'Some other string.  '
    );


/* Demo 2:  TRIM() */
-- Replaces the LTRIM(RTRIM()) pattern and supports custom trim characters.

-- Spaces: LTRIM(RTRIM()) vs TRIM()
DECLARE
    @SpacesOnly NVARCHAR(100) = N'                  This is         my string.                  ';

SELECT
    DATALENGTH(@SpacesOnly) AS OriginalLength,
    DATALENGTH(LTRIM(RTRIM(@SpacesOnly))) AS OldWayLength,
    LTRIM(RTRIM(@SpacesOnly)) AS OldWay,
    DATALENGTH(TRIM(@SpacesOnly)) AS NewWayLength,
    TRIM(@SpacesOnly) AS NewWay;

-- Tabs: TRIM() alone won't catch them, but you can specify characters to trim.
DECLARE
    @WithTabs NVARCHAR(100) = N'			          This is         my string.              		  	  ';

SELECT
    DATALENGTH(@WithTabs) AS OriginalLength,
    DATALENGTH(TRIM(@WithTabs)) AS TrimAloneLength,
    TRIM(@WithTabs) AS TrimAlone,
    DATALENGTH(TRIM(' '+CHAR(9) FROM @WithTabs)) AS TrimWithTabLength,
    TRIM(' '+CHAR(9) FROM @WithTabs) AS TrimWithTab;

-- You can trim any characters, not just whitespace.
DECLARE
    @CustomChars NVARCHAR(100) = N'OKThis is the real string, OK?OK';

SELECT
    TRIM('KO' FROM @CustomChars) AS TrimCustom;
GO


/* Demo 3:  STRING_AGG() */
-- Uses dbo.States table (created in code/data/TSQLV6.sql)
SELECT
    SalesTerritory,
    StateProvinceCode
FROM dbo.States s;

-- Pre-2017 solution: STUFF + FOR XML PATH
SELECT
    s.SalesTerritory,
    STUFF
        ((
            SELECT
                ',' + s2.StateProvinceCode
            FROM dbo.States s2
            WHERE
                s.SalesTerritory = s2.SalesTerritory
            ORDER BY
                s2.StateProvinceCode
            FOR XML PATH ('')
        ), 1, 1, '') AS StatesList
FROM dbo.States s;

-- 2017 solution: STRING_AGG()
SELECT
    SalesTerritory,
    STRING_AGG(StateProvinceCode, ',') AS StatesList
FROM dbo.States s
GROUP BY
    SalesTerritory;

-- STRING_AGG with ordering via WITHIN GROUP
SELECT
    SalesTerritory,
    STRING_AGG(StateProvinceCode, ',')
        WITHIN GROUP(ORDER BY StateProvinceCode) AS StatesList
FROM dbo.States s
GROUP BY
    SalesTerritory;
GO
