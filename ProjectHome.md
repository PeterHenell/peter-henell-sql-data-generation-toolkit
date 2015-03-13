A simple Framework to generate data for tables in Microsoft SQL Server or PostgreSQL.

Tested on Microsoft SQL Server 2012 and PostgreSQL 9.3.

**How to install:**
Run the installation script found in the Source repository. This should be done in the database you want to generate data in. Otherwise the automatically generated functions will not be available.
Script to install is found in the repo: https://code.google.com/p/peter-henell-sql-data-generation-toolkit/source/browse/data+generation+toolkit.sql

**How to unintall:**
Run the gen.Uninstall procedure by doing: `EXEC gen.Uninstall`

It can generate data for the most common data types. (More to be developed...)
It can generate data for tables that require foreign key data to be insertable.

You want to generate data for a table. You need the data to be predictable and it need to be "similar" to what the application would do to the data.

This tiny tool will help you generate data using a simple select statement.

Please see the Source respository for more examples.

Below sample will generate 1000 rows with the following data:

Columns:
  1. Each row is a new day, first row have date 2014-01-01. DEFAULT indicates to step one day per row.
  1. Same as Col 1, but with stepping up minutes instead of days.
  1. Same as Col 1, but with stepping up hours instead of days.
  1. A numeric serial. Each row get a new number, stepping default 1 per row.
  1. Same as Col 4 but with decimal values instead.
  1. "Random" string values (string values with no meaning), except it is not random but rather predictable.


Usage:
```
SELECT 
	gen.days(N, '2014-01-01', DEFAULT) AS [Day series],
	gen.minutes(N, '2014-01-01', DEFAULT) AS [Minute series],
	gen.hours(N, '2014-01-01', DEFAULT) AS [Hour series],
	gen.ints(N, DEFAULT, DEFAULT, DEFAULT) AS [Ints],
	gen.decimals(N, DEFAULT, DEFAULT, DEFAULT) AS [Decimal numbers],
	gen.strings(N, 10, 25) AS [Strings]
FROM 
	gen.generate_range(1, 1000);

Results: 
Day series	Minute series	Hour series	Ints	Decimal numbers	Strings
2014-01-01 00:00:00.0000000	2014-01-01 00:00:00.0000000	2014-01-01 00:00:00.0000000	1	1.000000	abcdefghij
2014-01-02 00:00:00.0000000	2014-01-01 00:01:00.0000000	2014-01-01 01:00:00.0000000	2	2.000000	bdfhjmoqsuw
2014-01-03 00:00:00.0000000	2014-01-01 00:02:00.0000000	2014-01-01 02:00:00.0000000	3	3.000000	cfimpsvyBEHK
2014-01-04 00:00:00.0000000	2014-01-01 00:03:00.0000000	2014-01-01 03:00:00.0000000	4	4.000000	dhmquyCGKPTX2
2014-01-05 00:00:00.0000000	2014-01-01 00:04:00.0000000	2014-01-01 04:00:00.0000000	5	5.000000	ejpuzEJPUZ5afk
2014-01-06 00:00:00.0000000	2014-01-01 00:05:00.0000000	2014-01-01 05:00:00.0000000	6	6.000000	fmsyEKRX4agntzF
```

Sample 2: Generate dates (startDate and endDate) such that "something" started every hour and took 5 minutes to complete (ended 5 minutes after it started):
```
SELECT 
	startDate,
	endDate
FROM 
	gen.generate_range(1, 1000)
CROSS APPLY(VALUES(gen.hours(N, '2014-01-01', DEFAULT))) as a(startdate)
CROSS APPLY(VALUES(gen.minutes(6, startDate, DEFAULT))) as b(endDate);

Results:
startDate	endDate
2014-01-01 00:00:00.0000000	2013-12-31 23:59:00.0000000
2014-01-01 01:00:00.0000000	2014-01-01 00:59:00.0000000
2014-01-01 02:00:00.0000000	2014-01-01 01:59:00.0000000
2014-01-01 03:00:00.0000000	2014-01-01 02:59:00.0000000
2014-01-01 04:00:00.0000000	2014-01-01 03:59:00.0000000
```

Foreign keys:
```
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
```