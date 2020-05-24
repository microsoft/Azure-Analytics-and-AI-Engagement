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
	[RetweetCount] [bigint]  NULL,
	[FavouriteCount] [bigint]  NULL,
	[Sentiment] [nvarchar](4000)  NULL,
	[SentimentScore] [bigint]  NULL,
	[IsRetweet] [bigint]  NULL,
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
FROM 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/twitterdata/'
WITH (
    FILE_TYPE = 'PARQUET',
    CREDENTIAL=(IDENTITY= 'Shared Access Signature', SECRET='#SAS_KEY#')
);
GO

-- Step 3 Lets query table 
SELECT TOP 10 * 
FROM  [dbo].[Twitter];
GO

