/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

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
	BULK N'endpoint=https://#COSMOS_ACCOUNT#.documents.azure.com:443/;account=#COSMOS_ACCOUNT#;database=manufacturing;collection=MfgMachineInstance;region=westus2',
	SECRET = '#COSMOS_KEY#',
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
	BULK N'endpoint=https://#COSMOS_ACCOUNT#.documents.azure.com:443/;account=#COSMOS_ACCOUNT#;database=manufacturing;collection=MfgMachineInstance;region=westus2',
	SECRET = '#COSMOS_KEY#',
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
	BULK N'endpoint=https://#COSMOS_ACCOUNT#.documents.azure.com:443/;account=#COSMOS_ACCOUNT#;database=manufacturing;collection=MfgMachineMake;region=westus2',
	SECRET = '#COSMOS_KEY#',
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
	BULK N'endpoint=https://#COSMOS_ACCOUNT#.documents.azure.com:443/;account=#COSMOS_ACCOUNT#;database=manufacturing;collection=MfgMesQuality;region=westus2',
	SECRET = '#COSMOS_KEY#',
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




