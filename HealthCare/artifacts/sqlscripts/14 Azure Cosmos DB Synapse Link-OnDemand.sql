/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md

/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */


--SQL serverless is also now generally available.
--It runs completely serverless.
--so we only pay for each query and the data we proccess.
--USE [HealthcareSQLOnDemand]
--GO

DROP VIEW IF EXISTS 
    dbo.IOMTDataCosmosDB;
GO

-- Create view
CREATE VIEW IOMTDataCosmosDB
AS 
SELECT PatientID,
PatientAge,Datetime,
Spo2,HeartRate,BodyTemperature,
SystolicPressure,DiastolicPressure
FROM OPENROWSET('CosmosDB',
                'Account=#COSMOS_ACCOUNT#;Database=healthcare;Key=#COSMOS_KEY#',
                IoMTData) AS IoMTData
GO

--Se
SELECT * FROM IOMTDataCosmosDB
