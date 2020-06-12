COPY INTO #TABLE_NAME# 
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/#CSV_FILE_NAME#.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = #DATA_START_ROW_NUMBER# 
)