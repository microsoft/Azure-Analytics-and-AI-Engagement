/******Important - Do not use in production, for demonstration purposes only - please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer

----lets truncate the  table and lets start afresh to make the demo seamless....

truncate table dbo.HighSpeedStreamingRaw

-- step 1 :show number of records ingested to far
-- run below query 2 times with a second or more gap between two runs

SELECT count_big(*) [Total Streaming DATA]
FROM dbo.HighSpeedStreamingRaw WITH (NOLOCK)

-- Step 2: diff number of records
--We can achieve 12GB/min throughput with latencies of only a few sec when landing data into Synapse

DECLARE @before bigint =  28920; -- Copy value from first run
DECLARE @after bigint =   97020; -- Copy value from second run
DECLARE @value float = 100000;
SELECT ROUND( (@after - @before) , 2 ) AS RecordsDiff



