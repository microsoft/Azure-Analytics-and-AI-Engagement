COPY INTO #TABLE_NAME# 
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/data/#CSV_FILE_NAME#.csv'
WITH (
	FILE_TYPE = 'CSV'
	,CREDENTIAL=(IDENTITY= 'Storage Account Key', SECRET='c/5jTocejppX2bd7luchLSv8f8k8J4ickv5Gwm+Nv45kn2IMFPGSeHbFHbXEUxrNmvweFLy01+A+omn0q9uHOQ==')
)