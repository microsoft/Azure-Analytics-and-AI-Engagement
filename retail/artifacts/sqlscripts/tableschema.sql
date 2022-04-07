SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_EsgCompanyVsTopicProbability]
( 
	[Organisation] [nvarchar](256)  NULL,
	[CodeOfConduct] [decimal](2,1)  NULL,
	[CompanyTransformation] [decimal](2,1)  NULL,
	[ValueEmployees] [decimal](2,1)  NULL,
	[FocusCustomer] [decimal](2,1)  NULL,
	[SustainableFinance] [decimal](2,1)  NULL,
	[SupportCommunity] [decimal](2,1)  NULL,
	[StrongGovernance] [decimal](2,1)  NULL,
	[EthicalInvestments] [decimal](2,1)  NULL,
	[GreenEnergy] [decimal](2,1)  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_ESGOrgConnections]
( 
	[Organisation] [nvarchar](256)  NULL,
	[Connection] [nvarchar](256)  NULL,
	[Importance] [float]  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_EsgOrgContribution]
( 
	[Organisation] [nvarchar](256)  NULL,
	[Theme] [nvarchar](256)  NULL,
	[ESG] [float]  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_EsgOrgDetractors]
( 
	[Organisation] [nvarchar](256)  NULL,
	[Company] [nvarchar](256)  NULL,
	[Importance] [float]  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_EsgOrgSentiment]
( 
	[Date] [datetime2](7)  NULL,
	[Organisation] [nvarchar](256)  NULL,
	[Delta] [float]  NULL,
	[7DayRolling] [float]  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_EsgOrgWordCloudData]
( 
	[Organisation] [nvarchar](1000)  NULL,
	[Lemma] [nvarchar](max)  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_ESGScores]
( 
	[Organisation] [nvarchar](256)  NULL,
	[Theme] [nvarchar](256)  NULL,
	[Total] [bigint]  NULL,
	[Days] [bigint]  NULL,
	[ESG] [float]  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_EsgSentimentAndCustomerChurn]
( 
	[date] [datetime2](7)  NULL,
	[organisation] [nvarchar](256)  NULL,
	[30DaysSentimentValue] [float]  NULL,
	[churn] [float]  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_EsgSentimentVsMarketPerformance]
( 
	[Date] [datetime2](7)  NULL,
	[30DaysSentimentValue] [float]  NULL,
	[7DaysStockPrice] [float]  NULL,
	[Organisation] [nvarchar](256)  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_ESGWeightedScore]
( 
	[Organisation] [nvarchar](256)  NULL,
	[Theme] [nvarchar](256)  NULL,
	[ESG] [float]  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AggregatedSales_SAPHANA]
( 
	[ProductKey] [nvarchar](max)  NULL,
	[SalesAmount] [nvarchar](max)  NULL,
	[OrderYear] [int]  NULL,
	[OrderMonth] [int]  NULL,
	[TotalSales] [bigint]  NULL,
	[AvgSalesAmount] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Automotive]
( 
	[marketplace] [nvarchar](max)  NULL,
	[customer_id] [nvarchar](max)  NULL,
	[review_id] [nvarchar](max)  NULL,
	[product_id] [nvarchar](max)  NULL,
	[product_parent] [nvarchar](max)  NULL,
	[product_title] [nvarchar](max)  NULL,
	[product_category] [nvarchar](max)  NULL,
	[star_rating] [nvarchar](max)  NULL,
	[helpful_votes] [nvarchar](max)  NULL,
	[total_votes] [nvarchar](max)  NULL,
	[vine] [nvarchar](max)  NULL,
	[verified_purchase] [nvarchar](max)  NULL,
	[review_headline] [nvarchar](max)  NULL,
	[review_body] [nvarchar](max)  NULL,
	[review_date] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Campaign_Analytics]
( 
	[Region] [varchar](50)  NULL,
	[Country] [varchar](50)  NULL,
	[Product_Category] [varchar](50)  NULL,
	[Campaign_Name] [varchar](50)  NULL,
	[Revenue] [varchar](50)  NULL,
	[Revenue_Target] [varchar](50)  NULL,
	[City] [varchar](50)  NULL,
	[State] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Campaign_Analytics_New]
( 
	[Region] [varchar](50)  NULL,
	[Country] [varchar](50)  NULL,
	[Product_Category] [varchar](50)  NULL,
	[Campaign_Name] [varchar](50)  NULL,
	[Revenue] [varchar](50)  NULL,
	[Revenue_Target] [varchar](50)  NULL,
	[RoleID] [varchar](10)  NULL,
	[City] [nvarchar](100)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
	[Responses] [float]  NULL,
	[Cost] [float]  NULL,
	[Revenue] [float]  NULL,
	[ROI] [float]  NULL,
	[Lead_Generation] [nvarchar](4000)  NULL,
	[Revenue_Target] [float]  NULL,
	[Campaign_Tactic] [nvarchar](4000)  NULL,
	[Customer_Segment] [nvarchar](4000)  NULL,
	[Status] [nvarchar](4000)  NULL,
	[Profit] [float]  NULL,
	[Marketing_Cost] [float]  NULL,
	[CampaignID] [nvarchar](4000)  NULL,
	[Date] [datetime]  NULL,
	[SORTED_ID] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CampaignAnalyticLatestBKP]
( 
	[Region] [nvarchar](4000)  NULL,
	[Country] [nvarchar](4000)  NULL,
	[ProductCategory] [nvarchar](4000)  NULL,
	[Campaign_ID] [nvarchar](4000)  NULL,
	[Campaign_Name] [nvarchar](4000)  NULL,
	[Qualification] [nvarchar](4000)  NULL,
	[Qualification_Number] [nvarchar](4000)  NULL,
	[Response_Status] [nvarchar](4000)  NULL,
	[Responses] [float]  NULL,
	[Cost] [float]  NULL,
	[Revenue] [float]  NULL,
	[ROI] [float]  NULL,
	[Lead_Generation] [nvarchar](4000)  NULL,
	[Revenue_Target] [float]  NULL,
	[Campaign_Tactic] [nvarchar](4000)  NULL,
	[Customer_Segment] [nvarchar](4000)  NULL,
	[Status] [nvarchar](4000)  NULL,
	[Profit] [float]  NULL,
	[Marketing_Cost] [float]  NULL,
	[CampaignID] [nvarchar](4000)  NULL,
	[Date] [datetime]  NULL,
	[SORTED_ID] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CampaignAnalytics]
