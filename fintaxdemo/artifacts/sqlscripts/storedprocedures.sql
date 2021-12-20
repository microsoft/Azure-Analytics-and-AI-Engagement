SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_AntiCorruptionUnitHead] AS 

GRANT SELECT ON FactInvoicesData TO AntiCorruptionUnitHead;  --Full access to all columns.

-- Step:6 Let us check if our AntiCorruptionUnitHead user can see all the information that is present. Assign Current User As 'AntiCorruptionUnitHead' and the execute the query

EXECUTE AS USER ='AntiCorruptionUnitHead'
select * from FactInvoicesData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_DAM_AC_New] AS 
GRANT SELECT ON FactInvoicesData ([TaxpayerID], [Region], [State], [Industry], [TaxableAmount], [TaxAmount]) TO TaxAuditor;
EXECUTE AS USER ='TaxAuditor'
select [TaxpayerID], [Region], [State], [Industry], [TaxableAmount], [TaxAmount] from FactInvoicesData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_DAM_F_New] AS 
BEGIN TRY
-- Generate a divide-by-zero error  
	
		GRANT SELECT ON FactInvoicesData ([TaxpayerID], [Region], [State], [Industry], [TaxableAmount], [TaxAmount]) TO TaxAuditor;
		EXECUTE AS USER ='TaxAuditor'
		select * from FactInvoicesData
END TRY
BEGIN CATCH
	SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		
		ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Confirm DDM] AS 
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl   ON c.[object_id] = tbl.[object_id]  WHERE 
is_masked = 1 and tbl.name='Fact-Invoices';
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_CleanUpRLS] AS
    EXECUTE AS USER = 'MarketingOwner';
    BEGIN
    DECLARE @sql1 nvarchar(4000) = 'ALTER SECURITY POLICY SalesFilter  
        WITH (STATE = OFF);'
    DECLARE @sql2 nvarchar(4000) = 'DROP SECURITY POLICY SalesFilter;'
    DECLARE @sql3 nvarchar(4000) = 'DROP FUNCTION Security.fn_securitypredicate;'
    DECLARE @sql4 nvarchar(4000) = 'DROP SCHEMA Security;'
    EXEC sp_executesql @sql1
    EXEC sp_executesql @sql2
    EXEC sp_executesql @sql3
    EXEC sp_executesql @sql4
    END
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_CreateSecuritySchema] AS
    EXECUTE AS USER = 'MarketingOwner';
    BEGIN
    DECLARE @sql nvarchar(4000) = 'create schema Security'
    EXEC sp_executesql @sql
    END
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_CreateSecurityFunction] AS
    EXECUTE AS USER = 'MarketingOwner';
    BEGIN
    DECLARE @sql nvarchar(4000) = 'CREATE FUNCTION Security.fn_securitypredicate(@Analyst AS sysname)  
        RETURNS TABLE  
        WITH SCHEMABINDING  
        AS  
        RETURN SELECT 1 AS fn_securitypredicate_result
        WHERE USER_NAME() = ''TaxAuditSupervisor'' OR @Analyst = USER_NAME()'
    EXEC sp_executesql @sql
    END
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_CreateSecurityPolicy] AS
    EXECUTE AS USER = 'MarketingOwner';
    BEGIN
    DECLARE @sql nvarchar(4000) = 'CREATE SECURITY POLICY SalesFilter  
        ADD FILTER PREDICATE Security.fn_securitypredicate(Designation)
        ON dbo.[FactInvoices]
        WITH (STATE = ON);'
    EXEC sp_executesql @sql
    END
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_FinTaxRLS] AS
EXECUTE AS USER = 'MarketingOwner' 
Begin	
	-- After creating the users, read access is provided to all three users on FactInvoices table
	GRANT SELECT ON [FactInvoices] TO FraudInvestigator, TaxAuditSuperviserSurDatum, TaxAuditSuperviserSandonillo, TaxAuditSuperviserStatiso, TaxAuditSuperviserTanglat, TaxAuditSuperviserPalacidios, TaxAuditSuperviserNordEl;  

	IF EXISts (SELECT 1 FROM sys.security_predicates sp where sp.predicate_definition='([Security].[fn_securitypredicate]([Designation]))')
	BEGIN
		DROP SECURITY POLICY SupervisorFilter;
		DROP FUNCTION Security.fn_securitypredicate;
	END
	
	IF  EXISTS (SELECT * FROM sys.schemas where name='Security')
	BEGIN	
	DROP SCHEMA Security;
	End
	
	/* Moving ahead, we Create a new schema, and an inline table-valued function. 
	The function returns 1 when a row in the Designation column is the same as the user executing the query (@Designation = USER_NAME())
	or if the user executing the query is the Manager user (USER_NAME() = 'FraudInvestigator').
	*/
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_GrantFullSelectFactInvoicesData] AS
    EXECUTE AS USER = 'AntiCorruptionUnitHead'
    GRANT SELECT ON FactInvoicesData TO AntiCorruptionUnitHead; 
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_GrantSelectSecurityPredicate] AS
    EXECUTE AS USER = 'MarketingOwner'
    GRANT SELECT ON security.fn_securitypredicate TO TaxAuditSupervisor, TaxAuditorStatiso, TaxAuditorSurDatum;
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_GrantSelectTaxAuditor] AS
    EXECUTE AS USER =N'TaxAuditor';
    GRANT SELECT ON [Fact-Invoices] TO TaxAuditor;  
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_GrantUnmaskTaxAuditor] AS
    EXECUTE AS USER = 'TaxAuditor'
    GRANT UNMASK TO TaxAuditor
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_GrantLimitedSelectFactInvoicesData] AS
    EXECUTE AS USER = 'TaxAuditor'
    GRANT SELECT ON FactInvoicesData ([TaxpayerID], [Region], [State], [Industry], [TaxableAmount], [TaxAmount]) TO TaxAuditor;
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_RevokeUnmaskTaxAuditor] AS
    EXECUTE AS USER = 'MarketingOwner'
    REVOKE UNMASK TO TaxAuditor
    REVERT;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_TaxAuditorStatiso] AS
EXECUTE AS USER = 'TaxAuditorStatiso' 
SELECT * FROM [FactInvoices];
revert;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_TaxAuditorSurDatum] AS
EXECUTE AS USER = 'TaxAuditorSurDatum' 
SELECT * FROM [FactInvoices];
revert;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_TaxAuditSupervisor] AS
EXECUTE AS USER = 'TaxAuditSupervisor';  
SELECT * FROM [FactInvoices];
revert;
GO	