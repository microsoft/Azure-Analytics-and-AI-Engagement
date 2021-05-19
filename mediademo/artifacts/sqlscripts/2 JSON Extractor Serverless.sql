-- This is auto-generated code
SELECT TOP 100
    JSON_VALUE (jsonContent,'$.accountId') AS AccountId,
	JSON_VALUE (jsonContent, '$.video_id') AS VideoId,
    JSON_VALUE (jsonContent, '$.name') AS Name,
	JSON_VALUE (jsonContent, '$.topics_name') AS TopicsName,
	JSON_VALUE (jsonContent, '$.transcript') AS Transcript   
FROM
    OPENROWSET(
        BULK 'https://#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/finalmediademostorage/*.json',
        FORMAT = 'CSV',
        FIELDQUOTE = '0x0b',
        FIELDTERMINATOR ='0x0b',
        ROWTERMINATOR = '0x0b'
    )
    WITH (
        jsonContent varchar(MAX)
    ) AS [result]