-- Use 'SustainabilityOnDemand' Serverless SQL Database
Use SustainabilityOnDemand

-- Creating Cosmos DB Credential
IF (NOT EXISTS(SELECT * FROM sys.credentials WHERE name = '#COSMOSDB_ACCOUNT_NAME#'))
    CREATE CREDENTIAL [#COSMOSDB_ACCOUNT_NAME#]
    WITH IDENTITY = 'SHARED ACCESS SIGNATURE', SECRET = '#COSMOSDB_ACCOUNT_KEY#'
GO

-- Create or ALTER View
CREATE OR ALTER VIEW SustainBusridershipDBWithoutHTAP
AS 
SELECT BusNo,
EstimatedArrivalTime,
[Destination],
[ID],
[Occupancy],
Capacity,
[RouteVia],
DepartureTime
FROM OPENROWSET(PROVIDER = 'CosmosDB',
                CONNECTION = 'Account=#COSMOSDB_ACCOUNT_NAME#;Database=sustainbusridershipdb',
                OBJECT = 'Busridership',
                SERVER_CREDENTIAL = '#COSMOSDB_ACCOUNT_NAME#'
) AS [Busridership]


-- Step 2 
-- Lets view RetailInventory Data
SELECT * FROM SustainBusridershipDBWithoutHTAP

