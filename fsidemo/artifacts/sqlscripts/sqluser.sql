CREATE LOGIN [MarketingOfficer]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [MarketingOfficer] FOR LOGIN [MarketingOfficer] WITH DEFAULT_SCHEMA=[dbo];
		
CREATE LOGIN [MarketingOfficerMiami]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [MarketingOfficerMiami] FOR LOGIN [MarketingOfficerMiami] WITH DEFAULT_SCHEMA=[dbo];
   
   
CREATE LOGIN [MarketingOfficerSanDiego]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [MarketingOfficerSanDiego] FOR LOGIN [MarketingOfficerSanDiego] WITH DEFAULT_SCHEMA=[dbo];
   
   
   CREATE LOGIN [HeadOfFinancialIntelligence]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [HeadOfFinancialIntelligence] FOR LOGIN [HeadOfFinancialIntelligence] WITH DEFAULT_SCHEMA=[dbo];
   



	