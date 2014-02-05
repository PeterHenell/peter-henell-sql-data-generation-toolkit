
/*
sample usage:

INSERT INTO someTable(dateColumn, dateColumn, dateColumn, intColumn, decimalColumn, varcharColumn)
SELECT 
	gen.day_series(N, '2014-01-01', DEFAULT) AS [Day series],
	gen.minute_series(N, '2014-01-01', DEFAULT) AS [Minute series],
	gen.hour_series(N, '2014-01-01', DEFAULT) AS [Hour series],
	gen.ints(N, DEFAULT, DEFAULT, DEFAULT) AS [Ints],
	gen.decimals(N, DEFAULT, DEFAULT, DEFAULT) AS [Decimal numbers],
	gen.strings(N, 10, 25) AS [Strings]
FROM 
	gen.generate_range(1, 1000);
	
	

*/

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gen')
BEGIN
	exec('CREATE SCHEMA [gen] AUTHORIZATION [dbo]');
END
GO


IF object_id(N'gen.generate_range', N'IF') IS NOT NULL
    DROP FUNCTION gen.generate_range
GO
CREATE FUNCTION gen.generate_range(@from bigint, @to bigint)
RETURNS TABLE 
WITH SCHEMABINDING

	RETURN
	SELECT TOP (@to - @from + 1) 
			ROW_NUMBER()  OVER (ORDER BY (SELECT null)) - 1 + @from AS [N]
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


IF object_id(N'gen.day_series', N'FN') IS NOT NULL
    DROP FUNCTION gen.day_series
GO
CREATE FUNCTION gen.day_series(@n bigint, @from datetime2(7), @step tinyint = 1)
RETURNS datetime2(7)
WITH schemabinding
AS
BEGIN	
	RETURN DATEADD(day, (@n - 1) * @step, @from);
END
GO

IF object_id(N'gen.second_series', N'FN') IS NOT NULL
    DROP FUNCTION gen.second_series
GO
CREATE FUNCTION gen.second_series(@n bigint, @from datetime2(7), @step tinyint = 1)
RETURNS datetime2(7)
WITH schemabinding
AS
BEGIN	
	RETURN DATEADD(second, (@n - 1) * @step, @from);
END
GO

IF object_id(N'gen.minute_series', N'FN') IS NOT NULL
    DROP FUNCTION gen.minute_series
GO
CREATE FUNCTION gen.minute_series(@n bigint, @from datetime2(7), @step tinyint = 1)
RETURNS datetime2(7)
WITH schemabinding
AS
BEGIN	
	RETURN DATEADD(minute, (@n - 1) * @step, @from);
END
GO

IF object_id(N'gen.hour_series', N'FN') IS NOT NULL
    DROP FUNCTION gen.hour_series
GO
CREATE FUNCTION gen.hour_series(@n bigint, @from datetime2(7), @step tinyint = 1)
RETURNS datetime2(7)
WITH schemabinding
AS
BEGIN	
	RETURN DATEADD(hour, (@n - 1) * @step, @from);
END
GO


IF object_id(N'gen.ints', N'FN') IS NOT NULL
    DROP FUNCTION gen.ints
GO
CREATE FUNCTION gen.ints(@n bigint, @startValue tinyint = 1, @max bigint = 1000000, @step int = 1)
RETURNS bigint
WITH schemabinding
AS
BEGIN	
	RETURN @startValue + ((@step * (@n - 1)) % @max);
END
GO


IF object_id(N'gen.decimals', N'FN') IS NOT NULL
    DROP FUNCTION gen.decimals
GO
CREATE FUNCTION gen.decimals(@n bigint, @startValue DECIMAL(19, 6) = 1.00, @max DECIMAL(19, 6) = 1000000.0, @step int = 1)
RETURNS DECIMAL(19, 6)
WITH schemabinding
AS
BEGIN	
	RETURN @startValue + ((@step * (@n - 1)) % @max);
END

go

IF object_id(N'gen.strings', N'FN') IS NOT NULL
    DROP FUNCTION gen.strings
GO
CREATE FUNCTION gen.strings(@n bigint, @minLen int = 1, @maxLen int = 100)
RETURNS varchar(MAX)
WITH schemabinding
AS
BEGIN
	-- Credits to Chris Judge from:	
	--http://stackoverflow.com/questions/1324063/generating-random-strings-with-t-sql
	-- Changes from his code: Made it working from within a function
	DECLARE @length int,
			@CharPool varchar(1000),
			@PoolLength int,
			@LoopCount int,
			@RandomString varchar(MAX)	;

	SET @Length = (@n % @maxLen) + @minLen

	-- define allowable character explicitly - easy to read this way an easy to 
	-- omit easily confused chars like l (ell) and 1 (one) or 0 (zero) and O (oh)
	SET @CharPool = 
		'abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ123456789'
	SET @PoolLength = DataLength(@CharPool)

	SET @LoopCount = 0
	SET @RandomString = ''

	WHILE (@LoopCount < @Length) BEGIN
		SELECT @RandomString = @RandomString + 
			SUBSTRING(@Charpool, CONVERT(int, (@LoopCount * @N) % @PoolLength), 1)
		SELECT @LoopCount = @LoopCount + 1
	END
	
	RETURN substring(@RandomString, 1, @maxLen);
END

go

