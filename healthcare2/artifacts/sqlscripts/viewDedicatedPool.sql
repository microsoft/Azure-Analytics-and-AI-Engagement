SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE MATERIALIZED VIEW [dbo].[MV_PatientDetails]
WITH ( DISTRIBUTION =  HASH (city))
AS SELECT count_big(Id) AS patient_count, city, count_big(*) AS cb FROM dbo.synpatient WHERE city IS NOT NULL GROUP BY city;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseKPIs]
AS SELECT
        DATEPART(HOUR, UpdatedOn) ForHour
        , AVG(Quality) AS Quality
        , AVG(SampleVerified) AS SampleVerified
        , AVG(SampleRejected) AS SampleRejected
        , AVG(SampleRetested) AS SampleRetested
    FROM
        SynapseLinkLabData
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 17
        AND DATEPART(HOUR, UpdatedOn) <= 22
    GROUP BY
        DATEPART(HOUR, UpdatedOn);
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseLast3HoursQuality]
AS SELECT
        UpdatedOn
        , AVG(Quality) AS Quality
    FROM
        SynapseLinkLabData
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 20
        AND DATEPART(HOUR, UpdatedOn) <= 22
    GROUP BY
        UpdatedOn;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseWorkload]
AS SELECT
        BatchId
        , AVG(PathologyProcessed) AS PathologyProcessed
        , AVG(PathologyVerified) AS PathologyVerified
        , AVG(PathologyAuthenticated) AS PathologyAuthenticated
        , AVG(RadiologyProcessed) AS RadiologyProcessed
        , AVG(RadiologyVerified) AS RadiologyVerified
        , AVG(RadiologyAuthenticated) AS RadiologyAuthenticated
        , AVG(CardioProcessed) AS CardioProcessed
    FROM
        SynapseLinkLabData
    WHERE
        DATEPART(HOUR, UpdatedOn) < 23
    GROUP BY
        BatchId;
GO

