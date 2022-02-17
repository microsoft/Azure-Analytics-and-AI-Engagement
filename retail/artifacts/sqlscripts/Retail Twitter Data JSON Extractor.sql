/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  ########################################

--JSON Extractor 
    --Step-1, Azure Synapse enables you to store JSON in standard textual format, use standard SQL language for querying JSON data

select * from [dbo].[TwitterAnalytics]

-- Step-2, let's take JSON data and extract specific structured columns.
SELECT  Top 100 
		JSON_VALUE( [TwitterData],'$.Hashtag') AS Hashtag,
		JSON_VALUE( [TwitterData],'$.City') AS City,
        JSON_VALUE( [TwitterData],'$.Sentiment') AS Sentiment,
        JSON_VALUE( [TwitterData],'$.IsRetweet') AS IsRetweet,
		JSON_VALUE( [TwitterData],'$.UserName') AS UserName
	   from [dbo].[TwitterAnalytics]
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
	   from [dbo].[TwitterAnalytics]
	   WHERE ISJSON([TwitterData]) > 0  And JSON_VALUE( TwitterData,'$.Sentiment')='Positive'