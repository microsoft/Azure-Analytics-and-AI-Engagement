IF OBJECT_ID(N'[dbo].[Sales]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Sales]

CREATE TABLE [dbo].[Sales]
( 
	[TransactionId] [nvarchar](100)  NULL,
	[CustomerId] [int]   NULL,
	[ProductId] [bigint]   NULL,
	[Quantity] [int]   NULL,
	[Price] [int]   NULL,
	[TotalAmount] [bigint]   NULL,
	[TransactionDate] [datetime]   NULL,
	[ProfitAmount] [int]   NULL,
	[Hour] [int]   NULL,
	[Minute] [int]   NULL,
	[StoreId] [bigint]   NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CustomerId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[IDS]', N'U') IS NOT NULL   
DROP TABLE [dbo].[IDS]

CREATE TABLE [dbo].[IDS]
( 
	[CustomerId] [int]   NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[Products]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Products]

CREATE TABLE [dbo].[Products]
( 
	[Products_ID] [int]  NOT NULL,
	[ProductID] [varchar](100)  NULL,
	[Name] [varchar](100)  NULL,
	[Department] [varchar](100)  NULL,
	[Price] [money]  NULL,
	[Category] [varchar](100)  NULL,
	[Thumbnail_FileName] [varchar](250)  NULL,
	[AdImage_FileName] [varchar](250)  NULL,
	[SoundFile_FileName] [varchar](100)  NULL,
	[SubCampaigns] [varchar](100)  NULL,
	[TargetGender] [varchar](40)  NULL,
	[TargetClassification] [varchar](100)  NULL,
	[TargetGeneration] [varchar](100)  NULL,
	[Tags] [varchar](100)  NULL,
	[BLECode] [varchar](100)  NULL,
	[Thumbnail] [varbinary](500)  NULL,
	[AdImage] [varbinary](500)  NULL,
	[SoundFile] [varbinary](500)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[Dim_Customer]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Dim_Customer]

CREATE TABLE [dbo].[Dim_Customer]
( 
	[Id] [bigint]  NULL,
	[Age] [smallint]  NULL,
	[Gender] [nvarchar](4000)  NULL,
	[Pincode] [nvarchar](4000)  NULL,
	[FirstName] [nvarchar](4000)  NULL,
	[LastName] [nvarchar](4000)  NULL,
	[FullName] [nvarchar](4000)  NULL,
	[DateOfBirth] [nvarchar](4000)  NULL,
	[Address] [nvarchar](4000)  NULL,
	[Email] [nvarchar](4000)  NULL,
	[Mobile] [nvarchar](4000)  NULL,
	[UserName] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[TwitterAnalytics]', N'U') IS NOT NULL   
DROP TABLE [dbo].[TwitterAnalytics]

CREATE TABLE [dbo].[TwitterAnalytics]
( 
	[Time] [nvarchar](100)  NULL,
	[Hashtag] [nvarchar](500)  NULL,
	[Tweet] [nvarchar](4000)  NULL,
	[City] [nvarchar](1000)  NULL,
	[UserName] [nvarchar](500)  NULL,
	[RetweetCount] [int]  NULL,
	[FavouriteCount] [int]  NULL,
	[Sentiment] [nvarchar](100)  NULL,
	[SentimentScore] [int]  NULL,
	[IsRetweet] [int]  NULL,
	[HourOfDay] [nvarchar](20)  NULL,
	[Language] [nvarchar](200)  NULL,
	[LineageKey] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[MillennialCustomers]', N'U') IS NOT NULL   
DROP TABLE [dbo].[MillennialCustomers]

CREATE TABLE [dbo].[MillennialCustomers]
( 
	[CustomerId] [nvarchar](4000)  NULL,
	[Age] [nvarchar](4000)  NULL,
	[ZipCode] [nvarchar](4000)  NULL,
	[FirstName] [nvarchar](4000)  NULL,
	[LastName] [nvarchar](4000)  NULL,
	[DateOfBirth] [nvarchar](4000)  NULL,
	[Phone] [nvarchar](4000)  NULL,
	[UserName] [nvarchar](4000)  NULL,
	[Address] [nvarchar](4000)  NULL,
	[FullName] [nvarchar](4000)  NULL,
	[Gender] [nvarchar](4000)  NULL,
	[Email] [nvarchar](4000)  NULL,
	[Title] [nvarchar](4000)  NULL,
	[ActivityTypeDisplay] [nvarchar](4000)  NULL,
	[EmailStatus] [nvarchar](4000)  NULL,
	[Title_1] [nvarchar](4000)  NULL,
	[LoyaltyId] [nvarchar](4000)  NULL,
	[ProductId] [nvarchar](4000)  NULL,
	[CustomerId_1] [nvarchar](4000)  NULL,
	[Price] [nvarchar](4000)  NULL,
	[Quantity] [nvarchar](4000)  NULL,
	[RewardPoints] [nvarchar](4000)  NULL,
	[CustomerId_2] [nvarchar](4000)  NULL,
	[CustomerId_3] [nvarchar](4000)  NULL,
	[CaseNumber] [nvarchar](4000)  NULL,
	[Priority] [nvarchar](4000)  NULL,
	[Status] [nvarchar](4000)  NULL,
	[CustomerId_4] [nvarchar](4000)  NULL,
	[Salesforce_EmailActivities_SentOn] [nvarchar](4000)  NULL,
	[AdobeAnalytics_WebsiteandClicksData_SentOn] [nvarchar](4000)  NULL,
	[Salesforce_SalesforceContacts_CustomerID] [nvarchar](4000)  NULL,
	[Salesforce_SalesforceContacts_CustomerID_Alternate] [nvarchar](4000)  NULL,
	[DynamicsCommerce_POSTransactions_Id] [nvarchar](4000)  NULL,
	[DynamicsCommerce_POSTransactions_Id_Alternate] [nvarchar](4000)  NULL,
	[Salesforce_EmailActivities_Id] [nvarchar](4000)  NULL,
	[Salesforce_EmailActivities_Id_Alternate] [nvarchar](4000)  NULL,
	[AdobeAnalytics_WebsiteandClicksData_Id] [nvarchar](4000)  NULL,
	[AdobeAnalytics_WebsiteandClicksData_Id_Alternate] [nvarchar](4000)  NULL,
	[DynamicsService_CustomerSupportCases_Id] [nvarchar](4000)  NULL,
	[DynamicsService_CustomerSupportCases_Id_Alternate] [nvarchar](4000)  NULL,
	[DynamicsService_DynamicsCRMServiceContacts_CustomerID] [nvarchar](4000)  NULL,
	[DynamicsService_DynamicsCRMServiceContacts_CustomerID_Alternate] [nvarchar](4000)  NULL,
	[AdobeAnalytics_AdobeAnalyticsWebsiteContacts_CustomerID] [nvarchar](4000)  NULL,
	[AdobeAnalytics_AdobeAnalyticsWebsiteContacts_CustomerID_Alternate] [nvarchar](4000)  NULL,
	[Customer_key] [nvarchar](4000)  NULL,
	[CustKey] [int]  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CustKey] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[TwitterRawData]', N'U') IS NOT NULL   
DROP TABLE [dbo].[TwitterRawData]

CREATE TABLE [dbo].[TwitterRawData]
( 
	[ID] [int]  NOT NULL,
	[TwitterData] [varchar](5000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[department_visit_customer]', N'U') IS NOT NULL   
DROP TABLE [dbo].[department_visit_customer]

CREATE TABLE [dbo].[department_visit_customer]
( 
	[Date] [nvarchar](4000)  NULL,
	[Accessories_count] [nvarchar](4000)  NULL,
	[Entertainment_count] [nvarchar](4000)  NULL,
	[Gaming] [nvarchar](4000)  NULL,
	[Kids] [nvarchar](4000)  NULL,
	[Mens] [nvarchar](4000)  NULL,
	[Phone_and_GPS] [nvarchar](4000)  NULL,
	[Womens] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[Category]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Category]

CREATE TABLE [dbo].[Category]
( 
	[ID] [float]  NOT NULL,
	[Category] [varchar](255)  NULL,
	[SubCategory] [varchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[ProdChamp]', N'U') IS NOT NULL   
DROP TABLE [dbo].[ProdChamp]

CREATE TABLE [dbo].[ProdChamp]
( 
	[Camp] [nvarchar](4000)  NULL,
	[Campaign] [nvarchar](4000)  NULL,
	[Final Camp] [nvarchar](4000)  NULL,
	[ProductID] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[WebsiteSocialAnalytics]', N'U') IS NOT NULL   
DROP TABLE [dbo].[WebsiteSocialAnalytics]

CREATE TABLE [dbo].[WebsiteSocialAnalytics]
( 
	[Country] [varchar](50)  NULL,
	[Product_Category] [varchar](50)  NULL,
	[Product] [varchar](50)  NULL,
	[Channel] [varchar](50)  NULL,
	[Gender] [varchar](50)  NULL,
	[Sessions] [int]  NULL,
	[Device_Category] [varchar](50)  NULL,
	[Sources] [varchar](50)  NULL,
	[Conversations] [varchar](50)  NULL,
	[Page] [varchar](50)  NULL,
	[Visits] [int]  NULL,
	[Unique_Visitors] [int]  NULL,
	[Browser] [varchar](50)  NULL,
	[Sentiment] [varchar](50)  NULL,
	[Duration_min] [varchar](50)  NULL,
	[Region] [varchar](50)  NULL,
	[Customer_Segment] [varchar](50)  NULL,
	[Daily_Users] [int]  NULL,
	[Conversion_Rate] [int]  NULL,
	[Return_Visitors] [int]  NULL,
	[Tweets] [int]  NULL,
	[Retweets] [int]  NULL,
	[Hashtags] [varchar](50)  NULL,
	[Campaign_Name] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[Campaigns]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Campaigns]

CREATE TABLE [dbo].[Campaigns]
( 
	[Campaigns_ID] [int]  NOT NULL,
	[CampaignID] [varchar](100)  NULL,
	[CampaignName] [varchar](100)  NULL,
	[SubCampaignID] [varchar](100)  NULL,
	[FullAd_FileName] [varchar](250)  NULL,
	[HalfAd_FileName] [varchar](250)  NULL,
	[Logo_FileName] [varchar](250)  NULL,
	[SoundFile_FileName] [varchar](250)  NULL,
	[FullAd] [varbinary](500)  NULL,
	[HalfAd] [varbinary](500)  NULL,
	[Logo] [varbinary](500)  NULL,
	[SoundFile] [varbinary](500)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[Campaign_Analytics]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Campaign_Analytics]

CREATE TABLE [dbo].[Campaign_Analytics]
( 
	[Region] [varchar](50)  NOT NULL,
	[Country] [varchar](50)  NOT NULL,
	[Product_Category] [varchar](50)  NOT NULL,
	[Campaign_Name] [varchar](50)  NOT NULL,
	[Revenue] [varchar](50)  NOT NULL,
	[Revenue_Target] [varchar](50)  NOT NULL,
	[City] [varchar](50)  NULL,
	[State] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[CampaignNew4]', N'U') IS NOT NULL   
DROP TABLE [dbo].[CampaignNew4]

CREATE TABLE [dbo].[CampaignNew4]
( 
	[Id] [nvarchar](4000)  NULL,
	[CampaignId] [nvarchar](4000)  NULL,
	[CampaignName] [nvarchar](4000)  NULL,
	[CampaignStartDate] [nvarchar](4000)  NULL,
	[CampaignEndDate] [nvarchar](4000)  NULL,
	[Cost] [nvarchar](4000)  NULL,
	[ROI] [nvarchar](4000)  NULL,
	[LeadGeneration] [nvarchar](4000)  NULL,
	[RevenueTarget] [nvarchar](4000)  NULL,
	[CampaignTactic] [nvarchar](4000)  NULL,
	[Profit] [nvarchar](4000)  NULL,
	[MarketingCost] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[CustomerVisitF]', N'U') IS NOT NULL   
DROP TABLE [dbo].[CustomerVisitF]

CREATE TABLE [dbo].[CustomerVisitF]
( 
	[Date] [nvarchar](4000)  NULL,
	[Gaming] [nvarchar](4000)  NULL,
	[Kids] [nvarchar](4000)  NULL,
	[Mens] [nvarchar](4000)  NULL,
	[Phone_and_GPS] [nvarchar](4000)  NULL,
	[Womens] [nvarchar](4000)  NULL,
	[Accessories] [nvarchar](4000)  NULL,
	[Entertainment] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[FinanceSales]', N'U') IS NOT NULL   
DROP TABLE [dbo].[FinanceSales]

CREATE TABLE [dbo].[FinanceSales]
( 
	[Fiscal Year] [varchar](20)  NULL,
	[Fiscal Quarter] [varchar](5000)  NULL,
	[Fiscal Month] [int]  NULL,
	[Country] [varchar](5000)  NULL,
	[Region] [varchar](5000)  NULL,
	[Customer Segment] [varchar](5000)  NULL,
	[Channel] [varchar](5000)  NULL,
	[Product] [varchar](5000)  NULL,
	[ProductCategory] [varchar](5000)  NULL,
	[Gross Sales] [decimal](18,0)  NULL,
	[Budget] [decimal](18,0)  NULL,
	[Forecast] [decimal](18,0)  NULL,
	[Discount] [decimal](18,0)  NULL,
	[Net Sales] [decimal](18,0)  NULL,
	[COGS] [decimal](18,0)  NULL,
	[Gross Profit] [decimal](18,0)  NULL,
	[Half Yearly] [varchar](50)  NULL,
	[VTB ($)] [decimal](18,0)  NULL,
	[VTB (%)] [decimal](18,0)  NULL,
	[link] [varchar](500)  NULL,
	[description] [varchar](500)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[LocationAnalytics]', N'U') IS NOT NULL   
DROP TABLE [dbo].[LocationAnalytics]

CREATE TABLE [dbo].[LocationAnalytics]
( 
	[Day] [datetime2](7)  NOT NULL,
	[Region] [varchar](50)  NOT NULL,
	[Product_Category] [varchar](50)  NOT NULL,
	[Visit_Start] [float]  NOT NULL,
	[Visit_End] [float]  NOT NULL,
	[Hour] [int]  NOT NULL,
	[Visitor_ID] [varchar](50)  NULL,
	[First_Visit] [bit]  NOT NULL,
	[Duration] [int]  NOT NULL,
	[Minutes] [varchar](50)  NOT NULL,
	[Visit_Type] [varchar](50)  NOT NULL,
	[Country] [varchar](50)  NOT NULL,
	[Department] [varchar](50)  NOT NULL,
	[Gender] [varchar](50)  NOT NULL,
	[Customer_Segment] [varchar](50)  NOT NULL,
	[Date] [varchar](50)  NOT NULL,
	[Stores] [int]  NOT NULL,
	[Engagement] [varchar](50)  NOT NULL,
	[Acquisition] [varchar](50)  NOT NULL,
	[Impressions] [varchar](50)  NOT NULL,
	[Conversion] [varchar](50)  NOT NULL,
	[Revenue] [varchar](50)  NULL,
	[WeekDay] [varchar](50)  NOT NULL,
	[SortByVisitType] [varchar](50)  NOT NULL,
	[Engaged_Visitors] [varchar](50)  NOT NULL,
	[Week_Number] [varchar](50)  NOT NULL,
	[Target_Visitors] [varchar](50)  NOT NULL,
	[Variance] [varchar](50)  NOT NULL,
	[Column28] [varchar](1)  NULL,
	[Column29] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[ProductLink2]', N'U') IS NOT NULL   
DROP TABLE [dbo].[ProductLink2]

CREATE TABLE [dbo].[ProductLink2]
( 
	[Product] [nvarchar](4000)  NULL,
	[Link] [nvarchar](4000)  NULL,
	[ReadOnlyLink] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[ProductRecommendations]', N'U') IS NOT NULL   
DROP TABLE [dbo].[ProductRecommendations]

CREATE TABLE [dbo].[ProductRecommendations]
( 
	[Product] [nvarchar](4000)  NULL,
	[Recommeded Product] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[BrandAwareness]', N'U') IS NOT NULL   
DROP TABLE [dbo].[BrandAwareness]

CREATE TABLE [dbo].[BrandAwareness]
( 
	[Region] [varchar](50)  NOT NULL,
	[Country] [varchar](50)  NOT NULL,
	[Product_Category] [varchar](50)  NOT NULL,
	[Department] [varchar](50)  NOT NULL,
	[Gender] [varchar](50)  NOT NULL,
	[Customer_Segment] [varchar](50)  NOT NULL,
	[Date] [datetime2](7)  NOT NULL,
	[Popularity] [float]  NOT NULL,
	[Engagement] [float]  NOT NULL,
	[Acquisition] [float]  NOT NULL,
	[Loyalty] [float]  NOT NULL,
	[Conversion] [float]  NOT NULL,
	[Revenue] [int]  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[OperatingExpenses]', N'U') IS NOT NULL   
DROP TABLE [dbo].[OperatingExpenses]

CREATE TABLE [dbo].[OperatingExpenses]
( 
	[Class] [varchar](5000)  NULL,
	[Country] [varchar](5000)  NULL,
	[Function Summary] [varchar](5000)  NULL,
	[Line Item] [varchar](5000)  NULL,
	[P&L Classification] [varchar](5000)  NULL,
	[VTB (%)] [varchar](5000)  NULL,
	[Actual ($)] [varchar](5000)  NULL,
	[Budget ($)] [varchar](5000)  NULL,
	[VTB ($)] [varchar](5000)  NULL,
	[YoY ($)] [varchar](5000)  NULL,
	[Channel] [varchar](5000)  NULL,
	[Region] [varchar](5000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[ProductLink]', N'U') IS NOT NULL   
DROP TABLE [dbo].[ProductLink]

CREATE TABLE [dbo].[ProductLink]
( 
	[Product] [nvarchar](4000)  NULL,
	[Link] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[SalesMaster]', N'U') IS NOT NULL   
DROP TABLE [dbo].[SalesMaster]

CREATE TABLE [dbo].[SalesMaster]
( 
	[Fiscal Year] [varchar](5000)  NULL,
	[Fiscal Quarter] [varchar](5000)  NULL,
	[Fiscal Month] [varchar](5000)  NULL,
	[Country] [varchar](5000)  NULL,
	[Region] [varchar](5000)  NULL,
	[Customer Segment] [varchar](5000)  NULL,
	[Channel] [varchar](5000)  NULL,
	[Product] [varchar](5000)  NULL,
	[Product Category] [varchar](5000)  NULL,
	[Gross Sales] [varchar](5000)  NULL,
	[Budget] [varchar](5000)  NULL,
	[Forecast] [varchar](5000)  NULL,
	[Discount] [varchar](5000)  NULL,
	[Net Sales] [varchar](5000)  NULL,
	[COGS] [varchar](5000)  NULL,
	[Gross Profit] [varchar](5000)  NULL,
	[Half Yearly] [varchar](5000)  NULL,
	[VTB ($)] [varchar](5000)  NULL,
	[VTB (%)] [varchar](5000)  NULL,
	[agegroup] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[SalesVsExpense]', N'U') IS NOT NULL   
DROP TABLE [dbo].[SalesVsExpense]

CREATE TABLE [dbo].[SalesVsExpense]
( 
	[Accounting Head] [varchar](5000)  NULL,
	[Amount] [varchar](5000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[FPA]', N'U') IS NOT NULL   
DROP TABLE [dbo].[FPA]

CREATE TABLE [dbo].[FPA]
( 
	[Fiscal Year] [varchar](5000)  NULL,
	[Fiscal Quarter] [varchar](5000)  NULL,
	[Fiscal Month] [varchar](5000)  NULL,
	[Country] [varchar](5000)  NULL,
	[Forecast] [varchar](5000)  NULL,
	[Budget] [varchar](5000)  NULL,
	[Actual] [varchar](5000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[Country]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Country]

CREATE TABLE [dbo].[Country]
( 
	[ID] [varchar](5000)  NULL,
	[Country] [varchar](5000)  NULL,
	[Region] [varchar](5000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[CampaignAnalytics]', N'U') IS NOT NULL   
DROP TABLE [dbo].[CampaignAnalytics]

CREATE TABLE [dbo].[CampaignAnalytics]
( 
	[Region] [varchar](50)  NOT NULL,
	[Country] [varchar](50)  NOT NULL,
	[Product_Category] [varchar](50)  NOT NULL,
	[Campaign_ID] [varchar](50)  NOT NULL,
	[Campaign_Name] [varchar](50)  NOT NULL,
	[Qualification] [varchar](50)  NOT NULL,
	[Qualification_Number] [varchar](50)  NOT NULL,
	[Response_Status] [varchar](50)  NOT NULL,
	[Responses] [int]  NOT NULL,
	[Cost] [int]  NOT NULL,
	[Revenue] [varchar](50)  NOT NULL,
	[ROI] [varchar](50)  NOT NULL,
	[Lead_Generation] [int]  NOT NULL,
	[Revenue_Target] [varchar](50)  NOT NULL,
	[Campaign_Tactic] [varchar](50)  NOT NULL,
	[Customer_Segment] [varchar](50)  NOT NULL,
	[Status] [varchar](50)  NOT NULL,
	[Profit] [varchar](50)  NOT NULL,
	[Marketing_Cost] [varchar](50)  NOT NULL,
	[Revenue_Varriance] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[Books]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Books]

CREATE TABLE [dbo].[Books]
( 
	[ID] [float]  NOT NULL,
	[BookListID] [float]  NULL,
	[Title] [varchar](255)  NULL,
	[Author] [varchar](255)  NULL,
	[Duration] [float]  NULL,
	[Image] [varchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[BookConsumption]', N'U') IS NOT NULL   
DROP TABLE [dbo].[BookConsumption]

CREATE TABLE [dbo].[BookConsumption]
( 
	[BookID] [float]  NULL,
	[Clicks] [float]  NULL,
	[Downloads] [float]  NULL,
	[Time Spent] [float]  NULL,
	[Country] [varchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[EmailAnalytics]', N'U') IS NOT NULL   
DROP TABLE [dbo].[EmailAnalytics]

CREATE TABLE [dbo].[EmailAnalytics]
( 
	[Recency] [varchar](50)  NOT NULL,
	[History_Segment_ID] [varchar](50)  NOT NULL,
	[History_Segment] [varchar](50)  NOT NULL,
	[History] [varchar](50)  NOT NULL,
	[Men] [varchar](50)  NOT NULL,
	[Women] [varchar](50)  NOT NULL,
	[Zip_Code] [varchar](50)  NOT NULL,
	[Newbie] [varchar](50)  NOT NULL,
	[Channel] [varchar](50)  NOT NULL,
	[Segment] [varchar](50)  NOT NULL,
	[Opens] [varchar](50)  NOT NULL,
	[Clicks] [varchar](50)  NOT NULL,
	[Revenue] [varchar](50)  NOT NULL,
	[Category_ID] [varchar](50)  NOT NULL,
	[Product_Category] [varchar](50)  NOT NULL,
	[Date] [datetime2](7)  NOT NULL,
	[Campaign] [varchar](50)  NOT NULL,
	[Region] [varchar](50)  NOT NULL,
	[Customer_Segment] [varchar](50)  NOT NULL,
	[Gender] [varchar](50)  NOT NULL,
	[Email_Status] [varchar](50)  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)

IF OBJECT_ID(N'[dbo].[DimDate]', N'U') IS NOT NULL   
DROP TABLE [dbo].[DimDate]

CREATE TABLE [dbo].[DimDate]
( 
	[Date] [datetime]  NOT NULL,
	[Day Number] [int]  NOT NULL,
	[Day] [nvarchar](10)  NOT NULL,
	[Month] [nvarchar](10)  NOT NULL,
	[Short Month] [nvarchar](3)  NOT NULL,
	[Calendar Month Number] [int]  NOT NULL,
	[Calendar Month Label] [nvarchar](20)  NOT NULL,
	[Calendar Year] [int]  NOT NULL,
	[Calendar Year Label] [nvarchar](10)  NOT NULL,
	[Fiscal Month Number] [int]  NOT NULL,
	[Fiscal Month Label] [nvarchar](20)  NOT NULL,
	[Fiscal Year] [int]  NOT NULL,
	[Fiscal Year Label] [nvarchar](10)  NOT NULL,
	[ISO Week Number] [int]  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[Popularity]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Popularity]

CREATE TABLE [dbo].[Popularity]
( 
	[BookID] [float]  NULL,
	[Rank] [float]  NULL,
	[Country] [nvarchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[FinalRevenue]', N'U') IS NOT NULL   
DROP TABLE [dbo].[FinalRevenue]

CREATE TABLE [dbo].[FinalRevenue]
( 
	[Month] [nvarchar](4000)  NULL,
	[Order] [nvarchar](4000)  NULL,
	[Revenue] [nvarchar](4000)  NULL,
	[Quarter] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[ConflictofInterest]', N'U') IS NOT NULL   
DROP TABLE [dbo].[ConflictofInterest]

CREATE TABLE [dbo].[ConflictofInterest]
( 
	[FiscalYear-Quarter] [varchar](5000)  NULL,
	[Fiscal Year] [varchar](5000)  NULL,
	[Fiscal Quarter] [varchar](5000)  NULL,
	[Country] [varchar](5000)  NULL,
	[Region] [varchar](5000)  NULL,
	[Required] [varchar](5000)  NULL,
	[Complete] [varchar](5000)  NULL,
	[Survey NC] [varchar](5000)  NULL,
	[Incomplete] [varchar](5000)  NULL,
	[Function Summary] [varchar](5000)  NULL,
	[Complete %] [varchar](5000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[CampaignAnalytics]', N'U') IS NOT NULL   
DROP TABLE [dbo].[CampaignAnalytics]

CREATE TABLE [dbo].[CampaignAnalytics]
( 
	[Region] [varchar](50)  NOT NULL,
	[Country] [varchar](50)  NOT NULL,
	[Product_Category] [varchar](50)  NOT NULL,
	[Campaign_ID] [varchar](50)  NOT NULL,
	[Campaign_Name] [varchar](50)  NOT NULL,
	[Qualification] [varchar](50)  NOT NULL,
	[Qualification_Number] [varchar](50)  NOT NULL,
	[Response_Status] [varchar](50)  NOT NULL,
	[Responses] [int]  NOT NULL,
	[Cost] [int]  NOT NULL,
	[Revenue] [varchar](50)  NOT NULL,
	[ROI] [varchar](50)  NOT NULL,
	[Lead_Generation] [int]  NOT NULL,
	[Revenue_Target] [varchar](50)  NOT NULL,
	[Campaign_Tactic] [varchar](50)  NOT NULL,
	[Customer_Segment] [varchar](50)  NOT NULL,
	[Status] [varchar](50)  NOT NULL,
	[Profit] [varchar](50)  NOT NULL,
	[Marketing_Cost] [varchar](50)  NOT NULL,
	[Revenue_Varriance] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[SiteSecurity]', N'U') IS NOT NULL   
DROP TABLE [dbo].[SiteSecurity]

CREATE TABLE [dbo].[SiteSecurity]
( 
	[FiscalQuarter] [varchar](5000)  NULL,
	[FiscalYear] [varchar](5000)  NULL,
	[FiscalMonth] [varchar](5000)  NULL,
	[Country] [varchar](5000)  NULL,
	[Region] [varchar](5000)  NULL,
	[Phase] [varchar](5000)  NULL,
	[Total Vulnerabilities] [varchar](5000)  NULL,
	[Total Open Vulnerabilities] [varchar](5000)  NULL,
	[Status] [varchar](5000)  NULL,
	[Data Classification] [varchar](5000)  NULL,
	[App Scan High Risk] [varchar](5000)  NULL,
	[App Scan Low Risk] [varchar](5000)  NULL,
	[Host Scan high Risk] [varchar](5000)  NULL,
	[Host Scan Low Risk] [varchar](5000)  NULL,
	[Active Sites Not Scanned] [varchar](5000)  NULL,
	[Site Status] [varchar](5000)  NULL,
	[Total Vuln] [varchar](5000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[BookList]', N'U') IS NOT NULL   
DROP TABLE [dbo].[BookList]

CREATE TABLE [dbo].[BookList]
( 
	[ID] [float]  NOT NULL,
	[CategoryID] [float]  NULL,
	[BookList] [varchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[WebsiteSocialAnalyticsPBIData]', N'U') IS NOT NULL   
DROP TABLE [dbo].[WebsiteSocialAnalyticsPBIData]

CREATE TABLE [dbo].[WebsiteSocialAnalyticsPBIData]
( 
	[Country] [varchar](50)  NULL,
	[Product_Category] [varchar](50)  NULL,
	[Product] [varchar](50)  NULL,
	[Channel] [varchar](50)  NULL,
	[Gender] [varchar](50)  NULL,
	[Sessions] [int]  NULL,
	[Device_Category] [varchar](50)  NULL,
	[Sources] [varchar](50)  NULL,
	[Conversations] [varchar](50)  NULL,
	[Page] [varchar](50)  NULL,
	[Visits] [int]  NULL,
	[Unique_Visitors] [int]  NULL,
	[Browser] [varchar](50)  NULL,
	[Sentiment] [varchar](50)  NULL,
	[Duration_min] [varchar](50)  NULL,
	[Region] [varchar](50)  NULL,
	[Customer_Segment] [varchar](50)  NULL,
	[Daily_Users] [int]  NULL,
	[Conversion_Rate] [int]  NULL,
	[Return_Visitors] [int]  NULL,
	[Tweets] [int]  NULL,
	[Retweets] [int]  NULL,
	[Hashtags] [varchar](50)  NULL,
	[Campaign_Name] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[CampaignAnalyticLatest]', N'U') IS NOT NULL   
DROP TABLE [dbo].[CampaignAnalyticLatest]

CREATE TABLE [dbo].[CampaignAnalyticLatest]
( 
	[Region] [nvarchar](4000)  NULL,
	[Country] [nvarchar](4000)  NULL,
	[ProductCategory] [nvarchar](4000)  NULL,
	[Campaign_ID] [nvarchar](4000)  NULL,
	[Campaign_Name] [nvarchar](4000)  NULL,
	[Qualification] [nvarchar](4000)  NULL,
	[Qualification_Number] [nvarchar](4000)  NULL,
	[Response_Status] [nvarchar](4000)  NULL,
	[Responses] [nvarchar](4000)  NULL,
	[Cost] [nvarchar](4000)  NULL,
	[Revenue] [nvarchar](4000)  NULL,
	[ROI] [nvarchar](4000)  NULL,
	[Lead_Generation] [nvarchar](4000)  NULL,
	[Revenue_Target] [nvarchar](4000)  NULL,
	[Campaign_Tactic] [nvarchar](4000)  NULL,
	[Customer_Segment] [nvarchar](4000)  NULL,
	[Status] [nvarchar](4000)  NULL,
	[Profit] [nvarchar](4000)  NULL,
	[Marketing_Cost] [nvarchar](4000)  NULL,
	[CampaignID] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[location_Analytics]', N'U') IS NOT NULL   
DROP TABLE [dbo].[location_Analytics]

CREATE TABLE [dbo].[location_Analytics]
( 
	[Day] [datetime2](7)  NOT NULL,
	[Region] [varchar](50)  NOT NULL,
	[Product_Category] [varchar](50)  NOT NULL,
	[Visit_Start] [float]  NOT NULL,
	[Visit_End] [float]  NOT NULL,
	[Hour] [int]  NOT NULL,
	[Visitor_ID] [varchar](50)  NULL,
	[First_Visit] [bit]  NOT NULL,
	[Duration] [int]  NOT NULL,
	[Minutes] [varchar](50)  NOT NULL,
	[Visit_Type] [varchar](50)  NOT NULL,
	[Country] [varchar](50)  NOT NULL,
	[Department] [varchar](50)  NOT NULL,
	[Gender] [varchar](50)  NOT NULL,
	[Customer_Segment] [varchar](50)  NOT NULL,
	[Date] [varchar](50)  NOT NULL,
	[Stores] [int]  NOT NULL,
	[Engagement] [varchar](50)  NOT NULL,
	[Acquisition] [varchar](50)  NOT NULL,
	[Impressions] [varchar](50)  NOT NULL,
	[Conversion] [varchar](50)  NOT NULL,
	[Revenue] [varchar](50)  NULL,
	[WeekDay] [varchar](50)  NOT NULL,
	[SortByVisitType] [varchar](50)  NOT NULL,
	[Engaged_Visitors] [varchar](50)  NOT NULL,
	[Week_Number] [varchar](50)  NOT NULL,
	[Target_Visitors] [varchar](50)  NOT NULL,
	[Variance] [varchar](50)  NOT NULL,
	[Column28] [varchar](1)  NULL,
	[Column29] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[DimData]', N'U') IS NOT NULL   
DROP TABLE [dbo].[DimData]

CREATE TABLE [dbo].[DimData]
( 
	[DateKey] [int]  NOT NULL,
	[DateValue] [datetime2](7)  NOT NULL,
	[DayOfMonth] [varchar](50)  NOT NULL,
	[DayOfYear] [varchar](50)  NOT NULL,
	[Year] [int]  NOT NULL,
	[MonthOfYear] [varchar](50)  NOT NULL,
	[MonthName] [varchar](50)  NOT NULL,
	[QuarterOfYear] [varchar](50)  NOT NULL,
	[QuarterName] [varchar](50)  NOT NULL,
	[WeekEnding] [datetime2](7)  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[salesPBIData]', N'U') IS NOT NULL   
DROP TABLE [dbo].[salesPBIData]

CREATE TABLE [dbo].[salesPBIData]
( 
	[Fiscal Year] [nvarchar](4000)  NULL,
	[Fiscal Quarter] [nvarchar](4000)  NULL,
	[Fiscal Month] [nvarchar](4000)  NULL,
	[Country] [nvarchar](4000)  NULL,
	[Region] [nvarchar](4000)  NULL,
	[Customer Segment] [nvarchar](4000)  NULL,
	[Channel] [nvarchar](4000)  NULL,
	[Product] [nvarchar](4000)  NULL,
	[Product Category] [nvarchar](4000)  NULL,
	[Gross Sales] [nvarchar](4000)  NULL,
	[Budget] [nvarchar](4000)  NULL,
	[Forecast] [nvarchar](4000)  NULL,
	[Discount] [nvarchar](4000)  NULL,
	[Net Sales] [nvarchar](4000)  NULL,
	[COGS] [nvarchar](4000)  NULL,
	[Gross Profit] [nvarchar](4000)  NULL,
	[Half Yearly] [nvarchar](4000)  NULL,
	[VTB ($)] [nvarchar](4000)  NULL,
	[VTB (%)] [nvarchar](4000)  NULL,
	[link] [nvarchar](4000)  NULL,
	[description] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[Customer_SalesLatest]', N'U') IS NOT NULL   
DROP TABLE [dbo].[Customer_SalesLatest]

CREATE TABLE [dbo].[Customer_SalesLatest]
( 
	[customer_id] [int]  NULL,
	[product_id] [int]  NULL,
	[product_name] [varchar](8000)  NULL,
	[total_quantity] [int]  NULL,
	[rating] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[department_visit_customer]', N'U') IS NOT NULL   
DROP TABLE [dbo].[department_visit_customer]

CREATE TABLE [dbo].[department_visit_customer]
( 
	[Date] [nvarchar](4000)  NULL,
	[Accessories_count] [nvarchar](4000)  NULL,
	[Entertainment_count] [nvarchar](4000)  NULL,
	[Gaming] [nvarchar](4000)  NULL,
	[Kids] [nvarchar](4000)  NULL,
	[Mens] [nvarchar](4000)  NULL,
	[Phone_and_GPS] [nvarchar](4000)  NULL,
	[Womens] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[CustomerVisitF_Spark]', N'U') IS NOT NULL   
DROP TABLE [dbo].[CustomerVisitF_Spark]

CREATE TABLE [dbo].[CustomerVisitF_Spark]
(
    [Date] date,
    Accessories int,
    Entertainment int,
    Gaming int,
    Kids int,
    Mens int,
    Phone_and_GPS int,
    Womens int
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

IF OBJECT_ID(N'[dbo].[ProductRecommendations_Sparkv2]', N'U') IS NOT NULL   
DROP TABLE [dbo].[ProductRecommendations_Sparkv2]

CREATE TABLE [dbo].[ProductRecommendations_Sparkv2]
( 
	[ProductId] [int]  NOT NULL,
	[ProductName] [nvarchar](100)  NOT NULL,
	[RecommendedProductId] [int]  NOT NULL,
	[RecommendedProductName] [nvarchar](100)  NOT NULL,
	[Similarity] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO