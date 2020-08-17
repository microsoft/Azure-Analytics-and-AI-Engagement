
-- Step:1(View the existing table 'CustomerInformation' Data) 
select top 100 * from CustomerInformation

-- Step:2 Let's confirm that there are no Dynamic Data Masking (DDM) applied on columns
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl   ON c.[object_id] = tbl.[object_id]  WHERE is_masked = 1;
-- No results returned verify that no data masking has been done yet.

-- Step:3 Now lets mask 'CreditCard' and 'Email' Column of 'CustomerInformation' table.
ALTER TABLE CustomerInformation  
ALTER COLUMN [CreditCard] ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-XXXX-",4)')
GO
ALTER TABLE CustomerInformation 
Alter Column Email ADD MASKED WITH (FUNCTION = 'email()')
GO
-- The columns are sucessfully masked.

-- Step:4 Let's see Dynamic Data Masking (DDM) applied on the two columns.
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl ON c.[object_id] = tbl.[object_id]  WHERE is_masked = 1;

-- Step:5 Now, let us grant SELECT permission to 'SalesStaff'sysusers on the 'CustomerInformation' table.
SELECT Name as [User] FROM sys.sysusers WHERE name = N'SalesStaff'
GRANT SELECT ON CustomerInformation TO SalesStaff;  

-- Step:6 Logged in as  'SalesStaff' let us execute the select query and view the result.
EXECUTE AS USER =N'SalesStaff';  
SELECT  * FROM CustomerInformation; 

-- Step:7 Let us Remove the data masking using UNMASK permission
GRANT UNMASK TO SalesStaff
EXECUTE AS USER = 'SalesStaff';  
SELECT top 10 * FROM CustomerInformation; 
revert; 
REVOKE UNMASK TO SalesStaff;  

----step:8 Reverting all the changes back to as it was.
ALTER TABLE CustomerInformation
ALTER COLUMN CreditCard DROP MASKED;
GO
ALTER TABLE CustomerInformation
ALTER COLUMN Email DROP MASKED;
GO