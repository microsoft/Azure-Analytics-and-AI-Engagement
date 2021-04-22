Truncate table [dbo].[Mkt_CampaignAnalyticLatest]

COPY INTO [dbo].[Mkt_CampaignAnalyticLatest]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/customcsv/Mkt_CampaignAnalyticLatest.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 1 
)