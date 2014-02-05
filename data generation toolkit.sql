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
			gen.rints(@min, @max) AS random
		FROM 
			gen.generate_range(1, @rows)
GO