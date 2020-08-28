Delete from CampaignData_Bubble
Delete from CampaignData;
Delete from Product;
Delete from Campaignproducts;
Delete from sales;

COPY INTO [dbo].[CampaignData_Bubble]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/mfg-pocdata/Before/CampaignData_Bubble.csv'
WITH (
    FILE_TYPE = 'CSV',
    FIRSTROW = 2
)
COPY INTO [dbo].[CampaignData]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/mfg-pocdata/Before/CampaignData.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO [dbo].[Product]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/mfg-pocdata/Before/Product.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO [dbo].[Campaignproducts]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/mfg-pocdata/Before/Campaignproducts.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO [dbo].[Sales]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/mfg-pocdata/Before/sales.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
---------------------
Select 'Reset is completed' as 'Messages'


