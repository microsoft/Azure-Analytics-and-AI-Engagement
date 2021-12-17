CREATE LOGIN [TaxAuditor]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditor] FOR LOGIN [TaxAuditor] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [FraudInvestigator]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [FraudInvestigator] FOR LOGIN [FraudInvestigator] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [TaxAuditSuperviserSurDatum]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditSuperviserSurDatum] FOR LOGIN [TaxAuditSuperviserSurDatum] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [TaxAuditSuperviserSandonillo]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditSuperviserSandonillo] FOR LOGIN [TaxAuditSuperviserSandonillo] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [TaxAuditSuperviserStatiso]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditSuperviserStatiso] FOR LOGIN [TaxAuditSuperviserStatiso] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [TaxAuditSuperviserTanglat]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditSuperviserTanglat] FOR LOGIN [TaxAuditSuperviserTanglat] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [TaxAuditSuperviserPalacidios]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditSuperviserPalacidios] FOR LOGIN [TaxAuditSuperviserPalacidios] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [TaxAuditSuperviserNordEl]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditSuperviserNordEl] FOR LOGIN [TaxAuditSuperviserNordEl] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [AntiCorruptionUnitHead]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [AntiCorruptionUnitHead] FOR LOGIN [AntiCorruptionUnitHead] WITH DEFAULT_SCHEMA=[dbo];
	
		
CREATE LOGIN [TaxAuditSupervisor]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditSupervisor] FOR LOGIN [TaxAuditSupervisor] WITH DEFAULT_SCHEMA=[dbo];
	
	
CREATE LOGIN [TaxAuditorStatiso]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditorStatiso] FOR LOGIN [TaxAuditorStatiso] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [TaxAuditorSurDatum]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditorSurDatum] FOR LOGIN [TaxAuditorSurDatum] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [MarketingOwner]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [MarketingOwner] FOR LOGIN [MarketingOwner] WITH DEFAULT_SCHEMA=[dbo];
