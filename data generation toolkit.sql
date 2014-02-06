SET NOCOUNT ON;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gen')
BEGIN
	EXEC('CREATE SCHEMA [gen] AUTHORIZATION [dbo]');
END
GO

IF OBJECT_ID(N'gen.rint_rows', N'IF') IS NOT NULL
    DROP FUNCTION gen.rint_rows
GO

IF OBJECT_ID(N'gen.rint_row', N'IF') IS NOT NULL
    DROP FUNCTION gen.rint_row
GO
IF OBJECT_ID(N'gen.rints', N'FN') IS NOT NULL
    DROP FUNCTION gen.rints
GO


IF OBJECT_ID('gen.v_rand', 'V') IS NOT NULL
	DROP VIEW gen.v_rand;
GO

IF OBJECT_ID(N'gen.generate_range', N'IF') IS NOT NULL
    DROP FUNCTION gen.generate_range
GO

IF OBJECT_ID(N'gen.days', N'FN') IS NOT NULL
    DROP FUNCTION gen.days
GO
IF OBJECT_ID(N'gen.seconds', N'FN') IS NOT NULL
    DROP FUNCTION gen.seconds
GO
IF OBJECT_ID(N'gen.minutes', N'FN') IS NOT NULL
    DROP FUNCTION gen.minutes
GO
IF OBJECT_ID(N'gen.hours', N'FN') IS NOT NULL
    DROP FUNCTION gen.hours
GO
IF OBJECT_ID(N'gen.ints', N'FN') IS NOT NULL
    DROP FUNCTION gen.ints
GO
IF OBJECT_ID(N'gen.decimals', N'FN') IS NOT NULL
    DROP FUNCTION gen.decimals
GO
IF OBJECT_ID(N'gen.strings', N'FN') IS NOT NULL
    DROP FUNCTION gen.strings
GO
IF OBJECT_ID(N'gen.CreatedObjects') IS NOT NULL
BEGIN
	
	IF OBJECT_ID('gen.DropAllGeneratedFunctions', N'P') IS NOT NULL
		EXEC gen.DropAllGeneratedFunctions;
	
	DROP TABLE gen.CreatedObjects;
END
GO

CREATE TABLE gen.CreatedObjects (
	Id INt IDENTITY(1, 1) PRIMARY KEY,
	CreateStatement varchar(MAX), 
	DropStatement  varchar(MAX)
)
GO

CREATE FUNCTION gen.generate_range(@from BIGINT, @to BIGINT)
RETURNS TABLE 
WITH SCHEMABINDING

	RETURN
	SELECT TOP (@to - @from + 1) 
			ROW_NUMBER()  OVER (ORDER BY (SELECT NULL)) - 1 + @from AS [N]
	FROM 
		(VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) a(n),
		(VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) b(n),
		(VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) c(n),
		(VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) d(n),
		(VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) e(n),
		(VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) f(n),
		(VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) g(n),
		(VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) h(n)
GO

CREATE FUNCTION gen.days(@n BIGINT, @from DATETIME2(7), @step TINYINT = 1)
RETURNS DATETIME2(7)
WITH SCHEMABINDING
AS
BEGIN	
	RETURN DATEADD(day, (@n - 1) * @step, @from);
END
GO

CREATE FUNCTION gen.seconds(@n BIGINT, @from DATETIME2(7), @step TINYINT = 1)
RETURNS DATETIME2(7)
WITH SCHEMABINDING
AS
BEGIN	
	RETURN DATEADD(second, (@n - 1) * @step, @from);
END
GO

CREATE FUNCTION gen.minutes(@n BIGINT, @from DATETIME2(7), @step TINYINT = 1)
RETURNS DATETIME2(7)
WITH SCHEMABINDING
AS
BEGIN	
	RETURN DATEADD(minute, (@n - 1) * @step, @from);
END
GO

CREATE FUNCTION gen.hours(@n BIGINT, @from DATETIME2(7), @step TINYINT = 1)
RETURNS DATETIME2(7)
WITH SCHEMABINDING
AS
BEGIN	
	RETURN DATEADD(hour, (@n - 1) * @step, @from);
END
GO

CREATE FUNCTION gen.ints(@n BIGINT, @startValue BIGINT = 1, @max BIGINT = 1000000, @step INT = 1)
RETURNS BIGINT
WITH SCHEMABINDING
AS
BEGIN	
	RETURN @startValue + ((@step * (@n - 1)) % @max);
END
GO

CREATE FUNCTION gen.decimals(@n BIGINT, @startValue DECIMAL(19, 6) = 1.00, @max DECIMAL(19, 6) = 1000000.0, @step INT = 1)
RETURNS DECIMAL(19, 6)
WITH SCHEMABINDING
AS
BEGIN	
	RETURN @startValue + ((@step * (@n - 1)) % @max);
