CREATE LOGIN [FacilityManager]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [FacilityManager] FOR LOGIN [FacilityManager] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [DataAnalystPalacidios]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [DataAnalystPalacidios] FOR LOGIN [DataAnalystPalacidios] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [DataAnalystSurdatum]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [DataAnalystSurdatum] FOR LOGIN [DataAnalystSurdatum] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [ChiefDataOfficer]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [ChiefDataOfficer] FOR LOGIN [ChiefDataOfficer] WITH DEFAULT_SCHEMA=[dbo];
