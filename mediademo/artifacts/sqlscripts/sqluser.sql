CREATE LOGIN [Reporter]  
    WITH PASSWORD = '#SQL_PASSWORD#'
GO
    CREATE USER [Reporter] FOR LOGIN [Reporter] WITH DEFAULT_SCHEMA=[dbo];
		
CREATE LOGIN [MediaAdministrator]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [MediaAdministrator] FOR LOGIN [MediaAdministrator] WITH DEFAULT_SCHEMA=[dbo];
   
   
CREATE LOGIN [ReporterLosAngeles]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [ReporterLosAngeles] FOR LOGIN [ReporterLosAngeles] WITH DEFAULT_SCHEMA=[dbo];
   
   
   CREATE LOGIN [CareManagerLosAngeles]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [CareManagerLosAngeles] FOR LOGIN [CareManagerLosAngeles] WITH DEFAULT_SCHEMA=[dbo];
   
      CREATE LOGIN [CareManager]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [CareManager] FOR LOGIN [CareManager] WITH DEFAULT_SCHEMA=[dbo];
   
CREATE LOGIN [ReporterMiami]
   WITH PASSWORD = '#SQL_PASSWORD#'
GO
   CREATE USER [ReporterMiami] FOR LOGIN [ReporterMiami] WITH DEFAULT_SCHEMA=[dbo];
   


