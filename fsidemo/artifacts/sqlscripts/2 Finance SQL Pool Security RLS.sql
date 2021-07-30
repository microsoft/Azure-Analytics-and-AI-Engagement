/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/
/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code 
(1) is not subject to SOC 1 and SOC 2 compliance audits, and 
(2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial 
services professional. Do not use this code to replace, substitute, or provide professional financial advice, or judgement. You are solely 
responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations 
or consents, and any solution you choose to build that incorporates this code in whole or in part.  */

/*	Row level Security (RLS) in Azure Synapse enables us to use group membership to control access to rows in a table.
	Azure Synapse applies the access restriction every time the data access is attempted from any user. 
	Let see how we can implement row level security in Azure Synapse.*/

----------------------------------Row-Level Security (RLS), 1: Filter predicates------------------------------------------------------------------
-- Step:1 The [Finance-FactSales] table has two Analyst values i.e. MarketingOfficerMiami and MarketingOfficerSanDiego
SELECT top 100 * FROM [Finance-FactSales] order by City ;

/* Moving ahead, we Create a new schema, and an inline table-valued function. 
The function returns 1 when a row in the Analyst column is the same as the user executing the query (@Analyst = USER_NAME())
 or if the user executing the query is the HeadOfFinancialIntelligence user (USER_NAME() = 'HeadOfFinancialIntelligence').
*/

--Step:2 To set up RLS, the following query creates three login users :  HeadOfFinancialIntelligence, MarketingOfficerMiami, MarketingOfficerSanDiego
Exec Sp_FinanceRLS
GO
CREATE SCHEMA Security
GO
CREATE FUNCTION Security.fn_securitypredicate(@Analyst AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result
WHERE @Analyst = USER_NAME() OR USER_NAME() = 'HeadOfFinancialIntelligence'
GO
-- Now we define security policy that allows users to filter rows based on thier login name.
CREATE SECURITY POLICY SalesFilter  
ADD FILTER PREDICATE Security.fn_securitypredicate(Designation)
ON dbo.[Finance-FactSales]
WITH (STATE = ON);
------ Allow SELECT permissions to the fn_securitypredicate function.------
GRANT SELECT ON security.fn_securitypredicate TO HeadOfFinancialIntelligence, MarketingOfficerMiami, MarketingOfficerSanDiego;

-- Step:3 Let us now test the filtering predicate, by selecting data from the [Finance-FactSales] table as 'MarketingOfficerMiami' user.
EXECUTE AS USER = 'MarketingOfficerMiami'; 
SELECT * FROM [Finance-FactSales];
revert;
-- As we can see, the query has returned rows here Login name is MarketingOfficerMiami

-- Step:4 Let us test the same for  'MarketingOfficerSanDiego' user.
EXECUTE AS USER = 'MarketingOfficerSanDiego'; 
SELECT * FROM [Finance-FactSales];
revert;
-- RLS is working indeed.

-- Step:5 The HeadOfFinancialIntelligence should be able to see all rows in the table.
EXECUTE AS USER = 'HeadOfFinancialIntelligence';  
SELECT * FROM [Finance-FactSales];
revert;
-- And he can.

--Step:6 To disable the security policy we just created above, we execute the following.
ALTER SECURITY POLICY SalesFilter  
WITH (STATE = OFF);

DROP SECURITY POLICY SalesFilter;
DROP FUNCTION Security.fn_securitypredicate;
DROP SCHEMA Security;