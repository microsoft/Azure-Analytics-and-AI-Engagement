
create user [CEO] without login
create user [DataAnalystMiami] without login
create user [DataAnalystSanDiego] without login

IF OBJECT_ID(N'[wwi_security].[CustomerInfo]', N'U') IS NOT NULL   
DROP TABLE [wwi_security].[CustomerInfo]

CREATE TABLE [wwi_security].[CustomerInfo]
( 
	[UserName] [nvarchar](100)  NULL,
	[Gender] [nvarchar](10)  NULL,
	[Phone] [nvarchar](50)  NULL,
	[Email] [nvarchar](150)  NULL,
	[CreditCard] [nvarchar](21)  NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO

COPY INTO [wwi_security].[CustomerInfo]
FROM 'https://#DATA_LAKE_ACCOUNT_NAME#.dfs.core.windows.net/wwi-02/security/customerinfo.csv'
WITH (
    FILE_TYPE = 'CSV',
    FIRSTROW = 2,
	FIELDQUOTE='''',
    ENCODING='UTF8'
)
GO

IF OBJECT_ID(N'[wwi_security].[Sale]', N'U') IS NOT NULL  
DROP TABLE [wwi_security].[Sale]
GO

CREATE TABLE [wwi_security].[Sale]
( 
	[ProductId] [int]  NOT NULL,
	[Analyst] [nvarchar](100)  NOT NULL,
	[Product] [nvarchar](200)  NOT NULL,
	[CampaignName] [nvarchar](200)  NOT NULL,
	[Quantity] [int]  NOT NULL,
	[Region] [nvarchar](50)  NOT NULL,
	[State] [nvarchar](50)  NOT NULL,
	[City] [nvarchar](50)  NOT NULL,
	[Revenue] [nvarchar](50)  NULL,
	[RevenueTarget] [nvarchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

COPY INTO [wwi_security].[Sale]
FROM 'https://#DATA_LAKE_ACCOUNT_NAME#.dfs.core.windows.net/wwi-02/security/factsale.csv'
WITH (
    FILE_TYPE = 'CSV',
    FIRSTROW = 2,
	FIELDQUOTE='''',
    ENCODING='UTF8'
)
GO
