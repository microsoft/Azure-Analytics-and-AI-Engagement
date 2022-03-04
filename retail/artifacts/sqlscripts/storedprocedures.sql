SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_AntiCorruptionUnitHead] AS 

GRANT SELECT ON Campaign_Analytics TO CEO;  --Full access to all columns.

-- Step:6 Let us check if our AntiCorruptionUnitHead user can see all the information that is present. Assign Current User As 'AntiCorruptionUnitHead' and the execute the query

EXECUTE AS USER ='CEO'
select * from Campaign_Analytics
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_DAM_AC_New] AS 
GRANT SELECT ON Campaign_Analytics([Region],[Country],[Product_Category],[Campaign_Name],[Revenue_Target],[City],[State]) TO DataAnalystMiami;
EXECUTE AS USER ='DataAnalystMiami'
select [Region],[Country],[Product_Category],[Campaign_Name],[Revenue_Target],
[City],[state] from Campaign_Analytics
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_DAM_F_New] AS 
BEGIN TRY
-- Generate a divide-by-zero error  
	
		GRANT SELECT ON Campaign_Analytics([Region],[Country],[Product_Category],[Campaign_Name],[Revenue_Target],[City],[State]) TO DataAnalystMiami;
		EXECUTE AS USER ='DataAnalystMiami'
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

CREATE PROC [dbo].[Sp_rls] AS 
Begin	
	-- After creating the users, read access is provided to all three users on FactSales table
	GRANT SELECT ON FactSales TO CEO, DataAnalystMiami, DataAnalystSanDiego;  

	--IF EXISTS (SELECT 1 FROM sys.security_predicates sp where sp.predicate_definition='([Security].[fn_securitypredicate]([SalesRep]))')
	IF EXISTS (SELECT 1 FROM sys.security_predicates sp where sp.predicate_definition='([Security].[fn_securitypredicate]([Analyst]))')
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
	or if the user executing the query is the Manager user (USER_NAME() = 'CEO').
	*/
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_CEO] AS
EXECUTE AS USER = 'CEO';  
SELECT * FROM [FactSales];
revert;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_DataAnalystMiami] AS
EXECUTE AS USER = 'DataAnalystMiami' 
SELECT * FROM [FactSales];
revert;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_DataAnalystSanDiego] AS
EXECUTE AS USER = 'DataAnalystSanDiego';  
SELECT * FROM [FactSales];
revert;
GO
