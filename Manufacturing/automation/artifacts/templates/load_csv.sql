SET IDENTITY_INSERT dbo.CampaignData ON
COPY INTO [#TABLE_NAME#]
FROM 'https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2B Scenario Dataset/#CSV_FILE_NAME#.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = #DATA_START_ROW_NUMBER# 
)
SET IDENTITY_INSERT dbo.CampaignData OFF
