/********************************************************************************
Get Sentiment Records
********************************************************************************/
SELECT
    CoreRecord.VideoId
    , CoreRecord.VideoFileName
    , CoreRecord.CreatedOn
    , SentimentInstances.SentimentId
    , SentimentInstances.SentimentType
    , SentimentInstances.SentimentScore
    , SentimentInstanceRecords.DurationStart
    , SentimentInstanceRecords.DurationEnd
FROM
    OPENROWSET(
        'CosmosDB'
        , 'Account=#COSMOS_ACCOUNT#;Database=videoindexer;Key=#COSMOS_KEY#'
        , videoindexerinsights)
WITH 
    ( 
    VideoId VARCHAR(1000) '$.id'
    , VideoFileName VARCHAR(MAX) '$.name'
    , CreatedOn VARCHAR(MAX) '$.created'
    , Videos varchar(max) '$.videos'
) AS CoreRecord
CROSS APPLY
    OPENJSON(CoreRecord.Videos)
WITH
    (
        Sentiments NVARCHAR(MAX) '$.insights.sentiments' AS JSON
    ) AS Insights
CROSS APPLY
    OPENJSON(Insights.Sentiments)
WITH
    (
        SentimentId INT '$.id'
        , SentimentScore FLOAT '$.averageScore'
        , SentimentType VARCHAR(MAX) '$.sentimentType'
        , Instances NVARCHAR(MAX) '$.instances' AS JSON
    ) AS SentimentInstances
CROSS APPLY
    OPENJSON(SentimentInstances.Instances)
WITH
    (
        DurationStart VARCHAR(MAX) '$.start'
        , DurationEnd VARCHAR(MAX) '$.end'
    ) AS SentimentInstanceRecords

