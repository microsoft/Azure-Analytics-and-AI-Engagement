CREATE LOGIN [BillingStaff]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [BillingStaff] FOR LOGIN [BillingStaff] WITH DEFAULT_SCHEMA=[dbo];
		
CREATE LOGIN [ChiefOperatingManager]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [ChiefOperatingManager] FOR LOGIN [ChiefOperatingManager] WITH DEFAULT_SCHEMA=[dbo];
   
   
CREATE LOGIN [CareManagerMiami]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [CareManagerMiami] FOR LOGIN [CareManagerMiami] WITH DEFAULT_SCHEMA=[dbo];
   
   
   CREATE LOGIN [CareManagerLosAngeles]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [CareManagerLosAngeles] FOR LOGIN [CareManagerLosAngeles] WITH DEFAULT_SCHEMA=[dbo];
   
      CREATE LOGIN [CareManager]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [CareManager] FOR LOGIN [CareManager] WITH DEFAULT_SCHEMA=[dbo];
   



