Delete from WebsiteSocialAnalyticsPBIData
delete from CampaignAnalyticLatest;
delete from Campaigns;
delete from CampaignNew4;
delete from location_Analytics;
delete from EmailAnalytics;
delete from FinanceSales;
delete from SalesMaster;
delete from SalesMaster;
delete from Customer_SalesLatest;

COPY INTO CampaignAnalyticLatest
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/CampaignAnalyticLatest.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO Campaigns
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/Campaigns.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO CampaignNew4
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/CampaignNew4.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO WebsiteSocialAnalyticsPBIData
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/WebsiteSocialAnalyticsPBIData.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO location_Analytics
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/location_Analytics.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO EmailAnalytics
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/EmailAnalytics.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO FinanceSales
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/FinanceSales.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO SalesMaster
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/SalesMaster.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)
COPY INTO Customer_SalesLatest
FROM 'https://solliancepublicdata.blob.core.windows.net/cdp/csv/Customer_SalesLatest.csv'
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
select top 10 *  from SalesMaster;
select top 10 * from Customer_SalesLatest;




