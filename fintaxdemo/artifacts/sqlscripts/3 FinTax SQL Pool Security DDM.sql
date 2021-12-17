/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/*

-- Step:1(View the existing table 'Taxpayers' Data) 

select top 100 * from [Fact-Invoices]

-- Step:2 Let's confirm that there are no Dynamic Data Masking (DDM) applied on columns

Exec [Confirm DDM]

-- No results returned verify that no data masking has been done yet.

-- Step:3 Now lets mask 'TaxpayerID' Column of '[Fact-Invoices]' table.

ALTER TABLE [Fact-Invoices] 
ALTER Column TaxpayerID ADD MASKED WITH (FUNCTION = 'partial(1,"XXXXX",1)')


-- The columns are sucessfully masked.

-- Step:4 Let's see Dynamic Data Masking (DDM) applied on the TaxpayerID column.

Exec [Confirm DDM]

-- Step:5 Now, let us grant SELECT permission to 'TaxAuditor'sysusers on the '[Fact-Invoices]' table.

SELECT Name as [User] FROM sys.sysusers WHERE name = N'TaxAuditor'
Exec sp_GrantSelectTaxAuditor --Grant SELECT on CustomerInfo for TaxAuditor

-- Step:6 Logged in as 'TaxAuditor' let us execute the select query and view the result.

EXECUTE AS USER =N'TaxAuditor';  
SELECT  * FROM [Fact-Invoices]; 

-- Step:7 Let us Remove the data masking using UNMASK permission

Exec sp_GrantUnmaskTaxAuditor --Grant unmask to TaxAuditor User
EXECUTE AS USER = 'TaxAuditor';  
SELECT top 10 * FROM [Fact-Invoices]; 


----step:8 Reverting all the changes back to as it was.

ALTER TABLE [Fact-Invoices] 
Alter Column TaxpayerID DROP MASKED;
GO
