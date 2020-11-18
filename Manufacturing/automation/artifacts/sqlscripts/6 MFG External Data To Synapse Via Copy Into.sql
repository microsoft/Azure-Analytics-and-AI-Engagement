--Step 1 Lets create table
IF OBJECT_ID(N'[dbo].[iot-lathe-peck-drill_test]', N'U') IS NOT NULL
BEGIN
  DROP TABLE [dbo].[iot-lathe-peck-drill_test]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iot-lathe-peck-drill_test]
( 
	[EpochTime] [bigint]  NULL,
	[StringDateTime] [varchar](50)  NULL,
	[VibrationX] [float]  NULL,
	[VibrationY] [float]  NULL,
	[VibrationZ] [float]  NULL,
	[JobId] [varchar](5000)  NULL,
	[DeviceId] [varchar](5000)  NULL,
	[SyntheticPartitionKey] [varchar](5000)  NULL,
	[ZAxis] [float]  NULL,
	[SpindleSpeed] [bigint]  NULL,
	[CoolantTemperature] [bigint]  NULL,
	[EventProcessedUtcTime] [varchar](5000)  NULL,
	[PartitionId] [bigint]  NULL,
	[EventEnqueuedUtcTime] [varchar](5000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

-- Step 2 Copy data from all PARQUET files in to the table

COPY INTO  [dbo].[iot-lathe-peck-drill_test]
FROM 'https://manufacturingdemo12.blob.core.windows.net/mfg-iot-data/'
WITH (
    FILE_TYPE = 'PARQUET',
    CREDENTIAL=(IDENTITY= 'Shared Access Signature', 
	SECRET='?sv=2019-07-07&sr=c&sig=xTmafJM7nzI5tQIoagk883YR5ZVJ6q4VcNe5IR17obE%3D&st=2020-11-17T00%3A00%3A00Z&se=2021-11-15T00%3A00%3A00Z&sp=rl')
) 

--step 3 Lets query table 
SELECT TOP 10 * FROM  [dbo].[iot-lathe-peck-drill_test]



