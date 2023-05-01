/* Demo 1:  Inline index definitions */
-- Get to specify clustered or nonclustered indexes inline.
-- Get to specify indexes as part of the table definition.
CREATE TABLE #TestTable
(
    TestID INT NOT NULL CONSTRAINT [PK_TestTable] PRIMARY KEY CLUSTERED,
    SomeID INT NOT NULL CONSTRAINT [DF_TestTable_SomeID] DEFAULT(0),
    SomeString NVARCHAR(72) NOT NULL,
    INDEX [IX_TestTable_SomeID] NONCLUSTERED(SomeID) INCLUDE (SomeString)
);
GO
