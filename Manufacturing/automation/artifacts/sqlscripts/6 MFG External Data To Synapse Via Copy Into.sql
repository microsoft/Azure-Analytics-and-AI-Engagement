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
	SECRET='?sv=2019-10-10&ss=bfqt&srt=sco&sp=rwdlacupx&se=2020-10-07T00:45:30Z&st=2020-03-06T16:45:30Z&spr=https,http&sig=LfQolgoKkjh%2Fhz2hyrxOT8DOKo1vJ7IFusRyCShR%2FUA%3D')
) 

--step 3 Lets query table 
SELECT TOP 10 * FROM  [dbo].[iot-lathe-peck-drill_test]



