-- Use 'SQLServerlessPool' Serverless SQL Database
Use SQLServerlessPool


SELECT TOP 100 *
FROM OPENROWSET(
    'CosmosDB',
    'account=#COSMOSDB_ACCOUNT_NAME#;database=healthcare;region=#REGION#;key=#COSMOSDB_ACCOUNT_KEY#',
    SynapseLinkLabData
) AS [SynapseLinkLabData]
