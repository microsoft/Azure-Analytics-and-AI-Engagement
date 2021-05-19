SELECT TOP 100 * 
FROM OPENROWSET('CosmosDB',
                'Account=#COSMOS_ACCOUNT#;Database=videoindexer;Key=#COSMOS_KEY#',
                videoindexerinsights) AS Indexer


GO          

SELECT JSON_VALUE(summarizedInsights,'$.keywords[0].name') InsightsName
FROM 
        OPENROWSET
        ('CosmosDB',
                'Account=#COSMOS_ACCOUNT#;Database=videoindexer;Key=#COSMOS_KEY#',
                videoindexerinsights
        ) AS Indexer