END

go

CREATE FUNCTION gen.strings(@n BIGINT, @minLen INT = 1, @maxLen INT = 100)
RETURNS VARCHAR(MAX)
WITH SCHEMABINDING
AS
BEGIN
	-- Credits to Chris Judge from:	
	--http://stackoverflow.com/questions/1324063/generating-random-strings-with-t-sql
	-- Changes from his code: Made it working from within a function
	DECLARE @length INT,
			@CharPool VARCHAR(1000),
			@PoolLength INT,
			@LoopCount INT,
			@RandomString VARCHAR(MAX)	;

	SET @Length = (@n % @maxLen) + @minLen

	-- define allowable character explicitly - easy to read this way an easy to 
	-- omit easily confused chars like l (ell) and 1 (one) or 0 (zero) and O (oh)
	SET @CharPool = 
		'abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ123456789'
	SET @PoolLength = DATALENGTH(@CharPool)

	SET @LoopCount = 0
	SET @RandomString = ''

	WHILE (@LoopCount < @Length) BEGIN
		SELECT @RandomString = @RandomString + 
			SUBSTRING(@Charpool, CONVERT(INT, (@LoopCount * @N) % @PoolLength), 1)
		SELECT @LoopCount = @LoopCount + 1
	END
	
	RETURN SUBSTRING(@RandomString, 1, @maxLen);
END

go

CREATE VIEW gen.v_rand WITH schemabinding
	AS SELECT RAND(CHECKSUM(NEWID())) AS Val;
GO

CREATE FUNCTION gen.rints(@min BIGINT = 1, @max BIGINT = 1000000)
RETURNS BIGINT
WITH SCHEMABINDING
AS
BEGIN	
	RETURN (SELECT ((@max - @min) * Val) + @min FROM gen.v_rand);
END

GO

CREATE FUNCTION gen.rint_row(@min BIGINT = 1, @max BIGINT = 1000000)
RETURNS TABLE 
WITH SCHEMABINDING
AS
	RETURN SELECT
		gen.rints(@min, @max) AS a,
		gen.rints(@min, @max) AS b,
		gen.rints(@min, @max) AS c,
		gen.rints(@min, @max) AS d,
		gen.rints(@min, @max) AS e,
		gen.rints(@min, @max) AS f,
		gen.rints(@min, @max) AS g,
		gen.rints(@min, @max) AS h,
		gen.rints(@min, @max) AS i,
		gen.rints(@min, @max) AS j

GO

CREATE FUNCTION gen.rint_rows(@min BIGINT = 1, @max BIGINT = 1000000, @rows bigint)
RETURNS TABLE 
WITH SCHEMABINDING
AS
	RETURN 
		SELECT
			random.a,
			random.b,
			random.c,
			random.d,
			random.e,
			random.f,
			random.g,
			random.h,
			random.i,
			random.j
		FROM gen.generate_range(1, @rows)
		CROSS APPLY gen.rint_row(@min, @max) AS random;
GO



