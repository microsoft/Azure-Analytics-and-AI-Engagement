COPY INTO #TABLE_NAME# 
FROM 'https://retailpocstorage.blob.core.windows.net/cdp/csv/#CSV_FILE_NAME#.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = #DATA_START_ROW_NUMBER# 
)