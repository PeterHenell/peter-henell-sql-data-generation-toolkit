-- Generate 1000 rows with different series (days, minutes, seconds etc)
SELECT 
	gen.days(N, '2014-01-01', DEFAULT) AS [Day series],
	gen.minutes(N, '2014-01-01', DEFAULT) AS [Minute series],
	gen.seconds(N, '2014-01-01', DEFAULT) AS [Seconds series],
	gen.hours(N, '2014-01-01', DEFAULT) AS [Hour series],
	gen.ints(N, DEFAULT, DEFAULT, DEFAULT) AS [Ints],
	gen.decimals(N, DEFAULT, DEFAULT, DEFAULT) AS [Decimal numbers],
	gen.strings(N, 10, 25) AS [Strings]
FROM 
	gen.generate_range(1, 1000);
	
-- Generate 1000 rows where each row started once per hour and ended 5-10 minutes later
SELECT 
	startDate,
	endDate
FROM 
	gen.generate_range(1, 1000)
CROSS APPLY(VALUES(gen.hours(N, '2014-01-01', DEFAULT))) as a(startdate)
cross APPLY gen.rint_row(5, 10) random
CROSS APPLY(VALUES(gen.minutes(random.a, startDate, DEFAULT))) as b(endDate)



-- generate 1000 random values between 5 and 10
SELECT * FROM gen.rint_rows(5, 10, 1000);