DECLARE  @sql TABLE (functionCreation VARCHAR(MAX), functiondrop VARCHAR(MAX))
INSERT @sql ( functionCreation, functiondrop )
SELECT 
	REPLACE(REPLACE(REPLACE(REPLACE('
CREATE FUNCTION gen.getPK_TABLE_NAME(@n BIGINT = 1)
RETURNS DATA_TYPE
WITH SCHEMABINDING
AS
BEGIN	
	RETURN 
		(SELECT COLUMN_NAME 
		FROM TABLE_SCHEMA.TABLE_NAME
		ORDER BY 1
		OFFSET (@n - 1) ROWS FETCH NEXT 1 ROWS ONLY)
END
  ' , 'TABLE_SCHEMA', TABLE_SCHEMA)
	, 'TABLE_NAME', TABLE_NAME)
	, 'COLUMN_NAME', COLUMN_NAME)
	, 'DATA_TYPE', DATA_TYPE) AS functionCreation

,REPLACE('IF OBJECT_ID(N''gen.getPK_TABLE_NAME'', N''FN'') IS NOT NULL
    DROP FUNCTION gen.getPK_TABLE_NAME;',
		'TABLE_NAME', TABLE_NAME) AS functiondrop
FROM 
(
	SELECT 
		t.TABLE_SCHEMA, 
		t.TABLE_NAME,
		kc.COLUMN_NAME,
		CASE c.DATA_TYPE WHEN 'varchar' THEN 'varchar(max)' 
						 WHEN 'nvarchar' THEN 'nvarchar(max)' 
						 ELSE c.DATA_TYPE END AS DATA_TYPE,
		COUNT(*) OVER (PARTITION BY CONCAT(t.TABLE_SCHEMA, 	t.TABLE_NAME) ORDER BY CONCAT(t.TABLE_SCHEMA, 	t.TABLE_NAME)) AS keyCount
	FROM 
		INFORMATION_SCHEMA.tables t

		INNER JOIN [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS] tc
			ON tc.TABLE_NAME = t.TABLE_NAME 
			AND tc.TABLE_SCHEMA = t.TABLE_SCHEMA 
			AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
		INNER JOIN INFORMATION_SCHEMA.key_column_usage kc
			ON kc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME 
			AND kc.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA 
			AND kc.TABLE_NAME = tc.TABLE_NAME
		INNER JOIN INFORMATION_SCHEMA.COLUMNS c
			ON c.TABLE_NAME = kc.TABLE_NAME 
			AND c.TABLE_SCHEMA = tc.TABLE_SCHEMA 
			AND c.COLUMN_NAME = kc.COLUMN_NAME
	) AS tables
WHERE tables.keyCount = 1 -- exclude composit primary keyed tables for now


DECLARE @c INT = 0, @goal INT;
SET @goal = (SELECT COUNT(*) FROM @sql);

WHILE @c < @goal
BEGIN
	
	DECLARE @creation VARCHAR(MAX);
	DECLARE @drop VARCHAR(MAX);

	SELECT 
		@creation = functionCreation,
		@drop = functiondrop
	FROM @sql
	ORDER BY functionCreation
	offset @c ROWS FETCH NEXT 1 ROWS ONLY;

	EXEC (@drop);
	EXEC (@creation);

	INSERT gen.CreatedObjects(CreateStatement, DropStatement)
	VALUES(@creation, @drop);
	
	SET @c += 1;
END

GO
-- TODO: räkna rader i varje tabell, använd det för att rotera om N blir mer än row_count (1, 2, 3, 1, 2, 3 etc)


IF OBJECT_ID('gen.DropAllGeneratedFunctions', N'P') IS NOT NULL
	DROP PROCEDURE gen.DropAllGeneratedFunctions
GO
CREATE PROCEDURE gen.DropAllGeneratedFunctions
AS
BEGIN
	DECLARE @sql VARCHAR(MAX) = '';

	SELECT @sql = @sql + DropStatement FROM gen.CreatedObjects;

	EXEC (@sql);
end

GO
IF OBJECT_ID('gen.Uninstall', N'P') IS NOT NULL
	DROP PROCEDURE gen.Uninstall
GO

CREATE PROCEDURE gen.Uninstall
AS
BEGIN
	
	IF OBJECT_ID(N'gen.rint_rows', N'IF') IS NOT NULL
		DROP FUNCTION gen.rint_rows

	IF OBJECT_ID(N'gen.rint_row', N'IF') IS NOT NULL
		DROP FUNCTION gen.rint_row
	IF OBJECT_ID(N'gen.rints', N'FN') IS NOT NULL
		DROP FUNCTION gen.rints
	IF OBJECT_ID('gen.v_rand', 'V') IS NOT NULL
		DROP VIEW gen.v_rand;
	IF OBJECT_ID(N'gen.generate_range', N'IF') IS NOT NULL
		DROP FUNCTION gen.generate_range
	IF OBJECT_ID(N'gen.days', N'FN') IS NOT NULL
		DROP FUNCTION gen.days
	IF OBJECT_ID(N'gen.seconds', N'FN') IS NOT NULL
		DROP FUNCTION gen.seconds
	IF OBJECT_ID(N'gen.minutes', N'FN') IS NOT NULL
		DROP FUNCTION gen.minutes
	IF OBJECT_ID(N'gen.hours', N'FN') IS NOT NULL
		DROP FUNCTION gen.hours
	IF OBJECT_ID(N'gen.ints', N'FN') IS NOT NULL
		DROP FUNCTION gen.ints
	IF OBJECT_ID(N'gen.decimals', N'FN') IS NOT NULL
		DROP FUNCTION gen.decimals
	IF OBJECT_ID(N'gen.strings', N'FN') IS NOT NULL
		DROP FUNCTION gen.strings

	EXEC gen.DropAllGeneratedFunctions;
	
	DROP TABLE gen.CreatedObjects;

	IF OBJECT_ID('gen.Uninstall', N'P') IS NOT NULL
		DROP PROCEDURE gen.Uninstall
	IF OBJECT_ID('gen.DropAllGeneratedFunctions', N'P') IS NOT NULL
		DROP PROCEDURE gen.DropAllGeneratedFunctions

	EXEC('drop SCHEMA [gen]');
END

GO
