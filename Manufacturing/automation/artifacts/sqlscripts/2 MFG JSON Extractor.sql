--JSON Extractor 
    --Step-1, Azure Synapse enables you to store JSON in standard textual format, use standard SQL language for querying JSON data

select * from [dbo].[mfg-iot-json]

-- Step-2, let's take JSON data and extract specific structured columns.
SELECT  Top 100 
		JSON_VALUE( [IoTData],'$.EpochTime') AS EpochTime,
		JSON_VALUE( [IoTData],'$.StringDateTime') AS StringDateTime,
		JSON_VALUE( [IoTData],'$.JobCode') AS JobCode,
		JSON_VALUE( [IoTData],'$.OperationId') AS OperationId
	   from [dbo].[mfg-iot-json]
	   WHERE ISJSON([IoTData]) > 0

--## Step-3, let's filter for OperationId=101.
    --The query below fetches JSON data and filters it by OperationId.<br>
    --Please note, this extracts specific columns in a structured format
SELECT  Top 100 
		JSON_VALUE( [IoTData],'$.EpochTime') AS EpochTime,
		JSON_VALUE( [IoTData],'$.StringDateTime') AS StringDateTime,
		JSON_VALUE( [IoTData],'$.JobCode') AS JobCode,
		JSON_VALUE( [IoTData],'$.OperationId') AS OperationId
	   from [dbo].[mfg-iot-json]
	   WHERE ISJSON([IoTData]) > 0  And JSON_VALUE( IoTData,'$.OperationId')=101