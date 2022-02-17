-- This is auto-generated code
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK 'https://#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/magentosource/MagentoData/Generated Data/GeneratedData.csv',
        FORMAT = 'CSV',
		PARSER_VERSION = '2.0'
    ) AS [Contosodataset]
