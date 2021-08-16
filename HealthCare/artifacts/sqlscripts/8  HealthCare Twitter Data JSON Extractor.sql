/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md

/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

--JSON Extractor 
    --Step-1, Azure Synapse enables you to store JSON in standard textual format, use standard SQL language for querying JSON data

select * from [dbo].[Healthcare-Twitter-Data]

-- Step-2, let's take JSON data and extract specific structured columns.
SELECT  Top 100 
		JSON_VALUE( [TwitterData],'$.Hashtag') AS Hashtag,
		JSON_VALUE( [TwitterData],'$.City') AS City,
        JSON_VALUE( [TwitterData],'$.Sentiment') AS Sentiment,
        JSON_VALUE( [TwitterData],'$.IsRetweet') AS IsRetweet,
		JSON_VALUE( [TwitterData],'$.UserName') AS UserName
	   from [dbo].[Healthcare-Twitter-Data]
	   WHERE ISJSON([TwitterData]) > 0

--## Step-3, let's filter for Sentiment='Sentiment'.
    --The query below fetches JSON data and filters it by Sentiment
    --Please note, this extracts specific columns in a structured format
SELECT  Top 100 
		JSON_VALUE( [TwitterData],'$.Hashtag') AS Hashtag,
		JSON_VALUE( [TwitterData],'$.City') AS City,
        JSON_VALUE( [TwitterData],'$.Sentiment') AS Sentiment,
        JSON_VALUE( [TwitterData],'$.IsRetweet') AS IsRetweet,
		JSON_VALUE( [TwitterData],'$.UserName') AS UserName
	   from [dbo].[Healthcare-Twitter-Data]
	   WHERE ISJSON([TwitterData]) > 0  And JSON_VALUE( TwitterData,'$.Sentiment')='Positive'