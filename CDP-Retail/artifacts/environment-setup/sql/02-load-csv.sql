COPY INTO #TABLE_NAME# 
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/#CSV_FILE_NAME#.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = #DATA_START_ROW_NUMBER# 
)