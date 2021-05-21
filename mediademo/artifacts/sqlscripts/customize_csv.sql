TRUNCATE TABLE [#TABLE_NAME#]
COPY INTO [#TABLE_NAME#]
FROM 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/customcsv/#TABLE_NAME#.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2
)

