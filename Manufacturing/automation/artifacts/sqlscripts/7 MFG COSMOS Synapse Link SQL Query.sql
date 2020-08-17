SELECT 
	[MachineInstanceId] 
    , [MachineInstanceIndex] 
	, [MachineMakeId] 
	, [LocationAreaId] 
	, [MachineCode] 
	, [LocationMachineCode] 
    , [MachineName] 

FROM OPENROWSET
	(
	BULK N'endpoint=https://cosmosdb-mfgdemo.documents.azure.com:443/;account=cosmosdb-mfgdemo;database=manufacturing;collection=MfgMachineInstance;region=westus2',
	SECRET = 'ituFGSRRpA9mKO8Kj3QHuDg3gsZasbyYQZ75v1t5EDyjub6X68cqUvW8h4bSvfjks6r5L7Ij2ZaZJGxFfSpV7A==',
	FORMAT='CosmosDB'
	)
WITH (
	[MachineInstanceId] BIGINT
    , [MachineInstanceIndex] BIGINT
	, [MachineMakeId] BIGINT
	, [LocationAreaId] BIGINT
	, [MachineCode] VARCHAR(50)
	, [LocationMachineCode] VARCHAR(50)
    , [MachineName] VARCHAR(50)
) AS q1



GO


Create View vwMfgMachineInstance
AS
SELECT 
	[MachineInstanceId] 
    , [MachineInstanceIndex] 
	, [MachineMakeId] 
	, [LocationAreaId] 
	, [MachineCode] 
	, [LocationMachineCode] 
    , [MachineName] 

FROM OPENROWSET
	(
	BULK N'endpoint=https://cosmosdb-mfgdemo.documents.azure.com:443/;account=cosmosdb-mfgdemo;database=manufacturing;collection=MfgMachineInstance;region=westus2',
	SECRET = 'ituFGSRRpA9mKO8Kj3QHuDg3gsZasbyYQZ75v1t5EDyjub6X68cqUvW8h4bSvfjks6r5L7Ij2ZaZJGxFfSpV7A==',
	FORMAT='CosmosDB'
	)
WITH (
	[MachineInstanceId] BIGINT
    , [MachineInstanceIndex] BIGINT
	, [MachineMakeId] BIGINT
	, [LocationAreaId] BIGINT
	, [MachineCode] VARCHAR(50)
	, [LocationMachineCode] VARCHAR(50)
    , [MachineName] VARCHAR(50)
) AS q1

GO

Create View vwMfgMachineMake
AS
SELECT 
	[MachineMakeId] 
    , [MachineTypeId] 
	, [MachineMakeCode] 
	, [MachineMakeName] 
FROM OPENROWSET
	(
	BULK N'endpoint=https://cosmosdb-mfgdemo.documents.azure.com:443/;account=cosmosdb-mfgdemo;database=manufacturing;collection=MfgMachineMake;region=westus2',
	SECRET = 'ituFGSRRpA9mKO8Kj3QHuDg3gsZasbyYQZ75v1t5EDyjub6X68cqUvW8h4bSvfjks6r5L7Ij2ZaZJGxFfSpV7A==',
	FORMAT='CosmosDB'
	)
WITH (
	[MachineMakeId] BIGINT
    , [MachineTypeId] BIGINT
	, [MachineMakeCode] VARCHAR(50)
	, [MachineMakeName] VARCHAR(50)
) AS q2
GO

Create View vwMfgMesQuality
AS
SELECT 
	[Avg] 
    , [Good] 
	, [MachineInstance] 
	, [MachineName] 
	, [Reject] 
	, [Snag] 
    , [ProductionMonth] 
FROM OPENROWSET
	(
	BULK N'endpoint=https://cosmosdb-mfgdemo.documents.azure.com:443/;account=cosmosdb-mfgdemo;database=manufacturing;collection=MfgMesQuality;region=westus2',
	SECRET = 'ituFGSRRpA9mKO8Kj3QHuDg3gsZasbyYQZ75v1t5EDyjub6X68cqUvW8h4bSvfjks6r5L7Ij2ZaZJGxFfSpV7A==',
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
) AS q3

GO

SELECT 	
	Cast(Convert(datetimeoffset,[ProductionMonth],101) as date) [Date],
	MAX(q3.Good) [Max_Good] , 
	MAX(q3.Reject) [Max_AVG] ,
	MAX(q3.Snag) [Max_AVG] ,
	q1.MachineCode,
	q2.MachineMakeName
FROM 
	vwMfgMachineInstance q1
JOIN 
	vwMfgMachineMake q2 ON 	q1.MachineMakeId = q2.MachineMakeId
JOIN 
	vwMfgMesQuality  q3 ON q3.MachineInstance = q1.MachineCode
Group by 
	q1.MachineCode,
	q2.MachineMakeName,
	Cast(Convert(datetimeoffset,[ProductionMonth],101) as date)




