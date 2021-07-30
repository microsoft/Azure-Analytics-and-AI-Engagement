/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/
/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code 
(1) is not subject to SOC 1 and SOC 2 compliance audits, and 
(2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial 
services professional. Do not use this code to replace, substitute, or provide professional financial advice, or judgement. You are solely 
responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations 
or consents, and any solution you choose to build that incorporates this code in whole or in part.  */

-- Step:1(View the existing table 'CustomerInfo' Data) 
select top 100 * from CustomerInfo

-- Step:2 Let's confirm that there are no Dynamic Data Masking (DDM) applied on columns
Exec [Confirm DDM]
-- No results returned verify that no data masking has been done yet.

-- Step:3 Now lets mask 'Medical Insurance Card' and 'Email' Column of 'CustomerInfo' table.
ALTER TABLE CustomerInfo  
ALTER COLUMN [CreditCard] ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-XXXX-",4)')
GO
ALTER TABLE CustomerInfo 
Alter Column Email ADD MASKED WITH (FUNCTION = 'email()')
GO
-- The columns are sucessfully masked.

-- Step:4 Let's see Dynamic Data Masking (DDM) applied on the two columns.
Exec [Confirm DDM]

-- Step:5 Now, let us grant SELECT permission to 'MarketingOfficer'sysusers on the 'CustomerInfo' table.
SELECT Name as [User] FROM sys.sysusers WHERE name = N'MarketingOfficer'
GRANT SELECT ON CustomerInfo TO MarketingOfficer;  

-- Step:6 Logged in as  'MarketingOfficer' let us execute the select query and view the result.
EXECUTE AS USER =N'MarketingOfficer';  
SELECT  * FROM CustomerInfo; 

-- Step:7 Let us Remove the data masking using UNMASK permission
GRANT UNMASK TO MarketingOfficer
EXECUTE AS USER = 'MarketingOfficer';  
SELECT top 10 * FROM CustomerInfo; 
revert; 
REVOKE UNMASK TO MarketingOfficer;  

----step:8 Reverting all the changes back to as it was.
ALTER TABLE CustomerInfo
ALTER COLUMN [CreditCard] DROP MASKED;
GO
ALTER TABLE CustomerInfo
ALTER COLUMN Email DROP MASKED;
GO