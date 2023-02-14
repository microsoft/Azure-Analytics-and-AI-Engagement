SELECT TOP 100 [ControllerId], [LastUpdate], [Temperature], [AcPower], [DcPower], [UpForService]
FROM OPENROWSET(​PROVIDER = 'CosmosDB',
                CONNECTION = 'Account=#COSMOSDB_ACCOUNT_NAME#;Database=Telemetry',
                OBJECT = 'Controllers',
                SERVER_CREDENTIAL = '#COSMOSDB_ACCOUNT_NAME#'
) AS [Controllers]
WHERE [ControllerId] = 'f6eeba8d-08ea-4a50-8958-27c9943c6f46'
ORDER BY [LastUpdate] DESC