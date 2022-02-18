--∗∗∗∗∗∗∗∗∗∗ Important – Do not use in production, for demonstration purposes only – please review the legal notices before continuing ∗∗∗∗∗--

SELECT TOP 100 *
FROM OPENROWSET(​PROVIDER = 'CosmosDB',
                CONNECTION = 'Account=#COSMOSDB_ACCOUNT_NAME#;Database=retail-foottraffic',
                OBJECT = 'retailcosmos',
                SERVER_CREDENTIAL = '#COSMOSDB_ACCOUNT_NAME#'
) AS [retailcosmos]

