CREATE VIEW vwMfgMesQuality
AS
SELECT
	[Avg]
    , [Good]
    , [MachineInstance]
    , [MachineName]
    , [Reject]
    , [Snag]
    , CONVERT(DATETIME, CONVERT(DATETIMEOFFSET,ProductionMonth)) AS [ProductionMonth]
FROM OPENROWSET
	(
	BULK N'endpoint=https://#COSMOS_ACCOUNT_NAME_MFGDEMO#.documents.azure.com:443/;account=#COSMOS_ACCOUNT_NAME_MFGDEMO#;database=manufacturing;collection=MfgMesQuality;region=#LOCATION#',
	SECRET = '#SECRET#',
	FORMAT='CosmosDB'
	)
WITH (
	[Avg] FLOAT
    , [Good] BIGINT
	, [MachineInstance] VARCHAR(50)
	, [MachineName] VARCHAR(50)
	, [Reject] BIGINT
	, [Snag] BIGINT
    , [ProductionMonth] VARCHAR(50)
) AS q1
GO


CREATE View vwMfgMesQualityHTAP
As
SELECT
    CONVERT(DATETIME, CONVERT(DATETIMEOFFSET,ProductionMonth)) AS ProductionMonthDate
	--Convert(datetime,ProductionMonth ,127) AS ProductionMonthDate
	, MachineInstance
	, SUM(CAST(Good AS FLOAT)) AS SumGood
	, SUM(CAST(Snag AS FLOAT)) AS SumSnag
	, SUM(CAST(Reject AS FLOAT)) AS SumReject
	, AVG(CAST(Good AS FLOAT)) AS AvgGood
	, AVG(CAST(Snag AS FLOAT)) AS AvgSnag
	, AVG(CAST(Reject AS FLOAT)) AS AvgReject
	, ROUND(AVG(Avg), 2) AS AveragedOverAvg
FROM
	[dbo].[vwMfgMesQuality]
GROUP BY
	CONVERT(DATETIME, CONVERT(DATETIMEOFFSET,ProductionMonth)) 
	, MachineInstance
UNION ALL
SELECT
	CAST('2019-06-30' AS Datetime) AS ProductionMonthDate
	, MachineInstance
	, 0 AS SumGood
	, 0 AS SumSnag
	, 0 AS SumReject
	, 0 AS AvgGood
	, 0 AS AvgSnag
	, 0 AS AvgReject
	, 0 AS AveragedOverAvg
FROM
	[dbo].[vwMfgMesQuality]
GROUP BY
	MachineInstance
GO
	
	
CREATE View vwMfgProductionMonth
AS
SELECT
	TOP 12
	CAST(ProductionMonth AS DATETIME) ProductionMonth
	, AVG(Avg) AS Avg
FROM
	[dbo].[vwMfgMesQuality]
GROUP BY
	ProductionMonth
ORDER BY
	ProductionMonth DESC
