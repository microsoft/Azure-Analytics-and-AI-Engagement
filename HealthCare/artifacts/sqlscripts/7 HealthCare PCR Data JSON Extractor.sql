/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md
--JSON Extractor 
    --Step-1, Azure Synapse enables you to store JSON in standard textual format, use standard SQL language for querying JSON data

select * from [dbo].[healthcare-pcr-json]

-- Step-2, let's take JSON data and extract specific structured columns.
SELECT  Top 100 
		JSON_VALUE( [Pcrdata],'$.PcrKey') AS PcrKey,
		JSON_VALUE( [Pcrdata],'$.Complaint_Reported_by_Dispatch') AS Complaint_Reported_by_Dispatch,
		JSON_VALUE( [Pcrdata],'$.Response_Mode_to_Scene') AS Response_Mode_to_Scene,
        JSON_VALUE( [Pcrdata],'$.Cause_of_Injury') AS Cause_of_Injury,
        JSON_VALUE( [Pcrdata],'$.Heart_Rate') AS Heart_Rate
	   from [dbo].[healthcare-pcr-json]
	   WHERE ISJSON([Pcrdata]) > 0

--## Step-3, let's filter for Response_Mode_to_Scene='Emergent (Immediate Response)'.
    --The query below fetches JSON data and filters it by Response_Mode_to_Scene.<br>
    --Please note, this extracts specific columns in a structured format
SELECT  Top 100 
		JSON_VALUE( [Pcrdata],'$.PcrKey') AS PcrKey,
		JSON_VALUE( [Pcrdata],'$.Complaint_Reported_by_Dispatch') AS Complaint_Reported_by_Dispatch,
		JSON_VALUE( [Pcrdata],'$.Response_Mode_to_Scene') AS Response_Mode_to_Scene,
        JSON_VALUE( [Pcrdata],'$.Cause_of_Injury') AS Cause_of_Injury,
        JSON_VALUE( [Pcrdata],'$.Heart_Rate') AS Heart_Rate
	   from [dbo].[healthcare-pcr-json]
	   WHERE ISJSON([Pcrdata]) > 0  And JSON_VALUE( Pcrdata,'$.Response_Mode_to_Scene')='Emergent (Immediate Response)'