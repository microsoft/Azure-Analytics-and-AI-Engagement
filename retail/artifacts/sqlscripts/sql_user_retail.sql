CREATE LOGIN [CEO]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [CEO] FOR LOGIN [CEO] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [DataAnalystMiami]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [DataAnalystMiami] FOR LOGIN [DataAnalystMiami] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [DataAnalystSanDiego]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [DataAnalystSanDiego] FOR LOGIN [DataAnalystSanDiego] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [DataAnalyst]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [DataAnalyst] FOR LOGIN [DataAnalyst] WITH DEFAULT_SCHEMA=[dbo];
	
CREATE LOGIN [TaxAuditor]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [TaxAuditor] FOR LOGIN [TaxAuditor] WITH DEFAULT_SCHEMA=[dbo];
	
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
