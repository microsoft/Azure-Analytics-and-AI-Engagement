/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/*

/*	Row level Security (RLS) in Azure Synapse enables us to use group membership to control access to rows in a table.
	Azure Synapse applies the access restriction every time the data access is attempted from any user. 
	Let see how we can implement row level security in Azure Synapse.*/

----------------------------------Row-Level Security (RLS), 1: Filter predicates------------------------------------------------------------------

-- Step:1 The FactInvoices table has 6 Auditor values i.e. TaxAuditorSurDatum, TaxAuditSuperviserSandonillo, TaxAuditorStatiso, TaxAuditSuperviserTanglat, TaxAuditSuperviserPalacidios and TaxAuditSuperviserNordEl

SELECT top 100 * FROM FactInvoices order by State ;

/* Moving ahead, we Create a new schema, and an inline table-valued function. 
The function returns 1 when a row in the Auditor column is the same as the user executing the query (@Auditor = USER_NAME())
 or if the user executing the query is the TaxAuditSupervisor user (USER_NAME() = 'TaxAuditSupervisor').
*/

--Step:2 To set up RLS, the following query creates 7 login users :  TaxAuditSupervisor, TaxAuditorSurDatum, TaxAuditSuperviserSandonillo, TaxAuditorStatiso, TaxAuditSuperviserTanglat, TaxAuditSuperviserPalacidios and TaxAuditSuperviserNordEl

Exec Sp_FinTaxRLS
GO
EXEC sp_CreateSecuritySchema 
    -- Stored Procedure Executes the following code: 
        -- CREATE SCHEMA Security
GO
EXEC sp_CreateSecurityFunction
    -- Stored Procedure Executes the following code:
        --  CREATE FUNCTION Security.fn_securitypredicate(@Analyst AS sysname)  
        --      RETURNS TABLE  
        --  WITH SCHEMABINDING  
        --  AS  
        --      RETURN SELECT 1 AS fn_securitypredicate_result
        --  WHERE @Analyst = USER_NAME() OR USER_NAME() = 'TaxAuditSupervisor'
GO
-- Now we define security policy that allows users to filter rows based on thier login name.
EXEC sp_CreateSecurityPolicy
    -- Stored Procedure Executes the following code:
        --  CREATE SECURITY POLICY SalesFilter  
        --  ADD FILTER PREDICATE Security.fn_securitypredicate(Designation)
        --  ON dbo.[FactInvoices]
        --  WITH (STATE = ON);        
------ Allow SELECT permissions to the fn_securitypredicate function.------
EXEC sp_GrantSelectSecurityPredicate
    -- Stored Procedure Executes the following code:
        --  GRANT SELECT ON security.fn_securitypredicate TO TaxAuditSupervisor, TaxAuditorSurDatum, TaxAuditorStatiso;

-- Step:3 Let us now test the filtering predicate, by selecting data from theFactInvoices table as 'TaxAuditorSurDatum' user.

EXECUTE AS USER = 'TaxAuditorSurDatum'; 
SELECT * FROM FactInvoices;
revert;
-- As we can see, the query has returned rows here Login name is TaxAuditorSurDatum

-- Step:4 Let us test the same for  'TaxAuditorStatiso' user.

EXECUTE AS USER = 'TaxAuditorStatiso'; 
SELECT * FROM FactInvoices;
revert;
-- RLS is working indeed.

-- Step:5 The TaxAuditSupervisor should be able to see all rows in the table.

EXECUTE AS USER = 'TaxAuditSupervisor';  
SELECT * FROM FactInvoices;
revert;
-- And he can.

--Step:6 To disable the security policy we just created above, we execute the following.
EXEC sp_CleanUpRLS
    -- Stored Procedure Executes the following code:
    --  ALTER SECURITY POLICY SalesFilter  
    --  WITH (STATE = OFF);

    --  DROP SECURITY POLICY SalesFilter;
    --  DROP FUNCTION Security.fn_securitypredicate;
    --  DROP SCHEMA Security;