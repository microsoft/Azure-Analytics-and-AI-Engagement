/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md
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