( 
	[Region] [varchar](50)  NULL,
	[Country] [varchar](50)  NULL,
	[Product_Category] [varchar](50)  NULL,
	[Campaign_ID] [varchar](50)  NULL,
	[Campaign_Name] [varchar](50)  NULL,
	[Qualification] [varchar](50)  NULL,
	[Qualification_Number] [varchar](50)  NULL,
	[Response_Status] [varchar](50)  NULL,
	[Responses] [int]  NULL,
	[Cost] [int]  NULL,
	[Revenue] [varchar](50)  NULL,
	[ROI] [varchar](50)  NULL,
	[Lead_Generation] [int]  NULL,
	[Revenue_Target] [varchar](50)  NULL,
	[Campaign_Tactic] [varchar](50)  NULL,
	[Customer_Segment] [varchar](50)  NULL,
	[Status] [varchar](50)  NULL,
	[Profit] [varchar](50)  NULL,
	[Marketing_Cost] [varchar](50)  NULL,
	[Revenue_Varriance] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Campaigns]
( 
	[Campaigns_ID] [int]  NULL,
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CohortAnalysis]
( 
	[High Loyal] [nvarchar](max)  NULL,
	[Column1] [nvarchar](max)  NULL,
	[Customer ID] [nvarchar](max)  NULL,
	[Frequency] [nvarchar](max)  NULL,
	[FrequencyCluster] [nvarchar](max)  NULL,
	[OverallScore] [nvarchar](max)  NULL,
	[RecencyCluster] [nvarchar](max)  NULL,
	[Recency] [nvarchar](max)  NULL,
	[Revenue] [nvarchar](max)  NULL,
	[RevenueCluster] [nvarchar](max)  NULL,
	[Segment] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ConflictofInterest]
( 
	[FiscalYear-Quarter] [varchar](20)  NULL,
	[Fiscal Year] [varchar](20)  NULL,
	[Fiscal Quarter] [varchar](20)  NULL,
	[Country] [varchar](20)  NULL,
	[Region] [varchar](50)  NULL,
	[Required] [varchar](10)  NULL,
	[Complete] [varchar](20)  NULL,
	[Survey NC] [varchar](10)  NULL,
	[Incomplete] [varchar](10)  NULL,
	[Function Summary] [varchar](50)  NULL,
	[Complete %] [varchar](20)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Country]
