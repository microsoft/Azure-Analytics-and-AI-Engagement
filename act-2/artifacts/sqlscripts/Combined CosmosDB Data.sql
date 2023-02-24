SELECT distinct TOP 10 Inventory.Region,
           Inventory.Modelid,
           Inventory.Lastupdate,
           AcPower,
           DcPower,
           Temperature,
           UpForService,
           Inventory.AvailableInventory
    FROM        OPENROWSET(​PROVIDER = 'CosmosDB',
                CONNECTION = 'Account=#COSMOSDB_ACCOUNT_NAME#;Database=Telemetry',
                OBJECT = 'Inventory',
                SERVER_CREDENTIAL = '#COSMOSDB_ACCOUNT_NAME#'
) AS [Inventory]
Left JOIN      OPENROWSET(​PROVIDER = 'CosmosDB', CONNECTION = 'Account=#COSMOSDB_ACCOUNT_NAME#;Database=Telemetry', 
                OBJECT = 'Controllers', SERVER_CREDENTIAL = '#COSMOSDB_ACCOUNT_NAME#'
                ) AS [Controllers] 
                ON Inventory.Modelid=Controllers.ModelId