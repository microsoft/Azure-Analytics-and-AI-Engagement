--Using Existing Database


---View The Campaign Data From CSV File 
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK 'https://#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/data-source/Campaign Data/campaign-data2.csv',
        FORMAT = 'CSV', HEADER_ROW = TRUE,
        PARSER_VERSION = '2.0'
    ) AS [result]

--- View Twitter Data From JSON File
SELECT
       JSON_VALUE (jsonContent, '$.hashtag') Hastag,
       JSON_VALUE (jsonContent, '$.city') City,
       JSON_VALUE (jsonContent, '$.retweetcount') Retweetcount,
       JSON_VALUE (jsonContent, '$.sentiment') Sentiment
FROM
    OPENROWSET(
        BULK 'https://#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/data-source/TwitterDataJson/*.json',
        FORMAT = 'CSV',
        FIELDQUOTE = '0x0b',
        FIELDTERMINATOR ='0x0b',
        ROWTERMINATOR = '0x0b'
    )
    WITH (
        jsonContent VARCHAR(MAX),
        Tweet varchar(MAX),
        City varchar(MAX),
        Hashtag VARCHAR(Max)
    ) AS [result]
-----Create View For Campaign Data
 CREATE or ALTER View Vw_CampaignData
As
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK 'https://#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/data-source/Campaign Data/campaign-data2.csv',
        FORMAT = 'CSV', HEADER_ROW = TRUE,
        PARSER_VERSION = '2.0'
    ) AS [result]

--- Create View For Twitter Data
CREATE or ALTER VIEW Vw_TwitterData
AS
SELECT
       JSON_VALUE (jsonContent, '$.hashtag') Hashtag,
       JSON_VALUE (jsonContent, '$.city') City,
       JSON_VALUE (jsonContent, '$.retweetcount') Retweetcount,
       JSON_VALUE (jsonContent, '$.sentiment') Sentiment
FROM
    OPENROWSET(
        BULK 'https://#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/data-source/TwitterDataJson/*.json',
        FORMAT = 'CSV',
        FIELDQUOTE = '0x0b',
        FIELDTERMINATOR ='0x0b',
        ROWTERMINATOR = '0x0b'
    )
    WITH (
        jsonContent VARCHAR(MAX),
        Tweet varchar(MAX),
        City varchar(MAX),
        Hashtag VARCHAR(Max)
    ) AS [result]

---Joining Twitter & Campaign Data
Select REPLACE(T.Hashtag,'#','') Hashtag,C.Cost,C.Revenue,C.ROI,C.Revenue_Target,T.Sentiment From Vw_CampaignData C Inner JOIN
Vw_TwitterData T On C.Campaign_Name= REPLACE(T.Hashtag,'#','')

