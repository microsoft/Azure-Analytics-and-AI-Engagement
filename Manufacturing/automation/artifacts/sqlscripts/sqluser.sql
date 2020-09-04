CREATE LOGIN [SalesStaff]  
    WITH PASSWORD = 'Smoothie@2020'
GO
    CREATE USER [SalesStaff] FOR LOGIN [SalesStaff] WITH DEFAULT_SCHEMA=[dbo];