-- Old syntax 

SELECT Top 100 [numberofsteps] , [heartrate],[systolic],[diastolic],[distance],[calories],[mode]
FROM OPENROWSET
	(
	BULK N'endpoint=https://#COSMOS_ACCOUNT#.documents.azure.com:443/;account=#COSMOS_ACCOUNT#;database=healthcare;collection=StreamingData;region=#LOCATION#',
	SECRET = '#COSMOS_KEY#',
	FORMAT='CosmosDB'
	)
    WITH (
	[numberofsteps] FLOAT,
    [heartrate]FLOAT,
    [systolic]FLOAT,
    [diastolic] FLOAT,
    [distance]FLOAT,
    [calories] FLOAT,
    [mode] VARCHAR(50) 
) AS q1

GO

-- New syntax (Automatically handle schema updates)

SELECT Top 100 patientId, patientAge, cast([Datetime] as Datetimeoffset) _datetime, bodyTemperature, heartRate, breathingRate, spo2 ,systolicPressure, 
                diastolicPressure ,numberOfSteps , activityTime , numberOfTimesPersonStoodUp , calories, vo2
FROM OPENROWSET
	(
    'CosmosDB',
    'account=#COSMOS_ACCOUNT#;database=healthcare;region=#LOCATION#;key=#COSMOS_KEY#',
    IoMTData
    )  as q1

GO




-- Mongodb API 

SELECT TOP 100 * 
FROM OPENROWSET('CosmosDB',
                'Account=cosmos-healthcare-mongodb-dev;Database=healthdata;Key=8Mrj3rKTiFajVxJqjRh2WHS8coDdxMe6Yf0OTdUYhOW78VQHhcF47QCGCznfJJ9exp9l1nbGy4tvCSgAm1kF3w==',
                IoMTData)
                 AS IoMTData


GO

-- Querying items with full-fidelity schema

SELECT TOP 100 
                patientId, patientAge, cast([Datetime] as Datetimeoffset) _datetime, bodyTemperature, heartRate, breathingRate, spo2 ,systolicPressure, 
                diastolicPressure ,numberOfSteps , activityTime , numberOfTimesPersonStoodUp , calories, vo2
FROM 
    OPENROWSET
            (
                'CosmosDB',
                'Account=cosmos-healthcare-mongodb-dev;Database=healthdata;Key=8Mrj3rKTiFajVxJqjRh2WHS8coDdxMe6Yf0OTdUYhOW78VQHhcF47QCGCznfJJ9exp9l1nbGy4tvCSgAm1kF3w==',
                IoMTData
            )
    WITH 
            ( 
                patientId VARCHAR(50) '$.patientId.string',
                patientAge INT '$.patientAge.int32',
                [Datetime]  VARCHAR(50) '$.datetime.string',
                bodyTemperature FLOAT '$.bodyTemperature.float64',
                heartRate INT '$.heartRate.int32',
                breathingRate INT '$.breathingRate.int32',
                spo2 INT '$.spo2.int32',
                systolicPressure INT '$.systolicPressure.int32',
                diastolicPressure INT '$.diastolicPressure.int32',
                numberOfSteps INT '$.numberOfSteps.int32',
                activityTime INT '$.activityTime.int32',
                numberOfTimesPersonStoodUp INT '$.numberOfTimesPersonStoodUp.int32',
                calories INT '$.calories.int32',
                vo2 INT '$.vo2.int32'
            )
    AS IoMTData


GO


Create or ALTER View vwActivityData
AS
SELECT Top 100 patientId, patientAge, cast([Datetime] as Datetimeoffset) _datetime, bodyTemperature, heartRate, breathingRate, spo2 ,systolicPressure, 
                diastolicPressure ,numberOfSteps , activityTime , numberOfTimesPersonStoodUp , calories, vo2
FROM OPENROWSET
	(
    'CosmosDB',
    'account=cosmos-healthcare-dev;database=healthcare;region=westus2;key=B3tUrtBdTxTt3wQ1e2D7127UhRHT1og4wRAXF9wI8cLL4fbBuOogpdEzxpU1gYBFsydsUYzWnAVOfmYSpH8JAA==',
    IoMTData
    )  as q1

    Go
Create or ALTER View vwHealthData
AS
    SELECT TOP 100 
                patientId, patientAge, cast([Datetime] as Datetimeoffset) _datetime, bodyTemperature, heartRate, breathingRate, spo2 ,systolicPressure, 
                diastolicPressure ,numberOfSteps , activityTime , numberOfTimesPersonStoodUp , calories, vo2
    FROM 
        OPENROWSET
            (
                'CosmosDB',
                'Account=cosmos-healthcare-mongodb-dev;Database=healthdata;Key=8Mrj3rKTiFajVxJqjRh2WHS8coDdxMe6Yf0OTdUYhOW78VQHhcF47QCGCznfJJ9exp9l1nbGy4tvCSgAm1kF3w==',
                IoMTData
            )
    WITH 
            ( 
                patientId VARCHAR(50) '$.patientId.string',
                patientAge INT '$.patientAge.int32',
                [Datetime]  VARCHAR(50) '$.datetime.string',
                bodyTemperature FLOAT '$.bodyTemperature.float64',
                heartRate INT '$.heartRate.int32',
                breathingRate INT '$.breathingRate.int32',
                spo2 INT '$.spo2.int32',
                systolicPressure INT '$.systolicPressure.int32',
                diastolicPressure INT '$.diastolicPressure.int32',
                numberOfSteps INT '$.numberOfSteps.int32',
                activityTime INT '$.activityTime.int32',
                numberOfTimesPersonStoodUp INT '$.numberOfTimesPersonStoodUp.int32',
                calories INT '$.calories.int32',
                vo2 INT '$.vo2.int32'
            )
    AS IoMTData

GO 


Select
b.patientId,
Max(b.numberOfTimesPersonStoodUp) [numberOfTimesPersonStoodUp],
Max(b.numberOfSteps) [numberOfSteps],
Max(b.calories) [calories],
Min(a.bodyTemperature) [MinbodyTemperature], 
Max(a.bodyTemperature) [MaxbodyTemperature], 
avg(a.bodyTemperature) [avgbodyTemperature], b.patientAge, FORMAT(a._datetime,'dd-MM-yyyy') as  _datetime 
 from vwHealthData a
Inner join vwActivityData b on a.patientId = b.patientId
--Inner join [default].[dbo].[patient_table] c on c.Id = b.patientId
Group by b.patientAge,FORMAT(a._datetime,'dd-MM-yyyy') , b.patientId


GO


