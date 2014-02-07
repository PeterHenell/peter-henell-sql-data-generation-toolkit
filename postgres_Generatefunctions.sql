
create or replace function gen.generate_pk_functions() 
returns void
as $$
DECLARE
	count INT;
	goal INT;
	c INT;
	createdObject gen.CreatedObjects%ROWTYPE;
BEGIN

	DROP TABLE IF EXISTS tempCreations;

	CREATE TEMP TABLE tempCreations (functionCreation text, functiondrop text);
	INSERT INTO tempCreations ( functionCreation, functiondrop )
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE('CREATE OR REPLACE FUNCTION gen.getPK_TABLE_NAME(n BIGINT := 1)
	RETURNS DATA_TYPE
	AS ' || quote_literal('
	BEGIN
		(SELECT COLUMN_NAME 
		FROM TABLE_SCHEMA.TABLE_NAME
		ORDER BY COLUMN_NAME
		LIMIT 1 OFFSET (n - 1));
	END; ')	
	||  'LANGUAGE plpgsql;'
		, 'TABLE_SCHEMA', TABLE_SCHEMA)
		, 'TABLE_NAME', TABLE_NAME)
		, 'COLUMN_NAME', COLUMN_NAME)
		, 'DATA_TYPE', DATA_TYPE) AS functionCreation

	,REPLACE('DROP FUNCTION IF EXIST gen.getPK_TABLE_NAME;',
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



	goal := (select COUNT(*) FROM tempCreations);
	c := 0;
	WHILE c < goal
	LOOP	
		SELECT  
			functionCreation,
			functiondrop
		into createdObject
		from 
			tempCreations
		ORDER BY functionCreation
		LIMIT 1 OFFSET c;		

		--EXECUTE (createdObject.DropStatement);
		EXECUTE (createdObject.CreateStatement);

		INSERT INTO gen.CreatedObjects(CreateStatement, DropStatement)
		VALUES(createdObject.CreateStatement, createdObject.DropStatement);
		
		c = c + 1;
	END LOOP;
END
$$ language plpgsql;

 DO language plpgsql $$
 BEGIN
   PERFORM gen.generate_pk_functions() ;
 END
 $$;

--select * from gen.CreatedObjects;
--select * from tempCreations;

