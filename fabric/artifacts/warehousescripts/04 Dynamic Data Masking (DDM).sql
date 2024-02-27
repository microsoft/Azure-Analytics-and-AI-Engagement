-------------------------------------------------------------------------Dynamic Data Masking (DDM)----------------------------------------------------------------------------------------------------------
/*  Dynamic data masking helps prevent unauthorized access to sensitive data by enabling customers
    to designate how much of the sensitive data to reveal with minimal impact on the application layer. 
    Let see how */
-- Step:1 Let us first get a view of CustomerPIIData table. 
SELECT * FROM CustomerPIIData;

-- Step:2 Let's confirm that there are no Dynamic Data Masking (DDM) applied on columns.
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl   
    ON c.[object_id] = tbl.[object_id]  
WHERE is_masked = 1 
    AND tbl.name = 'CustomerPIIData';
-- No results returned verify that no data masking has been done yet.

-- Step:3 Now lets mask 'CreditCard' and 'Email' Column of 'CustomerPIIData' table.
ALTER TABLE CustomerPIIData  
ALTER COLUMN [CreditCard] ADD MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX",4)');
GO
ALTER TABLE CustomerPIIData 
ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
GO
-- The columns are sucessfully masked.

-- Step:4 Let's see Dynamic Data Masking (DDM) applied on the two columns.
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl   
    ON c.[object_id] = tbl.[object_id]  
WHERE is_masked = 1 
    AND tbl.name ='CustomerPIIData';

-- Step:5 Now, let us grant SELECT permission to 'DemoUser1@CloudLabsAIoutlook.onmicrosoft.com' on the 'CustomerPIIData' table.
SELECT * FROM CustomerPIIData; 


----step:6 Reverting all the changes back to as it was.
ALTER TABLE CustomerPIIData
ALTER COLUMN CreditCard DROP MASKED;
GO
ALTER TABLE CustomerPIIData
ALTER COLUMN Email DROP MASKED;
GO