( 
	[ID] [varchar](10)  NULL,
	[Country] [varchar](20)  NULL,
	[Region] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[customer_segment_rfm]
( 
	[CustomerID] [nvarchar](max)  NULL,
	[Recency] [nvarchar](max)  NULL,
	[RecencyCluster] [nvarchar](max)  NULL,
	[Frequency] [nvarchar](max)  NULL,
	[FrequencyCluster] [nvarchar](max)  NULL,
	[Revenue] [nvarchar](max)  NULL,
	[RevenueCluster] [nvarchar](max)  NULL,
	[OverallScore] [nvarchar](max)  NULL,
	[Segment] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerInfo]
( 
	[UserName] [nvarchar](4000)  NULL,
	[Gender] [nvarchar](4000)  NULL,
	[Phone] [nvarchar](4000)  NULL,
	[Email] [nvarchar](4000)  NULL,
	[CreditCard] [nvarchar](19)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerSalesHana]
( 
	[ProductKey] [nvarchar](max)  NULL,
	[OrderDateKey] [nvarchar](max)  NULL,
	[DueDateKey] [nvarchar](max)  NULL,
	[ShipDateKey] [nvarchar](max)  NULL,
	[CustomerKey] [nvarchar](max)  NULL,
	[PromotionKey] [nvarchar](max)  NULL,
	[CurrencyKey] [nvarchar](max)  NULL,
	[SalesTerritoryKey] [nvarchar](max)  NULL,
	[SalesOrderNumber] [nvarchar](max)  NULL,
	[SalesOrderLineNumber] [nvarchar](max)  NULL,
	[RevisionNumber] [nvarchar](max)  NULL,
	[OrderQuantity] [nvarchar](max)  NULL,
	[UnitPrice] [int]  NULL,
	[ExtendedAmount] [int]  NULL,
	[UnitPriceDiscountPct] [nvarchar](max)  NULL,
	[DiscountAmount] [nvarchar](max)  NULL,
	[ProductStandardCost] [int]  NULL,
	[TotalProductCost] [nvarchar](max)  NULL,
	[SalesAmount] [nvarchar](max)  NULL,
	[TaxAmt] [nvarchar](max)  NULL,
	[Freight] [nvarchar](max)  NULL,
	[CarrierTrackingNumber] [nvarchar](max)  NULL,
	[CustomerPONumber] [nvarchar](max)  NULL,
	[OrderDate] [nvarchar](max)  NULL,
	[DueDate] [nvarchar](max)  NULL,
	[ShipDate] [nvarchar](max)  NULL,
	[OrderYear] [int]  NULL,
	[OrderMonth] [int]  NULL,
	[OrderDay] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerVisitF]
( 
	[Date] [nvarchar](4000)  NULL,
	[Gaming] [float]  NULL,
	[Kids] [float]  NULL,
	[Mens] [float]  NULL,
	[Phone_and_GPS] [float]  NULL,
	[Womens] [float]  NULL,
	[Accessories] [float]  NULL,
	[Entertainment] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[customerVisitsInPersonByLocation]
( 
	[City] [nvarchar](max)  NULL,
	[Month] [nvarchar](max)  NULL,
	[Total Visits] [nvarchar](max)  NULL,
	[Unique Visitors] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DailyStockData]
( 
	[Portfolio] [nvarchar](1000)  NULL,
	[Sector] [nvarchar](1000)  NULL,
	[Cik] [nvarchar](1000)  NULL,
	[Date] [nvarchar](1000)  NULL,
	[Ticker] [nvarchar](1000)  NULL,
	[AdjClose] [nvarchar](1000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimData]
( 
	[DateKey] [int]  NULL,
	[DateValue] [datetime2](7)  NULL,
	[DayOfMonth] [varchar](50)  NULL,
	[DayOfYear] [varchar](50)  NULL,
	[Year] [int]  NULL,
	[MonthOfYear] [varchar](50)  NULL,
	[MonthName] [varchar](50)  NULL,
	[QuarterOfYear] [varchar](50)  NULL,
	[QuarterName] [varchar](50)  NULL,
	[WeekEnding] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EmailAnalytics]
( 
	[Recency] [varchar](50)  NULL,
	[History_Segment_ID] [varchar](50)  NULL,
	[History_Segment] [varchar](50)  NULL,
	[History] [float]  NULL,
	[Men] [varchar](50)  NULL,
	[Women] [varchar](50)  NULL,
	[Zip_Code] [varchar](50)  NULL,
	[Newbie] [varchar](50)  NULL,
	[Channel] [varchar](50)  NULL,
	[Segment] [varchar](50)  NULL,
	[Opens] [varchar](50)  NULL,
	[Clicks] [varchar](50)  NULL,
	[Revenue] [float]  NULL,
	[Category_ID] [varchar](50)  NULL,
	[Product_Category] [varchar](50)  NULL,
	[Date] [datetime2](7)  NULL,
	[Campaign] [varchar](50)  NULL,
	[Region] [varchar](50)  NULL,
	[Customer_Segment] [varchar](50)  NULL,
	[Gender] [varchar](50)  NULL,
	[Email_Status] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Engagement_ActualVsForecast]
( 
	[Month] [datetime]  NULL,
	[Before] [nvarchar](max)  NULL,
	[CLine] [nvarchar](max)  NULL,
	[CLine_after] [nvarchar](max)  NULL,
	[Value] [nvarchar](max)  NULL,
	[Tweets] [float]  NULL,
	[Media] [float]  NULL,
	[Ads Clicked] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ESGOrganisation]
( 
	[Organisation] [nvarchar](1000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactSales]
( 
	[ProductID] [nvarchar](4000)  NULL,
	[Analyst] [nvarchar](4000)  NULL,
	[Product] [nvarchar](4000)  NULL,
	[CampaignName] [nvarchar](4000)  NULL,
	[Qty] [nvarchar](4000)  NULL,
	[Region] [nvarchar](4000)  NULL,
	[State] [nvarchar](4000)  NULL,
	[City] [nvarchar](4000)  NULL,
	[Revenue] [nvarchar](4000)  NULL,
	[RevenueTarget] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FinalRevenue]
( 
	[Month] [nvarchar](4000)  NULL,
	[Order] [nvarchar](4000)  NULL,
	[Revenue] [float]  NULL,
	[Quarter] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
	[Gross Sales] [float]  NULL,
	[Budget] [float]  NULL,
	[Forecast] [float]  NULL,
	[Discount] [float]  NULL,
	[Net Sales] [float]  NULL,
	[COGS] [float]  NULL,
	[Gross Profit] [decimal](18,0)  NULL,
	[Half Yearly] [varchar](50)  NULL,
	[VTB ($)] [float]  NULL,
	[VTB (%)] [float]  NULL,
	[link] [varchar](500)  NULL,
	[description] [varchar](500)  NULL,
	[Dates] [datetime]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FPA]
( 
	[Fiscal Year] [varchar](10)  NULL,
	[Fiscal Quarter] [varchar](10)  NULL,
	[Fiscal Month] [varchar](10)  NULL,
	[Country] [varchar](20)  NULL,
	[Forecast] [varchar](10)  NULL,
	[Budget] [varchar](20)  NULL,
	[Actual] [varchar](20)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[HeaderWIP]
( 
	[Operating_Profit(in USD millions)] [float]  NULL,
	[Operating_Profit_Target YTD(in USD millions)] [float]  NULL,
	[Revenue_Growth] [int]  NULL,
	[Revenue_Growth_Target YTD] [int]  NULL,
	[Marketing_Cost(in USD millions)] [float]  NULL,
	[Marketing_Cost YTD(in USD millions)] [float]  NULL,
	[Market_Sentiment] [int]  NULL,
	[ESG_Risk_Score] [int]  NULL,
	[Month] [varchar](15)  NULL,
	[Year] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[iot-foottraffic-data]
( 
	[RecordedOn] [nvarchar](max)  NULL,
	[before-foottraffic] [bigint]  NULL,
	[after-foottraffic] [bigint]  NULL,
	[EventProcessedUtcTime] [datetime2](7)  NULL,
	[PartitionId] [bigint]  NULL,
	[EventEnqueuedUtcTime] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[KS_CustomerInfo]
( 
	[ID] [int]  NOT NULL,
	[Region] [nvarchar](4000)  NULL,
	[UserName] [nvarchar](4000)  NULL,
	[Gender] [nvarchar](4000)  NULL,
	[Phone] [nvarchar](4000)  NULL,
	[Email] [nvarchar](4000)  NULL,
	[CreditCard] [nvarchar](19)  NULL,
	[Analyst] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Location_Analytics]
( 
	[Day] [datetime2](7)  NULL,
	[Region] [varchar](50)  NULL,
	[Product_Category] [varchar](50)  NULL,
	[Visit_Start] [float]  NULL,
	[Visit_End] [float]  NULL,
	[Hour] [int]  NULL,
	[Visitor_ID] [varchar](50)  NULL,
	[First_Visit] [bit]  NULL,
	[Duration] [float]  NULL,
	[Minutes] [varchar](50)  NULL,
	[Visit_Type] [varchar](50)  NULL,
	[Country] [varchar](50)  NULL,
	[Department] [varchar](50)  NULL,
	[Gender] [varchar](50)  NULL,
	[Customer_Segment] [varchar](50)  NULL,
	[Date] [varchar](50)  NULL,
	[Stores] [int]  NULL,
	[Engagement] [varchar](50)  NULL,
	[Acquisition] [varchar](50)  NULL,
	[Impressions] [varchar](50)  NULL,
	[Conversion] [varchar](50)  NULL,
	[Revenue] [float]  NULL,
	[WeekDay] [varchar](50)  NULL,
	[SortByVisitType] [varchar](50)  NULL,
	[Engaged_Visitors] [float]  NULL,
	[Week_Number] [varchar](50)  NULL,
	[Target_Visitors] [float]  NULL,
	[Variance] [varchar](50)  NULL,
	[Column28] [varchar](1)  NULL,
	[Column29] [varchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Magento_Address]
( 
	[AddressId] [bigint]  NULL,
	[CustomerStreetPoBoxAddress] [varchar](max)  NULL,
	[CustomerAddressCity] [varchar](max)  NULL,
	[CustomerAddressState] [varchar](max)  NULL,
	[CustomerAddressZipCode] [varchar](max)  NULL,
	[CustomerAddressCountry] [varchar](max)  NULL,
	[CustomerAddressRegion] [varchar](max)  NULL,
	[ConsumerStreetPoBoxAddress] [varchar](max)  NULL,
	[ConsumerAddressCity] [varchar](max)  NULL,
	[ConsumerAddressState] [varchar](max)  NULL,
	[ConsumerAddressZipCode] [varchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Magento_Customer]
( 
	[customer_id] [bigint]  NULL,
	[customer_firstname] [varchar](max)  NULL,
	[customer_lastname] [varchar](max)  NULL,
	[customer_middlename] [varchar](max)  NULL,
	[customer_date_of_birth] [date]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Magento_CustomerGender]
( 
	[CustomerId] [bigint]  NULL,
	[GenderId] [tinyint]  NULL,
	[CustomerGenderNote] [varchar](20)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Magento_Order]
( 
	[OrderId] [bigint]  NULL,
	[OrderReceivedTimestamp] [datetime]  NULL,
	[OrderEntryTimestamp] [datetime]  NULL,
	[OrderRequestedDeliveryDate] [date]  NULL,
	[ShipmentConfirmationTimestamp] [datetime]  NULL,
	[OrderActualDeliveryTimestamp] [datetime]  NULL,
	[OrderTotalInvoicedAmount] [decimal](10,2)  NULL,
	[TotalPaidAmount] [decimal](10,2)  NULL,
	[CustomerId] [bigint]  NULL,
	[OrderTotalRetailPriceAmount] [decimal](10,2)  NULL,
	[OrderTotalActualSalesPriceAmount] [decimal](10,2)  NULL,
	[OrderTotalAdjustmentPercentage] [decimal](10,2)  NULL,
	[OrderTotalAmount] [decimal](10,2)  NULL,
	[TotalShippingChargeAmount] [decimal](10,2)  NULL,
	[OrderTotalTaxAmount] [decimal](10,2)  NULL,
	[ProductId] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Magento_OrderLineStatus_New]
( 
	[OrderId] [nvarchar](max)  NULL,
	[OrderLineNumber] [nvarchar](max)  NULL,
	[OrderLineStatusStartTimestamp] [nvarchar](max)  NULL,
	[OrderLineStatusEndTimestamp] [nvarchar](max)  NULL,
	[OrderStatusTypeId] [nvarchar](max)  NULL,
	[Sku] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Magento_Product_New]
( 
	[ItemSku] [nvarchar](max)  NULL,
	[ProductName] [nvarchar](max)  NULL,
	[ProductDescription] [nvarchar](max)  NULL,
	[ProductShortDescription] [nvarchar](max)  NULL,
	[ProductId] [nvarchar](max)  NULL,
	[ProductSize] [nvarchar](max)  NULL,
	[BrandName] [nvarchar](max)  NULL,
	[Color] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[NewsAndSentiment]
( 
	[Symbol] [nvarchar](max)  NULL,
	[Name] [nvarchar](max)  NULL,
	[Url] [nvarchar](max)  NULL,
	[Date_Published] [nvarchar](max)  NULL,
	[Description] [nvarchar](max)  NULL,
	[Sentiment] [nvarchar](max)  NULL,
	[Positive_Score] [nvarchar](max)  NULL,
	[Negative_Score] [nvarchar](max)  NULL,
	[Neutral_Score] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OccupancyDate_0001]
( 
	[DeviceID] [nvarchar](max)  NULL,
	[StoreId] [nvarchar](max)  NULL,
	[EnqueuedTimeUTC] [nvarchar](max)  NULL,
	[BatteryLevel] [nvarchar](max)  NULL,
	[visitors_cnt] [nvarchar](max)  NULL,
	[visitors_in] [nvarchar](max)  NULL,
	[visitors_out] [nvarchar](max)  NULL,
	[avg_aisle_time_spent] [nvarchar](max)  NULL,
	[avg_dwell_time] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OccupancyDateNews]
( 
	[DeviceID] [nvarchar](max)  NULL,
	[StoreId] [nvarchar](max)  NULL,
	[EnqueuedTimeUTC] [nvarchar](max)  NULL,
	[BatteryLevel] [nvarchar](max)  NULL,
	[visitors_cnt] [nvarchar](max)  NULL,
	[visitors_in] [nvarchar](max)  NULL,
	[visitors_out] [nvarchar](max)  NULL,
	[avg_aisle_time_spent] [nvarchar](max)  NULL,
	[avg_dwell_time] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[occupancyHistoricalData]
( 
	[EnqueuedTimeUTC] [nvarchar](max)  NULL,
	[StoreId] [nvarchar](max)  NULL,
	[DeviceID] [nvarchar](max)  NULL,
	[BatteryLevel] [nvarchar](max)  NULL,
	[visitors_cnt] [nvarchar](max)  NULL,
	[visitors_in] [nvarchar](max)  NULL,
	[visitors_out] [nvarchar](max)  NULL,
	[avg_aisle_time_spent] [nvarchar](max)  NULL,
	[avg_dwell_time] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[occupancyHistoricalData2021]
( 
	[DeviceID] [nvarchar](max)  NULL,
	[StoreId] [nvarchar](max)  NULL,
	[EnqueuedTimeUTC] [nvarchar](max)  NULL,
	[BatteryLevel] [nvarchar](max)  NULL,
	[visitors_cnt] [nvarchar](max)  NULL,
	[visitors_in] [nvarchar](max)  NULL,
	[visitors_out] [nvarchar](max)  NULL,
	[avg_aisle_time_spent] [nvarchar](max)  NULL,
	[avg_dwell_time] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OnlineRetailData]
( 
	[InvoiceNo] [nvarchar](max)  NULL,
	[StockCode] [nvarchar](max)  NULL,
	[Description] [nvarchar](max)  NULL,
	[Quantity] [nvarchar](max)  NULL,
	[InvoiceDate] [nvarchar](max)  NULL,
	[UnitPrice] [nvarchar](max)  NULL,
	[CustomerID] [nvarchar](max)  NULL,
	[City] [nvarchar](max)  NULL,
	[Age] [nvarchar](max)  NULL,
	[AgeGroup] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OperatingExpenses]
( 
	[Class] [nvarchar](max)  NULL,
	[Country] [nvarchar](max)  NULL,
	[Function Summary] [nvarchar](max)  NULL,
	[Line Item] [nvarchar](max)  NULL,
	[P&L Classification] [nvarchar](max)  NULL,
	[VTB (%)] [nvarchar](max)  NULL,
	[Actual ($)] [nvarchar](max)  NULL,
	[Budget ($)] [nvarchar](max)  NULL,
	[VTB ($)] [nvarchar](max)  NULL,
	[YoY ($)] [nvarchar](max)  NULL,
	[Channel] [nvarchar](max)  NULL,
	[Region] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiBalanceSheet]
( 
	[BalanceSheetId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[TotalAssets] [float]  NULL,
	[Revenue] [float]  NULL,
	[Expense] [float]  NULL,
	[ResearchInvestment] [float]  NULL,
	[GovernmentDebt] [float]  NULL,
	[OtherGovernmentSecurities] [float]  NULL,
	[OtherSecurities] [float]  NULL,
	[HighQualityLiquidAsset] [float]  NULL,
	[NetCashFlow] [float]  NULL,
	[MonthNumber] [int]  NULL,
	[Month] [varchar](4000)  NULL,
	[Year] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiBankCustomerRanking]
( 
	[BankCustomerRankingId] [int]  NULL,
	[CustomerId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[NpsScore] [int]  NULL,
	[CSAT] [int]  NULL,
	[DateTime] [datetime]  NULL,
	[MonthNumber] [int]  NULL,
	[Month] [varchar](4000)  NULL,
	[Year] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiBankGlobalRanking]
( 
	[BankGlobalRankingId] [nvarchar](max)  NULL,
	[InstitutionId] [nvarchar](max)  NULL,
	[Country] [nvarchar](max)  NULL,
	[City] [nvarchar](max)  NULL,
	[Domain] [nvarchar](max)  NULL,
	[MsciScore] [nvarchar](max)  NULL,
	[EsgEnvironmentalScore] [nvarchar](max)  NULL,
	[EsgSocialScore] [nvarchar](max)  NULL,
	[EsgGovernanceScore] [nvarchar](max)  NULL,
	[QoQ] [nvarchar](max)  NULL,
	[Awareness] [nvarchar](max)  NULL,
	[MonthNumber] [nvarchar](max)  NULL,
	[Month] [nvarchar](max)  NULL,
	[Year] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiBedOccupancyForecasted]
( 
	[Date] [datetime]  NULL,
	[City] [nvarchar](4000)  NULL,
	[OccupancyRate] [decimal](38,18)  NULL,
	[forecasted] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiCustomer]
( 
	[CustomerId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[FirstName] [varchar](4000)  NULL,
	[LastName] [varchar](4000)  NULL,
	[LatestCreditScore] [int]  NULL,
	[Age] [int]  NULL,
	[AgeGroup] [varchar](4000)  NULL,
	[AccountOpeningTime] [float]  NULL,
	[Tenure] [int]  NULL,
	[IsActive] [bit]  NULL,
	[DateTime] [datetime]  NULL,
	[MonthNumber] [int]  NULL,
	[Month] [varchar](4000)  NULL,
	[Year] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiESG]
( 
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[EnvironmentTalk] [float]  NULL,
	[EnvironmentWalk] [float]  NULL,
	[SocialScoreTalk] [float]  NULL,
	[SocialScoreWalk] [float]  NULL,
	[GovernanceScoreTalk] [float]  NULL,
	[GovernanceScoreWalk] [float]  NULL,
	[MonthNumber] [int]  NULL,
	[Month] [varchar](4000)  NULL,
	[Year] [int]  NULL,
	[MSCIScore] [varchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiEsgArticleSentiment]
( 
	[EsgArticleSentimentId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[ReportedOn] [date]  NULL,
	[ArticleCount] [int]  NULL,
	[AverageSentiment] [decimal](5,2)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiEsgBigram]
( 
	[EsgBigramId] [int]  NULL,
	[InstitutionUnitId] [int]  NULL,
	[RegionId] [int]  NULL,
	[ReportedOn] [date]  NULL,
	[Bigram] [varchar](255)  NULL,
	[BigramCount] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiEsgDetractor]
( 
	[EsgDetractorId] [int]  NULL,
	[InstitutionUnitId] [int]  NULL,
	[ReportedOn] [date]  NULL,
	[EntityName] [varchar](255)  NULL,
	[DetractorIncidentCount] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiEsgInitiativesComparison]
( 
	[EsgInitiativesComparisonId] [int]  NULL,
	[InstitutionUnitId] [int]  NULL,
	[ReportedOn] [date]  NULL,
	[ComparisonWith] [varchar](255)  NULL,
	[Code of Conduct] [float]  NULL,
	[Company Transformation] [float]  NULL,
	[Ethical Investments] [float]  NULL,
	[Focus Customer] [float]  NULL,
	[Green Energy] [float]  NULL,
	[Strong Governance] [float]  NULL,
	[Support Community] [float]  NULL,
	[Sustainable Finance] [float]  NULL,
	[Value Employees] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiEsgInstitutionUnitPolicyScore]
( 
	[EsgInstitutionUnitPolicyScoreId] [int]  NULL,
	[InstitutionUnitId] [int]  NULL,
	[EsgPolicyId] [int]  NULL,
	[ReportedOn] [date]  NULL,
	[TalkScore] [decimal](5,2)  NULL,
	[WalkScore] [decimal](5,2)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiEsgPolicy]
( 
	[EsgPolicyId] [int]  NULL,
	[Segment] [varchar](255)  NULL,
	[PolicyName] [varchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiInstitution]
( 
	[InstitutionId] [int]  NULL,
	[InstitutionName] [varchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiInstitutionUnit]
( 
	[InstitutionUnitId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[InstitutionUnitName] [varchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiKPI]
( 
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[MaxCustomerLifetimeValue] [int]  NULL,
	[MaxCustomerLifetimeValueTarget] [int]  NULL,
	[CustomerServiceResponsetime] [int]  NULL,
	[CustomerServiceResponsetimeTarget] [int]  NULL,
	[CSATRankingwithPeers] [int]  NULL,
	[CSATRankingwithPeersTarget] [int]  NULL,
	[NPSRankingwithPeers] [int]  NULL,
	[NPSRankingwithPeersTarget] [int]  NULL,
	[AccountTakeoverIncidents] [int]  NULL,
	[AccountTakeoverIncidentsTarget] [int]  NULL,
	[InternalSocialEngineeringTestResults] [float]  NULL,
	[InternalSocialEngineeringTestResultsTarget] [float]  NULL,
	[RegulatoryCompliance] [int]  NULL,
	[RegulatoryComplianceTarget] [int]  NULL,
	[FRTB_Status_and_Reporting] [float]  NULL,
	[FRTB_Status_and_Reporting_Target] [float]  NULL,
	[RegulatoryReportingComplianceStatus] [int]  NULL,
	[RegulatoryReportingComplianceStatusTarget] [int]  NULL,
	[FraudulentClaims] [int]  NULL,
	[FraudulentClaimsTarget] [int]  NULL,
	[MonthNumber] [int]  NULL,
	[Date] [datetime]  NULL,
	[Month] [varchar](4000)  NULL,
	[Year] [int]  NULL,
	[ProjectedInvestment] [int]  NULL,
	[DedicatedPortfolio] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PbiReadmissionPrediction]
( 
	[hospital_id] [nvarchar](max)  NULL,
	[department_id] [nvarchar](max)  NULL,
	[city] [nvarchar](max)  NULL,
	[patient_age] [nvarchar](max)  NULL,
	[risk_level] [nvarchar](max)  NULL,
	[acute_type] [nvarchar](max)  NULL,
	[patient_category] [nvarchar](max)  NULL,
	[doctor_id] [nvarchar](max)  NULL,
	[length_of_stay] [nvarchar](max)  NULL,
	[wait_time] [nvarchar](max)  NULL,
	[type_of_stay] [nvarchar](max)  NULL,
	[treatment_cost] [nvarchar](max)  NULL,
	[claim_cost] [nvarchar](max)  NULL,
	[drug_cost] [nvarchar](max)  NULL,
	[hospital_expense] [nvarchar](max)  NULL,
	[follow_up] [nvarchar](max)  NULL,
	[readmitted_patient] [nvarchar](max)  NULL,
	[payment_type] [nvarchar](max)  NULL,
	[date] [datetime]  NULL,
	[month] [nvarchar](max)  NULL,
	[year] [nvarchar](max)  NULL,
	[reason_for_readmission] [nvarchar](max)  NULL,
	[disease] [nvarchar](max)  NULL,
	[Actual_Flag] [nvarchar](max)  NULL,
	[Predicted_Flag] [nvarchar](max)  NULL,
	[Prediction_Probability] [nvarchar](max)  NULL,
	[Actual_Readmission_Rate] [float]  NULL,
	[Predicted_Readmission_Rate] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiRegion]
( 
	[RegionId] [int]  NULL,
	[RegionCode] [varchar](255)  NULL,
	[RegionName] [varchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PbiRetailPrediction]
( 
	[hospital_id] [nvarchar](max)  NULL,
	[department_id] [nvarchar](max)  NULL,
	[city] [nvarchar](max)  NULL,
	[patient_age] [nvarchar](max)  NULL,
	[risk_level] [nvarchar](max)  NULL,
	[acute_type] [nvarchar](max)  NULL,
	[patient_category] [nvarchar](max)  NULL,
	[doctor_id] [nvarchar](max)  NULL,
	[length_of_stay] [nvarchar](max)  NULL,
	[wait_time] [nvarchar](max)  NULL,
	[type_of_stay] [nvarchar](max)  NULL,
	[treatment_cost] [nvarchar](max)  NULL,
	[claim_cost] [nvarchar](max)  NULL,
	[drug_cost] [nvarchar](max)  NULL,
	[hospital_expense] [nvarchar](max)  NULL,
	[follow_up] [nvarchar](max)  NULL,
	[readmitted_patient] [nvarchar](max)  NULL,
	[payment_type] [nvarchar](max)  NULL,
	[date] [datetime]  NULL,
	[month] [nvarchar](max)  NULL,
	[year] [nvarchar](max)  NULL,
	[reason_for_readmission] [nvarchar](max)  NULL,
	[disease] [nvarchar](max)  NULL,
	[Actual_Flag] [nvarchar](max)  NULL,
	[Predicted_Flag] [nvarchar](max)  NULL,
	[Prediction_Probability] [nvarchar](max)  NULL,
	[Actual_Readmission_Rate] [float]  NULL,
	[Predicted_Readmission_Rate] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PbiWaitTimeForecast]
( 
	[date] [datetime]  NULL,
	[wait_time] [decimal](38,18)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pred_anomaly]
( 
	[Date_Time] [datetime2](7)  NULL,
	[PrincipalComponent1] [bigint]  NULL,
	[PrincipalComponent2] [bigint]  NULL,
	[PrincipalComponent3] [bigint]  NULL,
	[Longitude] [decimal](38,18)  NULL,
	[Latitude] [decimal](38,18)  NULL,
	[PatientID] [nvarchar](4000)  NULL,
	[Anomaly Detected ] [nvarchar](4000)  NULL,
	[Scored Probabilities] [decimal](38,18)  NULL,
	[PC1] [decimal](38,18)  NULL,
	[PC2] [decimal](38,18)  NULL,
	[PC3] [decimal](38,18)  NULL,
	[url] [nvarchar](4000)  NULL,
	[Location] [nvarchar](4000)  NULL,
	[Row Num] [nvarchar](4000)  NULL,
	[Probability Goal] [decimal](38,18)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Products]
( 
	[Products_ID] [int]  NULL,
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RealTimeTwitterData]
( 
	[time] [datetime2](7)  NULL,
	[hashtag] [nvarchar](max)  NULL,
	[tweet] [nvarchar](max)  NULL,
	[city] [nvarchar](max)  NULL,
	[username] [nvarchar](max)  NULL,
	[retweetcount] [bigint]  NULL,
	[favouritecount] [bigint]  NULL,
	[sentiment] [nvarchar](max)  NULL,
	[sentimentscore] [bigint]  NULL,
	[isretweet] [bigint]  NULL,
	[hourofday] [nvarchar](max)  NULL,
	[language] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RevenueVsMarketingCost]
( 
	[Date] [datetime]  NULL,
	[Month] [nvarchar](max)  NULL,
	[Year] [nvarchar](max)  NULL,
	[MarketingCost] [nvarchar](max)  NULL,
	[NetSales] [nvarchar](max)  NULL,
	[Revenue] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Role]
( 
	[RoleID] [int]  NULL,
	[Name] [varchar](100)  NULL,
	[Email] [varchar](100)  NULL,
	[Roles] [varchar](128)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Sales]
( 
	[Fiscal Year] [nvarchar](max)  NULL,
	[Fiscal Quarter] [nvarchar](max)  NULL,
	[Fiscal Month] [nvarchar](max)  NULL,
	[Country] [nvarchar](max)  NULL,
	[Region] [nvarchar](max)  NULL,
	[Customer Segment] [nvarchar](max)  NULL,
	[Channel] [nvarchar](max)  NULL,
	[Product] [nvarchar](max)  NULL,
	[Product Category] [nvarchar](max)  NULL,
	[Gross Sales] [float]  NULL,
	[Budget] [float]  NULL,
	[Forecast] [float]  NULL,
	[Discount] [float]  NULL,
	[Net Sales] [float]  NULL,
	[COGS] [float]  NULL,
	[Gross Profit] [float]  NULL,
	[Half Yearly] [nvarchar](max)  NULL,
	[VTB ($)] [float]  NULL,
	[VTB (%)] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
	[Gross Sales] [float]  NULL,
	[Budget] [float]  NULL,
	[Forecast] [float]  NULL,
	[Discount] [float]  NULL,
	[Net Sales] [float]  NULL,
	[COGS] [float]  NULL,
	[Gross Profit] [varchar](5000)  NULL,
	[Half Yearly] [varchar](5000)  NULL,
	[VTB ($)] [float]  NULL,
	[VTB (%)] [float]  NULL,
	[agegroup] [varchar](50)  NULL,
	[Dates] [datetime]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SalesMasters]
( 
	[Fiscal Year] [nvarchar](max)  NULL,
	[Fiscal Quarter] [nvarchar](max)  NULL,
	[Fiscal Month] [nvarchar](max)  NULL,
	[Country] [nvarchar](max)  NULL,
	[Region] [nvarchar](max)  NULL,
	[Customer Segment] [nvarchar](max)  NULL,
	[Channel] [nvarchar](max)  NULL,
	[Product] [nvarchar](max)  NULL,
	[Product Category] [nvarchar](max)  NULL,
	[Gross Sales] [nvarchar](max)  NULL,
	[Budget] [nvarchar](max)  NULL,
	[Forecast] [nvarchar](max)  NULL,
	[Discount] [nvarchar](max)  NULL,
	[Net Sales] [nvarchar](max)  NULL,
	[COGS] [nvarchar](max)  NULL,
	[Gross Profit] [nvarchar](max)  NULL,
	[Half Yearly] [nvarchar](max)  NULL,
	[VTB ($)] [nvarchar](max)  NULL,
	[VTB (%)] [nvarchar](max)  NULL,
	[agegroup] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SalesMasterUpdated]
( 
	[Fiscal Year] [nvarchar](max)  NULL,
	[Fiscal Quarter] [nvarchar](max)  NULL,
	[Fiscal Month] [nvarchar](max)  NULL,
	[Country] [nvarchar](max)  NULL,
	[Region] [nvarchar](max)  NULL,
	[Customer Segment] [nvarchar](max)  NULL,
	[Channel] [nvarchar](max)  NULL,
	[Product] [nvarchar](max)  NULL,
	[Product Category] [nvarchar](max)  NULL,
	[Gross Sales] [nvarchar](max)  NULL,
	[Budget] [nvarchar](max)  NULL,
	[Forecast] [nvarchar](max)  NULL,
	[Discount] [nvarchar](max)  NULL,
	[Net Sales] [nvarchar](max)  NULL,
	[COGS] [nvarchar](max)  NULL,
	[Gross Profit] [nvarchar](max)  NULL,
	[Half Yearly] [nvarchar](max)  NULL,
	[VTB ($)] [nvarchar](max)  NULL,
	[VTB (%)] [nvarchar](max)  NULL,
	[agegroup] [nvarchar](max)  NULL,
	[Dates] [nvarchar](max)  NULL,
	[ProductId] [nvarchar](max)  NULL,
	[Brand] [nvarchar](max)  NULL,
	[CustomerId] [varchar](5)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Salestransaction]
( 
	[Fiscal Year] [nvarchar](max)  NULL,
	[Fiscal Quarter] [nvarchar](max)  NULL,
	[Fiscal Month] [nvarchar](max)  NULL,
	[Country] [nvarchar](max)  NULL,
	[Region] [nvarchar](max)  NULL,
	[Customer Segment] [nvarchar](max)  NULL,
	[Channel] [nvarchar](max)  NULL,
	[Product] [nvarchar](max)  NULL,
	[Product Category] [nvarchar](max)  NULL,
	[Gross Sales] [float]  NULL,
	[Budget] [float]  NULL,
	[Forecast] [float]  NULL,
	[Discount] [float]  NULL,
	[Net Sales] [float]  NULL,
	[COGS] [float]  NULL,
	[Gross Profit] [float]  NULL,
	[Half Yearly] [nvarchar](max)  NULL,
	[VTB ($)] [float]  NULL,
	[VTB (%)] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SortedCampaigns]
( 
	[Campaign_ID] [int]  NULL,
	[Campaign_Name] [varchar](20)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[testtable]
( 
	[Organisation] [nvarchar](256)  NULL,
	[Theme] [nvarchar](256)  NULL,
	[ESG] [float]  NULL,
	[ReportedOn] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[thermostatHistoricalData]
( 
	[EnqueuedTimeUTC] [nvarchar](max)  NULL,
	[StoreId] [nvarchar](max)  NULL,
	[DeviceID] [nvarchar](max)  NULL,
	[BatteryLevel] [nvarchar](max)  NULL,
	[Temp] [nvarchar](max)  NULL,
	[Temp_UoM] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[thermostatHistoricalData2021]
( 
	[DeviceID] [nvarchar](max)  NULL,
	[StoreId] [nvarchar](max)  NULL,
	[EnqueuedTimeUTC] [nvarchar](max)  NULL,
	[BatteryLevel] [nvarchar](max)  NULL,
	[Temp] [nvarchar](max)  NULL,
	[Temp_UoM] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Travel_Entertainment]
( 
	[Completion Date] [nvarchar](max)  NULL,
	[Month] [nvarchar](max)  NULL,
	[Audit Status] [nvarchar](max)  NULL,
	[Country] [nvarchar](max)  NULL,
	[Status Description] [nvarchar](max)  NULL,
	[Region] [nvarchar](max)  NULL,
	[Serious Failed] [nvarchar](max)  NULL,
	[Serious Failed Expenses] [nvarchar](max)  NULL,
	[Function Summary] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TwitterRawData]
( 
	[ID] [int]  NULL,
	[TwitterData] [varchar](5000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[VTBByChannel]
( 
	[Amount] [nvarchar](max)  NULL,
	[VTB ($) by channel] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[vwPbiESGSlicerOrganizations]
( 
	[InstitutionId] [int]  NULL,
	[InstitutionUnitId] [int]  NULL,
	[IsInstitutionUnit] [int]  NULL,
	[DisplayName] [varchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Wait_Time_Forecasted]
( 
	[city] [nvarchar](max)  NULL,
	[date] [nvarchar](max)  NULL,
	[month] [nvarchar](max)  NULL,
	[wait_time] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WebsiteSocialAnalyticsPBIData]
( 
	[Country] [nvarchar](max)  NULL,
	[Product_Category] [nvarchar](max)  NULL,
	[Product] [nvarchar](max)  NULL,
	[Channel] [nvarchar](max)  NULL,
	[Gender] [nvarchar](max)  NULL,
	[Sessions] [nvarchar](max)  NULL,
	[Device_Category] [nvarchar](max)  NULL,
	[Sources] [nvarchar](max)  NULL,
	[Conversations] [nvarchar](max)  NULL,
	[Page] [nvarchar](max)  NULL,
	[Visits] [nvarchar](max)  NULL,
	[Unique_Visitors] [nvarchar](max)  NULL,
	[Browser] [nvarchar](max)  NULL,
	[Sentiment] [nvarchar](max)  NULL,
	[Duration_min] [nvarchar](max)  NULL,
	[Region] [nvarchar](max)  NULL,
	[Customer_Segment] [nvarchar](max)  NULL,
	[Daily_Users] [nvarchar](max)  NULL,
	[Conversion_Rate] [nvarchar](max)  NULL,
	[Return_Visitors] [nvarchar](max)  NULL,
	[Tweets] [nvarchar](max)  NULL,
	[Retweets] [nvarchar](max)  NULL,
	[Hashtags] [nvarchar](max)  NULL,
	[Campaign_Name] [nvarchar](max)  NULL,
	[Date] [datetime]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WWIBrands]
( 
	[BrandID] [int]  NOT NULL,
	[BrandName] [varchar](200)  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [BrandName] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WWIProducts]
( 
	[Products_ID] [int]  NULL,
	[Name] [varchar](100)  NULL,
	[EntityName] [varchar](11)  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
