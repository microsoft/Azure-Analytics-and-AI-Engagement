--?????????? Important - Do not use in production, for demonstration purposes only - please review the legal notices before continuing ?????--
/*	Row level Security (RLS) in Azure Synapse enables us to use group membership to control access to rows in a table.
	Azure Synapse applies the access restriction every time the data access is attempted from any user. 
	Let see how we can implement row level security in Azure Synapse.*/

----------------------------------Row-Level Security (RLS), 1: Filter predicates------------------------------------------------------------------
-- Step:1 The FactSales table has two Analyst values i.e. DataAnalystMiami and DataAnalystSanDiego
SELECT  * FROM FactSales order by Analyst ;

/* Moving ahead, we Create a new schema, and an inline table-valued function. 
The function returns 1 when a row in the Analyst column is the same as the user executing the query (@Analyst = USER_NAME())
 or if the user executing the query is the CEO user (USER_NAME() = 'CEO').
*/

-- Demonstrate the existing security predicates already deployed to the database
SELECT * FROM sys.security_predicates

--Step:2 To set up RLS, the following query creates three login users :  CEO, DataAnalystMiami, DataAnalystSanDiego
EXEC dbo.Sp_rls;
GO

CREATE SCHEMA Security
GO
CREATE FUNCTION Security.fn_securitypredicate(@Analyst AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result
    WHERE @Analyst = USER_NAME() OR USER_NAME() = 'CEO'
GO

-- Now we define security policy that allows users to filter rows based on thier login name.
CREATE SECURITY POLICY SalesFilter  
ADD FILTER PREDICATE Security.fn_securitypredicate(Analyst)
ON dbo.FactSales
WITH (STATE = ON);
------ Allow SELECT permissions to the fn_securitypredicate function.------
GRANT SELECT ON security.fn_securitypredicate TO CEO, DataAnalystMiami, DataAnalystSanDiego;

-- Step:3 Let us now test the filtering predicate, by selecting data from the FactSales table as 'DataAnalystMiami' user.
GO

EXECUTE AS USER = 'DataAnalystMiami' 
SELECT * FROM FactSales;
revert;
-- As we can see, the query has returned rows here Login name is DataAnalystMiami

-- Step:4 Let us test the same for  'DataAnalystSanDiego' user.
GO

EXECUTE AS USER = 'DataAnalystSanDiego'; 
SELECT * FROM FactSales;
revert;
-- RLS is working indeed.

-- Step:5 The CEO should be able to see all rows in the table.
GO

EXECUTE AS USER = 'CEO';  
SELECT * FROM FactSales;
revert;
-- And he can.

--Step:6 To disable the security policy we just created above, we execute the following.
GO

ALTER SECURITY POLICY SalesFilter  
WITH (STATE = OFF);

DROP SECURITY POLICY SalesFilter;
DROP FUNCTION Security.fn_securitypredicate;
DROP SCHEMA Security;

