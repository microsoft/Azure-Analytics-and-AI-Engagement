/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md

/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

-- show number of records ingested to far
-- run below query 2 times with a second or more gap between two runs

SELECT count_big(*) [Total Streaming DATA]
FROM dbo.HighSpeedStreamingRaw WITH (NOLOCK)

-- diff number of records
--We can achieve 12GB/min throughput with latencies of only a few sec when landing data into Synapse

DECLARE @before bigint =  883866080; -- Copy value from first run
DECLARE @after bigint =   883924380; -- Copy value from second run
DECLARE @value float = 100000;
SELECT ROUND( (@after - @before) , 2 ) AS RecordsDiff
