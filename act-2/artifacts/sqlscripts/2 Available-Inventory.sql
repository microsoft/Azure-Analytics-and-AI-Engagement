SELECT Top 100 [Region],[lastupdate],[Modelid],[Availableinventory]
FROM OPENROWSET(​PROVIDER = 'CosmosDB',
                CONNECTION = 'Account=#COSMOSDB_ACCOUNT_NAME#;Database=Telemetry',
                OBJECT = 'Inventory',
                SERVER_CREDENTIAL = '#COSMOSDB_ACCOUNT_NAME#'
) AS [Inventory]
ORDER BY [LastUpdate] DESC
