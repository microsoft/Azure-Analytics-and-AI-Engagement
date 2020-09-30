CREATE LOGIN [SalesStaff]  
    WITH PASSWORD = 'Smoothie@2020'
GO
    CREATE USER [SalesStaff] FOR LOGIN [SalesStaff] WITH DEFAULT_SCHEMA=[dbo];
		
CREATE LOGIN [InventoryManager]
   WITH PASSWORD = 'Smoothie@2020'
GO

ALTER LOGIN [InventoryManager] DISABLE
GO
	CREATE USER [InventoryManager] WITH DEFAULT_SCHEMA=[dbo];

CREATE LOGIN [SalesStaffSanDiego] 
	 WITH PASSWORD = 'Smoothie@2020'
GO

ALTER LOGIN [SalesStaffSanDiego] DISABLE
GO
	CREATE USER [SalesStaffSanDiego] WITH DEFAULT_SCHEMA=[dbo];

CREATE LOGIN [SalesStaffMiami] 
	 WITH PASSWORD = 'Smoothie@2020'
GO

ALTER LOGIN [SalesStaffMiami] DISABLE
GO
	CREATE USER [SalesStaffMiami] WITH DEFAULT_SCHEMA=[dbo];

