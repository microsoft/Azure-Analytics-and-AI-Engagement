CREATE VIEW vwSynapseLinkMongoDBWorkload
AS
    SELECT
        BatchId
        , AVG(PathologyProcessed) AS PathologyProcessed
        , AVG(PathologyVerified) AS PathologyVerified
        , AVG(PathologyAuthenticated) AS PathologyAuthenticated
        , AVG(RadiologyProcessed) AS RadiologyProcessed
        , AVG(RadiologyVerified) AS RadiologyVerified
        , AVG(RadiologyAuthenticated) AS RadiologyAuthenticated
        , AVG(CardioProcessed) AS CardioProcessed
    FROM
    (
        SELECT
            CAST(UpdatedOn AS DATETIME) AS UpdatedOn
            , BatchId
            , SampleVerified
            , SampleRejected
            , SampleRetested
            , CAST(COALESCE(QualityInt, QualityFloat) AS DECIMAL(5, 2)) AS Quality
            , PathologyProcessed
            , PathologyVerified
            , PathologyAuthenticated
            , RadiologyProcessed
            , RadiologyVerified
            , RadiologyAuthenticated
            , CardioProcessed
        FROM OPENROWSET('CosmosDB',
                        'Account=#COSMOS_ACCOUNT_MONGO#;Database=healthdata;Key=#COSMOS_KEY_MONGO#',
                        SynapseLinkLabData)
        WITH
        (
            UpdatedOn VARCHAR(50) '$.UpdatedOn.string'
            , BatchId VARCHAR(50) '$.BatchId.string'
            , SampleVerified INT '$.SampleVerified.int32'
            , SampleRejected INT '$.SampleRejected.int32'
            , SampleRetested INT '$.SampleRetested.int32'
            , QualityInt INT '$.Quality.int32'
            , QualityFloat FLOAT '$.Quality.float64'
            , PathologyProcessed FLOAT '$.PathologyProcessed.float64'
            , PathologyVerified FLOAT '$.PathologyVerified.float64'
            , PathologyAuthenticated FLOAT '$.PathologyAuthenticated.float64'
            , RadiologyProcessed FLOAT '$.RadiologyProcessed.float64'
            , RadiologyVerified FLOAT '$.RadiologyVerified.float64'
            , RadiologyAuthenticated FLOAT '$.RadiologyAuthenticated.float64'
            , CardioProcessed FLOAT '$.CardioProcessed.float64'
        ) AS MongoDBQuery
    ) RealData
    WHERE
        DATEPART(HOUR, RealData.UpdatedOn) <= 23
    GROUP BY
        RealData.BatchId
GO


CREATE VIEW vwSynapseLinkMongoDBLast3HoursQuality
AS
    SELECT
        UpdatedOn
        , AVG(Quality) AS Quality
    FROM
    (
        SELECT
            CAST(UpdatedOn AS DATETIME) AS UpdatedOn
            , BatchId
            , SampleVerified
            , SampleRejected
            , SampleRetested
            , CAST(COALESCE(QualityInt, QualityFloat) AS DECIMAL(5, 2)) AS Quality
            , PathologyProcessed
            , PathologyVerified
            , PathologyAuthenticated
            , RadiologyProcessed
            , RadiologyVerified
            , RadiologyAuthenticated
            , CardioProcessed
        FROM OPENROWSET('CosmosDB',
                      'Account=#COSMOS_ACCOUNT_MONGO#;Database=healthdata;Key=#COSMOS_KEY_MONGO#',
                        SynapseLinkLabData)
        WITH
        (
            UpdatedOn VARCHAR(50) '$.UpdatedOn.string'
            , BatchId VARCHAR(50) '$.BatchId.string'
            , SampleVerified INT '$.SampleVerified.int32'
            , SampleRejected INT '$.SampleRejected.int32'
            , SampleRetested INT '$.SampleRetested.int32'
            , QualityInt INT '$.Quality.int32'
            , QualityFloat FLOAT '$.Quality.float64'
            , PathologyProcessed FLOAT '$.PathologyProcessed.float64'
            , PathologyVerified FLOAT '$.PathologyVerified.float64'
            , PathologyAuthenticated FLOAT '$.PathologyAuthenticated.float64'
            , RadiologyProcessed FLOAT '$.RadiologyProcessed.float64'
            , RadiologyVerified FLOAT '$.RadiologyVerified.float64'
            , RadiologyAuthenticated FLOAT '$.RadiologyAuthenticated.float64'
            , CardioProcessed FLOAT '$.CardioProcessed.float64'
        ) AS MongoDBQuery
    ) RealData
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 21
        AND DATEPART(HOUR, UpdatedOn) <= 23
    GROUP BY
        UpdatedOn
GO


