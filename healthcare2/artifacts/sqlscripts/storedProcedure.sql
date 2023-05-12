SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_ChiefOperatingManager] AS 
Revert
GRANT SELECT ON Campaign_Analytics TO ChiefOperatingManager;  --Full access to all columns.
-- Step:6 Let us check if our ChiefOperatingManager user can see all the information that is present. Assign Current User As 'CEO' and the execute the query
EXECUTE AS USER ='ChiefOperatingManager'
select * from Campaign_Analytics
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_DAM_AC_New] AS 
GRANT SELECT ON Campaign_Analytics([Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State]) TO CareManagerMiami;
EXECUTE AS USER ='CareManagerMiami'
select [Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State] from Campaign_Analytics
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_DAM_F_New] AS 
BEGIN TRY
-- Generate a divide-by-zero error  
	
		GRANT SELECT ON Campaign_Analytics([Region],[Country],[Campaign_Name],[Revenue_Target],[CITY],[State]) TO CareManagerMiami;
		EXECUTE AS USER ='CareManagerMiami'
		select * from Campaign_Analytics
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

CREATE PROC [dbo].[CLS_VPGlobalOperations] AS 

GRANT SELECT ON Campaign_Analytics TO VPGlobalOperations;  --Full access to all columns.
-- Step:6 Let us check if our VP-GlobalOperations user can see all the information that is present. Assign Current User As 'VP-GlobalOperations' and the execute the query
EXECUTE AS USER ='VPGlobalOperations'
select * from Campaign_Analytics
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Confirm DDM] AS 
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl   ON c.[object_id] = tbl.[object_id]  WHERE 
is_masked = 1 and tbl.name='PatientInformation';
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_HealthCareRLS] AS 
Begin	
	-- After creating the users, read access is provided to all three users on FactSales table
	GRANT SELECT ON [HealthCare-FactSales] TO ChiefOperatingManager, CareManagerMiami, CareManagerLosAngeles;  

	IF EXISts (SELECT 1 FROM sys.security_predicates sp where sp.predicate_definition='([Security].[fn_securitypredicate]([SalesRep]))')
	BEGIN
		DROP SECURITY POLICY SalesFilter;
		DROP FUNCTION Security.fn_securitypredicate;
	END
	
	IF  EXISTS (SELECT * FROM sys.schemas where name='Security')
	BEGIN	
	DROP SCHEMA Security;
	End
	
	/* Moving ahead, we Create a new schema, and an inline table-valued function. 
	The function returns 1 when a row in the SalesRep column is the same as the user executing the query (@SalesRep = USER_NAME())
	or if the user executing the query is the Manager user (USER_NAME() = 'ChiefOperatingManager').
	*/
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_CareManagerLosAngeles] AS
EXECUTE AS USER = 'CareManagerLosAngeles'; 
SELECT * FROM [HealthCare-FactSales];
revert;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_CareManagerMiami] AS
EXECUTE AS USER = 'CareManagerMiami' 
SELECT * FROM [HealthCare-FactSales];
revert;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_ChiefOperatingManager] AS
EXECUTE AS USER = 'ChiefOperatingManager';  
SELECT * FROM [HealthCare-FactSales];
revert;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_VPGlobalOperations] AS
EXECUTE AS USER = 'VPGlobalOperations';  
SELECT * FROM [HealthCare-FactSales];
revert;
GO

