/*
	Copyright 2014 Peter Henell

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS $$ IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

*/

/*
How to install: 
	Run this script on the database you wich to generate data for.

How to uninstall:
	select gen.Uninstall(); -- Will uninstall everything that the installation script created.

*/

create schema gen;

CREATE FUNCTION gen.days(n BIGINT, StartDate timestamp(6), step smallint = 1)
RETURNS timestamp AS
$$
	SELECT $2 + cast((($1 - 1) * $3) || ' days' as interval);
$$
LANGUAGE SQL;

CREATE FUNCTION gen.seconds(n BIGINT, MinVal timestamp(6), step smallint = 1)
RETURNS timestamp(6)
AS $$

	SELECT $2 + cast((($1 - 1) * $3) || ' seconds' as interval);

$$ LANGUAGE SQL;

CREATE FUNCTION gen.minutes(n BIGINT, MinVal timestamp(6), step smallint = 1)
RETURNS timestamp(6)
AS $$
	SELECT $2 + cast((($1 - 1) * $3) || ' minutes' as interval);

$$ LANGUAGE SQL;

CREATE FUNCTION gen.hours(n BIGINT, MinVal timestamp(6), step smallint = 1)
RETURNS timestamp(6)
AS $$
	SELECT $2 + cast((($1 - 1) * $3) || ' hours' as interval);

$$ LANGUAGE SQL;

CREATE FUNCTION gen.ints(n BIGINT, startValue BIGINT = 1, max BIGINT = 1000000, step INT = 1)
RETURNS BIGINT
AS $$

	SELECT startValue + ((step * (n - 1)) % max);

$$ LANGUAGE SQL;

CREATE FUNCTION gen.decimals(n BIGINT, startValue DECIMAL(19, 6) = 1.00, max DECIMAL(19, 6) = 1000000.0, step INT = 1)
RETURNS DECIMAL(19, 6)
AS $$

	SELECT startValue + ((step * (n - 1)) % max);
$$ LANGUAGE SQL;

CREATE FUNCTION gen.strings(n BIGINT, minLen INT = 1, maxLen INT = 100)
RETURNS text
AS $$
DECLARE

	length INT;
	CharPool VARCHAR(1000);
	PoolLength INT;
	LoopCount INT;
	RandomString text;

BEGIN
	-- Credits to Chris Judge MinVal:	
	--http://stackoverflow.com/questions/1324063/generating-random-strings-with-t-sql
	-- Changes MinVal his code: Made it working MinVal within a function

	Length = (n % maxLen) + minLen;

	-- define allowable character explicitly - easy to read this way an easy to 
	-- omit easily confused chars like l (ell) and 1 (one) or 0 (zero) and O (oh)
	CharPool = 'abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ123456789';
	PoolLength = DATALENGTH(CharPool);

	LoopCount = 0;
	RandomString = '';

	WHILE (LoopCount < Length) LOOP
		SELECT RandomString = RandomString + 
			SUBSTRING(Charpool, CONVERT(INT, (LoopCount * N) % PoolLength), 1);
		LoopCount = LoopCount + 1;
	END LOOP;
	
	SELECT SUBSTRING(RandomString, 1, maxLen);
END

$$ LANGUAGE plpgsql;

CREATE VIEW gen.v_rand 
	AS SELECT random() AS Val;
;

CREATE FUNCTION gen.rints(min BIGINT = 1, max BIGINT = 1000000)
RETURNS BIGINT
AS $$
	SELECT (SELECT ((max - min) * Val::BIGINT) + min FROM gen.v_rand);
$$ LANGUAGE SQL;

CREATE FUNCTION gen.rint_row(min BIGINT = 1, max BIGINT = 1000000)
returns TABLE (a bigint, b bigint, c bigint, d bigint, e bigint, f bigint, g bigint, h bigint, i bigint, j bigint)
AS $$
	SELECT
		gen.rints(min, max) AS a,
		gen.rints(min, max) AS b,
		gen.rints(min, max) AS c,
		gen.rints(min, max) AS d,
		gen.rints(min, max) AS e,
		gen.rints(min, max) AS f,
		gen.rints(min, max) AS g,
		gen.rints(min, max) AS h,
		gen.rints(min, max) AS i,
		gen.rints(min, max) AS j