CREATE VIEW vwSynapseLinkMongoDBLast7HoursQualityVerified
AS
    SELECT
        DATEPART(HOUR, UpdatedOn) AS ForHour
        , AVG(Quality) AS Quality
        , AVG(SampleVerified) AS SampleVerified
    FROM
    (
        SELECT
            CAST(UpdatedOn AS DATETIME) AS UpdatedOn
            , BatchId
            , SampleVerified
            , SampleRejected
            , SampleRetested
            , CAST(COALESCE(QualityInt, QualityFloat) AS DECIMAL(5, 2)) AS Quality
            , PathologyProcessed
            , PathologyVerified
            , PathologyAuthenticated
            , RadiologyProcessed
            , RadiologyVerified
            , RadiologyAuthenticated
            , CardioProcessed
        FROM OPENROWSET('CosmosDB',
                       'Account=#COSMOS_ACCOUNT_MONGO#;Database=healthdata;Key=#COSMOS_KEY_MONGO#',
                        SynapseLinkLabData)
        WITH
        (
            UpdatedOn VARCHAR(50) '$.UpdatedOn.string'
            , BatchId VARCHAR(50) '$.BatchId.string'
            , SampleVerified INT '$.SampleVerified.int32'
            , SampleRejected INT '$.SampleRejected.int32'
            , SampleRetested INT '$.SampleRetested.int32'
            , QualityInt INT '$.Quality.int32'
            , QualityFloat FLOAT '$.Quality.float64'
            , PathologyProcessed FLOAT '$.PathologyProcessed.float64'
            , PathologyVerified FLOAT '$.PathologyVerified.float64'
            , PathologyAuthenticated FLOAT '$.PathologyAuthenticated.float64'
            , RadiologyProcessed FLOAT '$.RadiologyProcessed.float64'
            , RadiologyVerified FLOAT '$.RadiologyVerified.float64'
            , RadiologyAuthenticated FLOAT '$.RadiologyAuthenticated.float64'
            , CardioProcessed FLOAT '$.CardioProcessed.float64'
        ) AS MongoDBQuery
    ) RealData
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 17
        AND DATEPART(HOUR, UpdatedOn) <= 23
    GROUP BY
        DATEPART(HOUR, UpdatedOn)
GO


CREATE VIEW vwSynapseLinkMongoDBKPIs
AS
    SELECT
        DATEPART(HOUR, UpdatedOn) ForHour
        , AVG(Quality) AS Quality
        , AVG(SampleVerified) AS SampleVerified
        , AVG(SampleRejected) AS SampleRejected
        , AVG(SampleRetested) AS SampleRetested
    FROM
    (
        SELECT
            CAST(UpdatedOn AS DATETIME) AS UpdatedOn
            , BatchId
            , SampleVerified
            , SampleRejected
            , SampleRetested
            , CAST(COALESCE(QualityInt, QualityFloat) AS DECIMAL(5, 2)) AS Quality
            , PathologyProcessed
            , PathologyVerified
            , PathologyAuthenticated
            , RadiologyProcessed
            , RadiologyVerified
            , RadiologyAuthenticated
            , CardioProcessed
        FROM OPENROWSET('CosmosDB',
                        'Account=#COSMOS_ACCOUNT_MONGO#;Database=healthdata;Key=#COSMOS_KEY_MONGO#',
                        SynapseLinkLabData)
        WITH
        (
            UpdatedOn VARCHAR(50) '$.UpdatedOn.string'
            , BatchId VARCHAR(50) '$.BatchId.string'
            , SampleVerified INT '$.SampleVerified.int32'
            , SampleRejected INT '$.SampleRejected.int32'
            , SampleRetested INT '$.SampleRetested.int32'
            , QualityInt INT '$.Quality.int32'
            , QualityFloat FLOAT '$.Quality.float64'
            , PathologyProcessed FLOAT '$.PathologyProcessed.float64'
            , PathologyVerified FLOAT '$.PathologyVerified.float64'
            , PathologyAuthenticated FLOAT '$.PathologyAuthenticated.float64'
            , RadiologyProcessed FLOAT '$.RadiologyProcessed.float64'
            , RadiologyVerified FLOAT '$.RadiologyVerified.float64'
            , RadiologyAuthenticated FLOAT '$.RadiologyAuthenticated.float64'
            , CardioProcessed FLOAT '$.CardioProcessed.float64'
        ) AS MongoDBQuery
    ) RealData
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 17
        AND DATEPART(HOUR, UpdatedOn) <= 23
    GROUP BY
        DATEPART(HOUR, UpdatedOn)
GO

/*
SELECT
    *
FROM
    vwSynapseLinkMongoDBWorkload
ORDER BY
    BatchId

SELECT
    *
FROM
    vwSynapseLinkMongoDBLast3HoursQuality
ORDER BY
    UpdatedOn

SELECT
    *
FROM
    vwSynapseLinkMongoDBLast7HoursQualityVerified
ORDER BY
    ForHour

SELECT
    *
FROM
    vwSynapseLinkMongoDBKPIs
ORDER BY
    ForHour
*/

/*
DROP VIEW vwSynapseLinkMongoDBWorkload
GO
DROP VIEW vwSynapseLinkMongoDBLast3HoursQuality
GO
DROP VIEW vwSynapseLinkMongoDBLast7HoursQualityVerified
GO
DROP VIEW vwSynapseLinkMongoDBKPIs
GO

*/