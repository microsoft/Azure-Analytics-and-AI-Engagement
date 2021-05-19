-- Step:1(View the existing table 'CustomerInfo' Data) 
select top 100 * from CustomerInfo

-- Step:2 Let's confirm that there are no Dynamic Data Masking (DDM) applied on columns
Exec [Confirm DDM]
-- No results returned verify that no data masking has been done yet.

-- Step:3 Now lets mask 'CreditCardCard' and 'Email' Column of 'CustomerInfo' table.
ALTER TABLE CustomerInfo  
ALTER COLUMN [CreditCard] ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-XXXX-",4)')
GO
ALTER TABLE CustomerInfo 
Alter Column Email ADD MASKED WITH (FUNCTION = 'email()')
GO
-- The columns are sucessfully masked.

-- Step:4 Let's see Dynamic Data Masking (DDM) applied on the two columns.
Exec [Confirm DDM]

-- Step:5 Now, let us grant SELECT permission to 'Reporter'sysusers on the 'CustomerInfo' table.
SELECT Name as [User] FROM sys.sysusers WHERE name = N'Reporter'
GRANT SELECT ON CustomerInfo TO Reporter;  

-- Step:6 Logged in as  'Reporter' let us execute the select query and view the result.
EXECUTE AS USER =N'Reporter';  
SELECT  * FROM CustomerInfo; 

-- Step:7 Let us Remove the data masking using UNMASK permission
GRANT UNMASK TO Reporter
EXECUTE AS USER = 'Reporter';  
SELECT top 10 * FROM CustomerInfo; 
revert; 
REVOKE UNMASK TO Reporter;  

----step:8 Reverting all the changes back to as it was.
ALTER TABLE CustomerInfo
ALTER COLUMN [CreditCard] DROP MASKED;
GO
ALTER TABLE CustomerInfo
ALTER COLUMN Email DROP MASKED;
GO