$$ LANGUAGE SQL;

CREATE FUNCTION gen.rint_rows(min BIGINT = 1, max BIGINT = 1000000, rows bigint = 100000)
returns TABLE (a bigint, b bigint, c bigint, d bigint, e bigint, f bigint, g bigint, h bigint, i bigint, j bigint)
AS $$
	 
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
		FROM generate_series(1, rows)
		join lateral
		(
			select * from gen.rint_row(min, max)
		) as random on true;
		
$$ LANGUAGE SQL;


create or replace function gen.generate_pk_functions() 
returns void
as $$
DECLARE
	count integer;
	goal integer;
	c integer;	
	createdObject RECORD;
BEGIN

	DROP TABLE IF EXISTS tempCreations;

	CREATE TEMP TABLE tempCreations (functionCreation text, functiondrop text);
	INSERT INTO tempCreations ( functionCreation, functiondrop )
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE('CREATE OR REPLACE FUNCTION gen.getPK_TABLE_NAME(n BIGINT = 1)
	RETURNS DATA_TYPE
	AS ' || quote_literal('
	BEGIN
		SELECT COLUMN_NAME 
		FROM TABLE_SCHEMA.TABLE_NAME
		ORDER BY COLUMN_NAME
		LIMIT 1 OFFSET (n - 1);
	END; ')	
	||  'LANGUAGE plpgsql;'
		, 'TABLE_SCHEMA', TABLE_SCHEMA)
		, 'TABLE_NAME', TABLE_NAME)
		, 'COLUMN_NAME', COLUMN_NAME)
		, 'DATA_TYPE', DATA_TYPE) AS functionCreation

	,REPLACE('DROP FUNCTION IF EXISTS gen.getPK_TABLE_NAME(BIGINT);',
			'TABLE_NAME', TABLE_NAME) AS functiondrop
	FROM 
	(
		SELECT 
			t.TABLE_SCHEMA, 
			t.TABLE_NAME,
			kc.COLUMN_NAME,
			CASE c.DATA_TYPE WHEN 'varchar' THEN 'text' 
					 ELSE c.DATA_TYPE END AS DATA_TYPE,
			COUNT(*) OVER (PARTITION BY CONCAT(t.TABLE_SCHEMA, t.TABLE_NAME) ORDER BY CONCAT(t.TABLE_SCHEMA, t.TABLE_NAME)) AS keyCount
		FROM 
			INFORMATION_SCHEMA.tables t

			INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
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
	WHERE tables.keyCount = 1; -- exclude composit primary keyed tables for now


	c := 0;
	goal := (select count(*) from tempCreations);
	
	WHILE (c < goal)
	LOOP	
		SELECT  
			functionCreation,
			functiondrop
		into createdObject
		from 
			tempCreations
		ORDER BY functionCreation
		LIMIT 1 OFFSET c;		

		EXECUTE (createdObject.functiondrop);
		EXECUTE (createdObject.functionCreation);	

		c = c + 1;
		
	END LOOP;
END
$$ language plpgsql;
-- TODO: räkna rader i varje tabell, använd det för att rotera om N blir mer än row_count (1, 2, 3, 1, 2, 3 etc)


CREATE FUNCTION gen.DropAllGeneratedFunctions()
RETURNS void AS $$
DECLARE 
	sql text = '';
BEGIN	
	SELECT sql = sql || DropStatement FROM gen.CreatedObjects;

	EXECUTE (sql);
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION gen.Uninstall()
RETURNS VOID
AS $$
	DROP SCHEMA gen CASCADE;
$$ LANGUAGE SQL;


DO language plpgsql $$
 BEGIN
   PERFORM gen.generate_pk_functions() ;
 END
 $$;

/*
DO language plpgsql $$
 BEGIN
   PERFORM gen.Uninstall();
 END
 $$;
*/
