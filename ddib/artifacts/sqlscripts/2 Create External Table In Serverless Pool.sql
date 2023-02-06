----Create Database
-- Create DATABASE IgniteServerlessPool

--Creates an external file format object that defines external data stored in Data Lake.
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseParquetFormat') 
	CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat] 
	WITH ( FORMAT_TYPE = PARQUET)
GO

---Create Master Key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'L9235edf@12@$'

--Create Credential
CREATE DATABASE SCOPED CREDENTIAL SaasToken
WITH IDENTITY='SHARED ACCESS SIGNATURE',
SECRET='#SAS_TOKEN#';

-- Create External Data Source
CREATE EXTERNAL DATA SOURCE [ADLSSource] 
	WITH (
		LOCATION = 'abfss://delta-files@#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net'
	)

--------------------------- Create External Tables
CREATE EXTERNAL TABLE [TwitterHistoricalData] (
	[time] datetime2(7),
	[hashtag] nvarchar(4000),
	[tweet] nvarchar(4000),
	[city] nvarchar(4000),
	[username] nvarchar(4000),
	[retweetcount] int,
	[favouritecount] int,
	[sentiment] nvarchar(4000),
	[sentimentscore] numeric(10,0),
	[isretweet] int,
	[hourofday] nvarchar(4000),
	[language] nvarchar(4000),
	[MLSentiment] nvarchar(4000)
	)
	WITH (
	LOCATION = 'dlt/tables/bronze_twitter_historical_data/*.parquet',
	DATA_SOURCE = [ADLSSource],
	FILE_FORMAT = [SynapseParquetFormat]
	)
GO
--------------------
CREATE EXTERNAL TABLE CampaignSentimentData (
	[city] nvarchar(4000),
	[hashtag] nvarchar(4000),
	[count] bigint
	)
	WITH (
	LOCATION = 'dlt/tables/Sentiment_Campaign_Analytics/*.parquet',
	DATA_SOURCE = [ADLSSource],
	FILE_FORMAT = [SynapseParquetFormat]
	)
GO
-----------------------
CREATE EXTERNAL TABLE CampaignData (
	[Region] nvarchar(4000),
	[Country] nvarchar(4000),
	[ProductCategory] nvarchar(4000),
	[Campaign_ID] int,
	[Campaign_Name] nvarchar(4000),
	[Qualification] nvarchar(4000),
	[Qualification_Number] nvarchar(4000),
	[Response_Status] nvarchar(4000),
	[Responses] real,
	[Cost] real,
	[Revenue] real,
	[ROI] real,
	[Lead_Generation] nvarchar(4000),
	[Revenue_Target] real,
	[Campaign_Tactic] nvarchar(4000),
	[Customer_Segment] nvarchar(4000),
	[Status] nvarchar(4000),
	[Profit] real,
	[Marketing_Cost] real,
	[CampaignID] int,
	[CampDate] date,
	[SORTED_ID] int
	)
	WITH (
	LOCATION = 'dlt/tables/bronze_campaign_data/*.parquet',
	DATA_SOURCE = [ADLSSource],
	FILE_FORMAT = [SynapseParquetFormat]
	)
GO
------------------
CREATE EXTERNAL TABLE SalesForecastData (
	[Quantity] float,
	[Advert] float,
	[Price] real,
	[Brand] nvarchar(4000),
	[Predicted_Revenue] float
	)
	WITH (
	LOCATION = 'SalesForecast Data/salespredictiondata/*.parquet',
	DATA_SOURCE = [ADLSSource],
	FILE_FORMAT = [SynapseParquetFormat]
	)
GO
------------------
CREATE EXTERNAL TABLE CustomerChurnData (
	[Gender] nvarchar(4000),
	[SeniorCitizen] nvarchar(4000),
	[Partner] nvarchar(4000),
	[Dependents] nvarchar(4000),
	[tenure_month] int,
	[Discount] nvarchar(4000),
	[OutletSize] nvarchar(4000),
	[OnlineDelivery] nvarchar(4000),
	[OrderStatus] nvarchar(4000),
	[CustomerSupport] nvarchar(4000),
	[Brand] nvarchar(4000),
	[StoreContract] nvarchar(4000),
	[PaperlessBilling] nvarchar(4000),
	[PaymentMethod] nvarchar(4000),
	[UnitPrice] float,
	[TotalAmount] float,
	[Churn] bigint,
	[ChurnProbability] float,
	[PredictedChurn] nvarchar(4000)
	)
	WITH (
	LOCATION = 'CustomerChurn Data/**',
	DATA_SOURCE = [ADLSSource],
	FILE_FORMAT = [SynapseParquetFormat]
	)
GO
