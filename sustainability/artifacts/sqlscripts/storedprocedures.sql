SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_ChiefDataOfficer] AS 
Revert;
GRANT SELECT ON Vehicle_Analytics TO ChiefDataOfficer;  --Full access to all columns.
-- Step:6 Let us check if our ChiefDataOfficer user can see all the information that is present. Assign Current User As 'CEO' and the execute the query
EXECUTE AS USER ='ChiefDataOfficer'
select * from Vehicle_Analytics


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_DAM_AC_New] AS 
GRANT SELECT ON Vehicle_Analytics (VehicleID,Fueltype,Mileage,Year,Months,Distance,FuelConsumption,[CO2Emission(kg)],Date,FuelCost,VehicleType) TO DataAnalystSurdatum;
EXECUTE AS USER ='DataAnalystSurdatum'
select VehicleID,Fueltype,Mileage,Year,Months,Distance,FuelConsumption,[CO2Emission(kg)],Date,FuelCost,VehicleType 
from Vehicle_Analytics


GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CLS_DAM_F_New] AS 
BEGIN TRY
	
		GRANT SELECT ON Vehicle_Analytics (VehicleID,Fueltype,Mileage,Year,Months,Distance,FuelConsumption,[CO2Emission(kg)],Date,FuelCost,VehicleType) TO DataAnalystSurdatum;
		EXECUTE AS USER ='DataAnalystSurdatum'
		select * from Vehicle_Analytics
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
is_masked = 1 and tbl.name='TweeterUserInfo';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[PushData] AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
INSERT INTO [Fact_Airqualitydetails]
SELECT  * from Temp


END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_FinanceRLS] AS 
Begin	
	-- After creating the users, read access is provided to all three users on FactSales table
	GRANT SELECT ON [Facility-FactSales] TO ChiefDataOfficer, DataAnalystSurdatum, DataAnalystSanDiego;  

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

CREATE PROC [dbo].[Sp_FleetRLS] AS 
Begin	
	-- After creating the users, read access is provided to all three users on FactExpense table
	GRANT SELECT ON [Fleet-FactExpense] TO ChiefDataOfficer, DataAnalystSurdatum, DataAnalystPalacidios;  

	IF EXISts (SELECT 1 FROM sys.security_predicates sp where sp.predicate_definition='([Security].[fn_securitypredicate]([TranOfficer]))')
	BEGIN
		DROP SECURITY POLICY ExpenseFilter;
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

CREATE PROC [dbo].[Sp_Mask_DDM] AS 
ALTER TABLE TweeterUserInfo  
ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-XXXX-",4)');
ALTER TABLE TweeterUserInfo 
Alter Column Email ADD MASKED WITH (FUNCTION = 'email()');

EXECUTE AS USER =N'FacilityManager';  
SELECT  * FROM TweeterUserInfo; 

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_CEO] AS
EXECUTE AS USER = 'ChiefDataOfficer';  
SELECT * FROM [Fleet-FactExpense];
revert;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_DataAnalystMiami] AS
EXECUTE AS USER = 'DataAnalystSurdatum'; 
SELECT * FROM [Fleet-FactExpense];
revert;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_DataAnalystPalacidios] AS
EXECUTE AS USER = 'DataAnalystPalacidios'; 
SELECT * FROM [Fleet-FactExpense];
revert;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_DataAnalystSanDiego] AS
EXECUTE AS USER = 'DataAnalystSanDiego'; 
SELECT * FROM [Fleet-FactExpense];
revert;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_RLS_DataAnalystSurdatum] AS
EXECUTE AS USER = 'DataAnalystSurdatum'; 
SELECT * FROM [Fleet-FactExpense];
revert;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_UnMask_DDM] AS 

GRANT UNMASK TO FacilityManager
EXECUTE AS USER = 'FacilityManager';  
SELECT  * FROM TweeterUserInfo; 
revert; 
REVOKE UNMASK TO FacilityManager;  

----step:8 Reverting all the changes back to as it was.
ALTER TABLE TweeterUserInfo
ALTER COLUMN Phone DROP MASKED;

GO