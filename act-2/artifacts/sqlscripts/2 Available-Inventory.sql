-- Use 'SQLServerlessPool' Serverless SQL Database
Use SQLServerlessPool

-- Creating Cosmos DB Credential
IF (NOT EXISTS(SELECT * FROM sys.credentials WHERE name = '#COSMOSDB_ACCOUNT_NAME#'))
    CREATE CREDENTIAL [#COSMOSDB_ACCOUNT_NAME#]
    WITH IDENTITY = 'SHARED ACCESS SIGNATURE', SECRET = '#COSMOSDB_ACCOUNT_KEY#'
GO

SELECT Top 100 [Region],[lastupdate],[Modelid],[Availableinventory]
FROM OPENROWSET(​PROVIDER = 'CosmosDB',
                CONNECTION = 'Account=#COSMOSDB_ACCOUNT_NAME#;Database=Telemetry',
                OBJECT = 'Inventory',
                SERVER_CREDENTIAL = '#COSMOSDB_ACCOUNT_NAME#'
) AS [Inventory]
ORDER BY [LastUpdate] DESC
