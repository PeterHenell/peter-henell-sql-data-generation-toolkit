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

/*
Results:
Day series	Minute series	Seconds series	Hour series	Ints	Decimal numbers	Strings
2014-01-01 00:00:00.0000000	2014-01-01 00:00:00.0000000	2014-01-01 00:00:00.0000000	2014-01-01 00:00:00.0000000	1	1.000000	abcdefghij
2014-01-02 00:00:00.0000000	2014-01-01 00:01:00.0000000	2014-01-01 00:00:01.0000000	2014-01-01 01:00:00.0000000	2	2.000000	bdfhjmoqsuw
2014-01-03 00:00:00.0000000	2014-01-01 00:02:00.0000000	2014-01-01 00:00:02.0000000	2014-01-01 02:00:00.0000000	3	3.000000	cfimpsvyBEHK
2014-01-04 00:00:00.0000000	2014-01-01 00:03:00.0000000	2014-01-01 00:00:03.0000000	2014-01-01 03:00:00.0000000	4	4.000000	dhmquyCGKPTX2


*/	

-- Generate 1000 rows where each row started once per hour and ended 5-10 minutes later
SELECT 
	startDate,
	endDate
FROM 
	gen.generate_range(1, 1000)
CROSS APPLY(VALUES(gen.hours(N, '2014-01-01', DEFAULT))) as a(startdate)
cross APPLY gen.rint_row(5, 10) random
CROSS APPLY(VALUES(gen.minutes(random.a, startDate, DEFAULT))) as b(endDate)

/*
Results:
startDate	endDate
2014-01-01 00:00:00.0000000	2014-01-01 00:07:00.0000000
2014-01-01 01:00:00.0000000	2014-01-01 01:04:00.0000000
2014-01-01 02:00:00.0000000	2014-01-01 02:04:00.0000000
2014-01-01 03:00:00.0000000	2014-01-01 03:04:00.0000000
2014-01-01 04:00:00.0000000	2014-01-01 04:05:00.0000000
2014-01-01 05:00:00.0000000	2014-01-01 05:04:00.0000000

*/

-- generate 1000 random values between 5 and 10
SELECT * FROM gen.rint_rows(5, 10, 1000);
/*
Results:
a	b	c	d	e	f	g	h	i	j
7	6	9	8	7	9	8	8	9	9
7	6	6	9	5	5	6	9	7	8
6	6	7	6	7	6	5	6	8	6
6	6	5	5	7	6	6	9	5	5
9	5	9	7	9	5	9	8	6	5
*/


SELECT * FROM gen.generate_range(1, 1000);
/*
Results:
1
2
3
4
5
6
7
8
*/


-- ---------------------------------------------------------------------------------------
--   Getting foreign keys
--
--   Imagine we are inserting data to a table called OrderTransactions, 
--		this table have a foreign key to MoneyTransaction table.
--	 To be able to insert data into OrderTransaction we will need to either disable the foreign key constraints or
--      to use a key from the MoneyTransaction table.
--
--   When the framework is installed, some functions are dynamically generated.
--	 For each table that have a single value primary key (composit keys not supported)
--		it will generate a function that allow us to select a row from them.
--   These functions will get the N:th primary key from a table.
--   These functions are all named: gen.getPK_TABLENAME and require one parameter N to get the N:th row in them.
--
--
-- This example show how to get 100 primary keys to the table MoneyTransaction
--
-- Insert OrderTransaction(MoneyTransactionId, Amount)
SELECT 
	gen.getPK_moneyTransaction(N),
	gen.decimals(N, 100, 500, 100)
FROM
	gen.generate_range(1, 100);

-- Results
/*
1	100.000000
2	200.000000
3	300.000000
4	400.000000
5	500.000000
6	100.000000
*/
--
-- ----------------------------------------------------------------------------------------



-- To uninstall the framework and all the generated functions
-- To install again, simply run the installation script
-- Uninstall will remove all the functions, procedures, generated functions and the [gen] schema itself
EXEC gen.Uninstall