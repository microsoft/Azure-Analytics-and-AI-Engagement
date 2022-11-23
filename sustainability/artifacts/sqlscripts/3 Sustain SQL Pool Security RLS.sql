/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/*
/*	Row level Security (RLS) in Azure Synapse enables us to use group membership to control access to rows in a table.
	Azure Synapse applies the access restriction every time the data access is attempted from any user. 
	Let see how we can implement row level security in Azure Synapse.*/

----------------------------------Row-Level Security (RLS), 1: Filter predicates------------------------------------------------------------------
-- Step:1 The [Fleet-FactExpense] table has two Analyst values i.e. DataAnalystSurdatum and DataAnalystPalacidios
SELECT top 100 * FROM [Fleet-FactExpense] order by City ;

/* Moving ahead, we Create a new schema, and an inline table-valued function. 
The function returns 1 when a row in the Analyst column is the same as the user executing the query (@Analyst = USER_NAME())
 or if the user executing the query is the ChiefDataOfficer user (USER_NAME() = 'ChiefDataOfficer').
*/

--Step:2 To set up RLS, the following query creates three login users :  ChiefDataOfficer, DataAnalystSurdatum, DataAnalystPalacidios
Exec Sp_FleetRLS
GO
CREATE SCHEMA Security
GO
CREATE FUNCTION Security.fn_securitypredicate(@Analyst AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result
WHERE @Analyst = USER_NAME() OR USER_NAME() = 'ChiefDataOfficer'
GO
-- Now we define security policy that allows users to filter rows based on thier login name.
CREATE SECURITY POLICY ExpenseFilter  
ADD FILTER PREDICATE Security.fn_securitypredicate(Designation)
ON dbo.[Fleet-FactExpense]
WITH (STATE = ON);
------ Allow SELECT permissions to the fn_securitypredicate function.------
GRANT SELECT ON security.fn_securitypredicate TO ChiefDataOfficer, DataAnalystSurdatum, DataAnalystPalacidios;

-- Step:3 Let us now test the filtering predicate, by selecting data from the [Fleet-FactExpense] table as 'DataAnalystPalacidios' user.
EXECUTE AS USER = 'DataAnalystPalacidios'; 
SELECT * FROM [Fleet-FactExpense];
revert;
-- As we can see, the query has returned rows here Login name is DataAnalystSurdatum

-- Step:4 Let us test the same for  'DataAnalystSurdatum' user.
EXECUTE AS USER = 'DataAnalystSurdatum'; 
SELECT * FROM [Fleet-FactExpense];
revert;
-- RLS is working indeed.

-- Step:5 The ChiefDataOfficer should be able to see all rows in the table.
EXECUTE AS USER = 'ChiefDataOfficer';  
SELECT * FROM [Fleet-FactExpense];
revert;
-- And he can.

--Step:6 To disable the security policy we just created above, we execute the following.
ALTER SECURITY POLICY ExpenseFilter  
WITH (STATE = OFF);

DROP SECURITY POLICY ExpenseFilter;
DROP FUNCTION Security.fn_securitypredicate;
DROP SCHEMA Security;