Delete from WebsiteSocialAnalyticsPBIData
delete from CampaignAnalyticLatest;
delete from Campaigns;
delete from CampaignNew4;
delete from location_Analytics;
delete from EmailAnalytics;
delete from FinanceSales;
delete from SalesMaster;
delete from Customer_SalesLatest;

COPY INTO CampaignAnalyticLatest
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/CampaignAnalyticLatest.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO Campaigns
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/Campaigns.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO CampaignNew4
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/CampaignNew4.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO WebsiteSocialAnalyticsPBIData
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/WebsiteSocialAnalyticsPBIData.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO location_Analytics
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/location_Analytics.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO EmailAnalytics
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/EmailAnalytics.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO FinanceSales
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/FinanceSales.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO SalesMaster
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/SalesMaster.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO Customer_SalesLatest
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/Customer_SalesLatest.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)

--Below select statement is for enable a cacheing
select top 10 * from WebsiteSocialAnalyticsPBIData;
select top 10 * from CampaignAnalyticLatest;
select top 10 * from Campaigns;
select top 10 *  from CampaignNew4;
select top 10 *  from location_Analytics;
select top 10 *  from EmailAnalytics;
select top 10 *  from FinanceSales;
select top 10 *  from SalesMaster;
select top 10 * from Customer_SalesLatest;


select 'Reset is Completed' As Message;

