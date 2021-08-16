/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

--Step 1 Let's create table
IF OBJECT_ID(N'dbo.Twitter', N'U') IS NOT NULL
BEGIN
	DROP TABLE [dbo].[Twitter]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Twitter]
( 
	[Time] [nvarchar](4000)  NULL,
	[Hashtag] [nvarchar](4000)  NULL,
	[Tweet] [nvarchar](4000)  NULL,
	[City] [nvarchar](4000)  NULL,
	[UserName] [nvarchar](4000)  NULL,
	[RetweetCount] [int]  NULL,
	[FavouriteCount] [int]  NULL,
	[Sentiment] [nvarchar](4000)  NULL,
	[SentimentScore] [int]  NULL,
	[IsRetweet] [int]  NULL,
	[HourOfDay] [nvarchar](4000)  NULL,
	[Language] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
);
GO

-- Step 2 Copy data from all PARQUET files in to the table
COPY INTO [dbo].[Twitter]
FROM 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/twitterdata/dbo.TwitterAnalytics.parquet'
WITH (
    FILE_TYPE = 'PARQUET',
    CREDENTIAL=(IDENTITY= 'Shared Access Signature', SECRET='#SAS_KEY#')
);
GO

-- Step 3 Lets query table 
SELECT TOP 10 * 
FROM  [dbo].[Twitter];
GO

