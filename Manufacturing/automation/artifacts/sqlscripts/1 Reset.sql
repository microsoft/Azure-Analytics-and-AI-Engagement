Delete from CampaignData_Bubble
Delete from CampaignData;
Delete from Product;
Delete from Campaignproducts;
Delete from sales;

COPY INTO [dbo].[CampaignData_Bubble]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/customcsv/Manufacturing B2B Scenario Dataset/CampaignData_Bubble.csv'
WITH (
    FILE_TYPE = 'CSV',
    FIRSTROW = 2
)
COPY INTO [dbo].[CampaignData]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/customcsv/Manufacturing B2B Scenario Dataset/CampaignData.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO [dbo].[Product]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/customcsv/Manufacturing B2B Scenario Dataset/Product.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO [dbo].[Campaignproducts]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/customcsv/Manufacturing B2B Scenario Dataset/Campaignproducts.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO [dbo].[Sales]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/customcsv/Manufacturing B2B Scenario Dataset/sales.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
---------------------
Select 'Reset is completed' as 'Messages'


