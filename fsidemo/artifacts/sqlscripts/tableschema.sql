SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADB_AllTransactions]
( 
	[user] [nvarchar](256)  NULL,
	[latitude] [float]  NULL,
	[longitude] [float]  NULL,
	[amount] [float]  NULL,
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

CREATE TABLE [dbo].[ADB_RyanTransactions]
( 
	[user] [nvarchar](256)  NULL,
	[latitude] [float]  NULL,
	[longitude] [float]  NULL,
	[amount] [float]  NULL,
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

CREATE TABLE [dbo].[ADB_SuspiciousTransactionsMiami]
( 
	[user] [nvarchar](256)  NULL,
	[latitude] [float]  NULL,
	[longitude] [float]  NULL,
	[amount] [float]  NULL,
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

CREATE TABLE [dbo].[ADB_SuspiciousTransactionsSantorini]
( 
	[latitude] [float]  NULL,
	[longitude] [float]  NULL,
	[amount] [float]  NULL,
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

CREATE TABLE [dbo].[Campaign_Analytics]
( 
	[Region] [nvarchar](20)  NULL,
	[Country] [nvarchar](20)  NULL,
	[Campaign_Name] [nvarchar](100)  NULL,
	[Revenue] [nvarchar](20)  NULL,
	[Revenue_Target] [nvarchar](20)  NULL,
	[City] [nvarchar](20)  NULL,
	[State] [nvarchar](50)  NULL
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

CREATE TABLE [dbo].[Carbon-Emission]
( 
	[Issuer Name] [nvarchar](max)  NULL,
	[Fiscal Year] [nvarchar](max)  NULL,
	[Carbon emissions - Scope 1+2 revenue intensity (tCO2e/USD million)] [nvarchar](max)  NULL,
	[Carbon emissions - Scope 1+2 (tCO2e)] [nvarchar](max)  NULL,
	[Carbon Emissions - Scope 1+2 KEY] [nvarchar](max)  NULL,
	[Carbon emissions - Scope 1 (tCO2e)] [nvarchar](max)  NULL,
	[Carbon Emissions - Scope 1 KEY] [nvarchar](max)  NULL,
	[Carbon emissions - Scope 2 (tCO2e)] [nvarchar](max)  NULL,
	[Carbon Emissions - Scope 2 KEY] [nvarchar](max)  NULL,
	[Carbon emissions - Scope 3 total reported (tCO2e)] [nvarchar](max)  NULL,
	[Energy consumption (MWh)] [nvarchar](max)  NULL,
	[Energy consumption revenue intensity (MWh/USD million)] [nvarchar](max)  NULL,
	[Renewable energy consumption (MWh)] [nvarchar](max)  NULL,
	[Energy consumption from renewable sources (% of total energy consumption)] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Climate-Risk]
( 
	[Issuer Name] [nvarchar](max)  NULL,
	[Carbon Emissions - Scope 1 Intensity Projection for 2030 -tCO2e/USD million sales] [nvarchar](max)  NULL,
	[Carbon Emissions - Scope 2 Intensity Projection for 2030 -tCO2e/USD million sales] [nvarchar](max)  NULL,
	[Carbon Emissions - Scope 3 Intensity Projection for 2030 -tCO2e/USD million sales] [nvarchar](max)  NULL,
	[Aggregated Company 1.5 Degree Climate VaR] [nvarchar](max)  NULL,
	[Aggregated Company 2 Degree Climate VaR ] [nvarchar](max)  NULL,
	[Aggregated Company 3 Degree Climate VaR] [nvarchar](max)  NULL,
	[Aggregated Warming Potential-Degree C] [nvarchar](max)  NULL,
	[Aggregated Warming Potential-degree C-without Company targets] [nvarchar](max)  NULL,
	[Market Capitalization - Valuation Date] [nvarchar](max)  NULL,
	[Revenue - Valuation Date] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Countrys]
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CroGlobalMarkets]
( 
	[CroGlobalMarketsId] [int]  NULL,
	[InstitutionUnitId] [int]  NULL,
	[ReportedOn] [datetime]  NULL,
	[FrtbStatus] [varchar](20)  NULL,
	[TradingExposure] [decimal](10,2)  NULL,
	[MarketSurvelliance] [decimal](3,2)  NULL,
	[EsgAssets] [decimal](10,2)  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [InstitutionUnitId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CroInsurance]
( 
	[CroInsuranceId] [int]  NULL,
	[InstitutionUnitId] [int]  NULL,
	[ReportedOn] [datetime]  NULL,
	[RegulatoryReportingCompliance] [decimal](10,2)  NULL,
	[ClaimProcessingCycleTime] [int]  NULL,
	[FradulentClaimsValue] [decimal](10,2)  NULL,
	[UnderwritingEfficiency] [decimal](3,2)  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CroInsuranceId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CroMacroeconomicTrend]
( 
	[CroRiskDashboardId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[RegionId] [int]  NULL,
	[ReportedOn] [datetime]  NULL,
	[Projection] [decimal](10,2)  NULL,
	[UpsideScenario] [decimal](10,2)  NULL,
	[DownsideScenario] [decimal](10,2)  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CroRiskDashboardId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CroRetailBank]
( 
	[CroRetailBankId] [int]  NULL,
	[InstitutionUnitId] [int]  NULL,
	[ReportedOn] [datetime]  NULL,
	[MarketRisk] [varchar](20)  NULL,
	[CreditRiskExposure] [decimal](10,2)  NULL,
	[RegulatoryCompliance] [decimal](10,2)  NULL,
	[FinancialCrimeLoss] [decimal](10,2)  NULL,
	[LoanPortfolioPerformance] [decimal](10,2)  NULL,
	[IcappStatus] [decimal](10,2)  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [InstitutionUnitId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CroRiskDashboard]
( 
	[CroRiskDashboardId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[ReportedOn] [datetime]  NULL,
	[OverallComplianceRiskValue] [decimal](3,2)  NULL,
	[OverallComplianceRiskIndicator] [varchar](20)  NULL,
	[OverallCreditRiskValue] [decimal](3,2)  NULL,
	[OverallCreditRiskIndicator] [varchar](20)  NULL,
	[OverallOperationalRiskValue] [decimal](3,2)  NULL,
	[OverallOperationalRiskIndicator] [varchar](20)  NULL,
	[IncidentsCount] [int]  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [InstitutionId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerInfo]
( 
	[UserName] [nvarchar](max)  NULL,
	[Gender] [nvarchar](max)  NULL,
	[Phone] [nvarchar](max)  NULL,
	[Email] [nvarchar](max)  NULL,
	[CreditCard] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[CustomerTransactions]
( 
	[CustomerTransactionID] [nvarchar](max)  NULL,
	[CustomerID] [nvarchar](max)  NULL,
	[TransactionTypeID] [nvarchar](max)  NULL,
	[InvoiceID] [nvarchar](max)  NULL,
	[PaymentMethodID] [nvarchar](max)  NULL,
	[TransactionDate] [nvarchar](max)  NULL,
	[LastEditedBy] [nvarchar](max)  NULL,
	[LastEditedWhen] [nvarchar](max)  NULL,
	[AmountExcludingTax] [nvarchar](max)  NULL,
	[TaxAmount] [nvarchar](max)  NULL,
	[TransactionAmount] [nvarchar](max)  NULL,
	[OutstandingBalance] [nvarchar](max)  NULL,
	[FinalizationDate] [nvarchar](max)  NULL,
	[IsFinalized] [nvarchar](max)  NULL
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
	[Portfolio] [nvarchar](max)  NULL,
	[Sector] [nvarchar](max)  NULL,
	[Cik] [nvarchar](max)  NULL,
	[Date] [nvarchar](max)  NULL,
	[Ticker] [nvarchar](max)  NULL,
	[AdjClose] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[DailyStockDataLatest]
( 
	[Prop_0] [nvarchar](max)  NULL,
	[Prop_1] [nvarchar](max)  NULL,
	[Prop_2] [nvarchar](max)  NULL,
	[Prop_3] [nvarchar](max)  NULL,
	[Prop_4] [nvarchar](max)  NULL,
	[Prop_5] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[EnvMgmtPractices]
( 
	[Issuer Name] [nvarchar](200)  NULL,
	[Executive body responsible] [nvarchar](2000)  NULL,
	[Scope of management] [nvarchar](2000)  NULL,
	[Formal management] [nvarchar](2000)  NULL,
	[Oversight of ESG risk management] [nvarchar](2000)  NULL,
	[Conducts climate-related risk analysis] [nvarchar](2000)  NULL,
	[Evidence of board-level engagement on climate-related risks] [nvarchar](2000)  NULL,
	[Sustainability related product development] [nvarchar](2000)  NULL,
	[Involvement in green bonds] [nvarchar](2000)  NULL,
	[Involvement of group credit risk in ESG due diligence] [nvarchar](2000)  NULL
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

CREATE TABLE [dbo].[Finance-FactSales]
( 
	[Designation] [nvarchar](50)  NULL,
	[PayerName] [nvarchar](50)  NULL,
	[CampaignName] [nvarchar](50)  NULL,
	[Region] [nvarchar](50)  NULL,
	[State] [nvarchar](20)  NULL,
	[City] [nvarchar](20)  NULL,
	[Revenue] [nvarchar](10)  NULL,
	[RevenueTarget] [nvarchar](10)  NULL
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

CREATE TABLE [dbo].[FPA1]
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

CREATE TABLE [dbo].[HistoricalNewsAndSentiment]
( 
	[Symbol] [varchar](50)  NULL,
	[Name] [varchar](50)  NULL,
	[Url] [varchar](50)  NULL,
	[Date_Published] [datetime]  NULL,
	[Description] [varchar](100)  NULL,
	[Sentiment] [varchar](50)  NULL,
	[Positive_Score] [float]  NULL,
	[Negative_Score] [float]  NULL,
	[Neutral_Score] [float]  NULL
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

CREATE TABLE [dbo].[HistoricalStock]
( 
	[Portfolio] [varchar](80)  NULL,
	[Sector] [varchar](80)  NULL,
	[Cik] [varchar](80)  NULL,
	[Date] [date]  NULL,
	[Ticker] [varchar](80)  NULL,
	[AdjClose] [numeric](18,0)  NULL
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

CREATE TABLE [dbo].[HofAntiMoneyLaundering]
( 
	[HofAntiMoneyLaunderingId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[ReportedOn] [datetime]  NULL,
	[SarCount] [int]  NULL,
	[FalsePositiveRate] [decimal](3,2)  NULL,
	[DownsideScenario] [decimal](10,2)  NULL,
	[InvestigationResponseTime] [int]  NULL,
	[BsaOfacReportingStatus] [varchar](20)  NULL,
	[DetectionEfficiency] [decimal](3,2)  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [InstitutionId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[HofCyberSecurity]
( 
	[HofSanctionsScreeningId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[ReportedOn] [datetime]  NULL,
	[AccountTakeoverIncidents] [int]  NULL,
	[ActiveVulnerabilities] [int]  NULL,
	[InvestigationResponseTime] [int]  NULL,
	[PatchManagementCompletion] [decimal](3,2)  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [InstitutionId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[HofSanctionsScreening]
( 
	[HofSanctionsScreeningId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[ReportedOn] [datetime]  NULL,
	[SarCount] [int]  NULL,
	[ScreeningEfficiency] [decimal](3,2)  NULL,
	[FalseHits] [int]  NULL,
	[FincenCompliance] [decimal](3,2)  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [InstitutionId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Institution]
( 
	[InstitutionId] [int]  NULL,
	[InstitutionName] [varchar](20)  NULL
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

CREATE TABLE [dbo].[InstitutionUnit]
( 
	[InstitutionUnitId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[InstitutionUnitName] [varchar](200)  NULL
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

CREATE TABLE [dbo].[NewsAndSentimentNew]
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

CREATE TABLE [dbo].[OFACSyanapseLinkData]
( 
	[TransactionID] [int]  NULL,
	[TransactionType] [nvarchar](100)  NULL,
	[TransactionAmount] [nvarchar](200)  NULL,
	[TransactionDate] [datetime]  NULL,
	[OFAC Eval Time] [datetime]  NULL,
	[OFAC Avail] [datetime]  NULL,
	[AvgOFACTime] [int]  NULL,
	[States] [nvarchar](50)  NULL,
	[IsFraud] [int]  NULL,
	[IsFraudFlagged] [int]  NULL
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

CREATE TABLE [dbo].[OFACSyanapseLinkData1]
( 
	[TransactionID] [int]  NULL,
	[TransactionAmount] [nvarchar](200)  NULL,
	[TransactionDate] [datetime]  NULL,
	[OFAC Eval Completion] [datetime]  NULL,
	[OFAC Eval Avalilability] [datetime]  NULL,
	[AvgOFACTime] [int]  NULL,
	[States] [nvarchar](50)  NULL,
	[IsFraud] [nvarchar](5)  NULL,
	[IsFraudFlagged] [nvarchar](5)  NULL
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

CREATE TABLE [dbo].[OFACSyanapseLinkData2]
( 
	[TransactionID] [int]  NULL,
	[TransactionType] [nvarchar](100)  NULL,
	[TransactionAmount] [nvarchar](200)  NULL,
	[TransactionDate] [datetime]  NULL,
	[OFAC Eval Time] [datetime]  NULL,
	[OFAC Avail] [datetime]  NULL,
	[AvgOFACTime] [int]  NULL,
	[States] [nvarchar](50)  NULL,
	[IsFraud] [int]  NULL,
	[IsFraudFlagged] [int]  NULL
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

CREATE TABLE [dbo].[OFACTType]
( 
	[ID] [int]  NULL,
	[NAME] [varchar](50)  NULL
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
	[BankGlobalRankingId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[MsciScore] [varchar](4000)  NULL,
	[CSR] [float]  NULL,
	[RegulationQuality] [decimal](18,0)  NULL,
	[EsgEnvironmentalScore] [decimal](18,0)  NULL,
	[EsgSocialScore] [decimal](18,0)  NULL,
	[EsgGovernanceScore] [decimal](18,0)  NULL,
	[QoQ] [int]  NULL,
	[Awareness] [int]  NULL,
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

CREATE TABLE [dbo].[pbiBedOccupancyForecasted]
( 
	[Date] [nvarchar](4000)  NULL,
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

CREATE TABLE [dbo].[pbiComplianceReport]
( 
	[ComplianceReportId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[Category] [varchar](4000)  NULL,
	[FactorName] [varchar](4000)  NULL,
	[FactorScore] [int]  NULL,
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

CREATE TABLE [dbo].[pbiCustomerInsurance]
( 
	[ProductId] [int]  NULL,
	[CustomerId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[ExpenseRatio] [float]  NULL,
	[LossReserves] [float]  NULL,
	[ClaimAmount] [int]  NULL,
	[Efficiency] [float]  NULL,
	[MonthSequence] [int]  NULL,
	[MonthNumber] [int]  NULL,
	[Month] [varchar](4000)  NULL,
	[Year] [int]  NULL,
	[TargetExpenseRatio] [int]  NULL
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

CREATE TABLE [dbo].[pbiCustomerTransactions]
( 
	[CustomerTransactionsId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[CustomerId] [int]  NULL,
	[TransactionAmount] [int]  NULL,
	[CtrFlag] [bit]  NULL,
	[SarFlag] [bit]  NULL,
	[FalseFlag] [bit]  NULL,
	[Description] [varchar](4000)  NULL,
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

CREATE TABLE [dbo].[pbiEmployee]
( 
	[EmployeeId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[FirstName] [varchar](4000)  NULL,
	[LastName] [varchar](4000)  NULL,
	[Age] [int]  NULL,
	[JoinedDate] [datetime]  NULL,
	[LastWorkingDate] [datetime]  NULL,
	[EmployeeSatisfactionScore] [int]  NULL
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

CREATE TABLE [dbo].[pbiGlobalMarketPerformance]
( 
	[GlobalMarketPerformanceId] [int]  NULL,
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[Revenue] [int]  NULL,
	[SnP] [float]  NULL,
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

CREATE TABLE [dbo].[pbiGlobalRisk]
( 
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[MarketSurveillance] [int]  NULL,
	[ESGAssets] [float]  NULL,
	[Incidents] [int]  NULL,
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

CREATE TABLE [dbo].[pbiInstitutionDetails]
( 
	[InstitutionId] [int]  NULL,
	[City] [varchar](4000)  NULL,
	[Country] [varchar](4000)  NULL,
	[Region] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL
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

CREATE TABLE [dbo].[pbiInsuranceRisk]
( 
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[UnderwritingEfficiency] [int]  NULL,
	[ClaimsProcessingTime] [int]  NULL,
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
	[date] [nvarchar](max)  NULL,
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

CREATE TABLE [dbo].[pbiRetailBankRisk]
( 
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[PortfolioPerformance] [int]  NULL,
	[ICAAPStatus] [int]  NULL,
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

CREATE TABLE [dbo].[pbiROE]
( 
	[Date] [nvarchar](max)  NULL,
	[InstitutionId] [nvarchar](max)  NULL,
	[RetailBankKpiRoeId] [nvarchar](max)  NULL,
	[ROE] [float]  NULL,
	[TargetROE] [float]  NULL
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

CREATE TABLE [dbo].[pbiVulnerabilities]
( 
	[InstitutionId] [int]  NULL,
	[Country] [varchar](4000)  NULL,
	[City] [varchar](4000)  NULL,
	[Domain] [varchar](4000)  NULL,
	[Efficiency] [int]  NULL,
	[InvestigationResponseTime] [int]  NULL,
	[Vulnerabilities] [int]  NULL,
	[Description] [varchar](4000)  NULL,
	[DateTime] [datetime]  NULL,
	[MonthNumber] [int]  NULL,
	[Month] [varchar](4000)  NULL,
	[Year] [int]  NULL,
	[ClientOnboardingEfficiency] [int]  NULL
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

CREATE TABLE [dbo].[PbiWaitTimeForecast]
( 
	[date] [nvarchar](4000)  NULL,
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

CREATE TABLE [dbo].[Portfolio]
( 
	[Portfolio] [varchar](80)  NULL,
	[Sector] [varchar](30)  NULL,
	[Ticker] [varchar](30)  NULL,
	[CreatedDate] [bigint]  NULL,
	[CIK] [bigint]  NULL
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

CREATE TABLE [dbo].[Region]
( 
	[RegionId] [int]  NULL,
	[RegionCode] [varchar](20)  NULL,
	[RegionName] [varchar](50)  NULL
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
	[Gross Sales] [nvarchar](max)  NULL,
	[Budget] [nvarchar](max)  NULL,
	[Forecast] [nvarchar](max)  NULL,
	[Discount] [nvarchar](max)  NULL,
	[Net Sales] [nvarchar](max)  NULL,
	[COGS] [nvarchar](max)  NULL,
	[Gross Profit] [nvarchar](max)  NULL,
	[Half Yearly] [nvarchar](max)  NULL,
	[VTB ($)] [nvarchar](max)  NULL,
	[VTB (%)] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[States]
( 
	[id] [int]  NULL,
	[Statesname] [varchar](100)  NULL,
	[CountryID] [char](1)  NULL
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

CREATE TABLE [dbo].[Stockprice]
( 
	[Stockticker] [nvarchar](max)  NULL,
	[Date] [nvarchar](max)  NULL,
	[Open] [nvarchar](max)  NULL,
	[high] [nvarchar](max)  NULL,
	[low] [nvarchar](max)  NULL,
	[Close] [nvarchar](max)  NULL,
	[AdjClose] [nvarchar](max)  NULL,
	[Volume] [nvarchar](max)  NULL,
	[LastYear] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[TEST3]
( 
	[TransactionID] [int]  NULL,
	[TransactionType] [nvarchar](100)  NULL,
	[TransactionAmount] [nvarchar](200)  NULL,
	[TransactionDate] [datetime]  NULL,
	[OFAC Eval Time] [datetime]  NULL,
	[OFAC Avail] [datetime]  NULL,
	[AvgOFACTime] [int]  NULL,
	[States] [nvarchar](50)  NULL,
	[IsFraud] [nvarchar](5)  NULL,
	[IsFraudFlagged] [nvarchar](5)  NULL
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

CREATE TABLE [dbo].[AccountHeads]
( 
	[Id] [bigint]  NOT NULL,
	[Code] [nvarchar](3)  NOT NULL,
	[Name] [nvarchar](50)  NOT NULL,
	[ParentGroupId] [bigint]  NULL,
	[IsCreditAcc] [int]  NOT NULL
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

CREATE TABLE [dbo].[ApplicationCollateral]
( 
	[Name] [varchar](100)  NULL,
	[Owner (Lookup)] [varchar](50)  NULL,
	[Status] [varchar](20)  NULL,
	[Type] [varchar](30)  NULL,
	[Financial Holding ID (Lookup)] [varchar](50)  NULL,
	[Loan Application (Lookup)] [varchar](50)  NULL,
	[Property Holding ID (Lookup)] [varchar](10)  NULL,
	[Created By (Lookup)] [varchar](30)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [bigint]  NULL,
	[Modified By (Lookup)] [varchar](50)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](50)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](50)  NULL,
	[Owning Team (Lookup)] [varchar](50)  NULL,
	[Record Created On] [datetime]  NULL,
	[Status Reason] [varchar](15)  NULL,
	[Time Zone Rule Version Number] [int]  NULL,
	[UTC Conversion Time Zone Code] [varchar](10)  NULL,
	[Version Number] [bigint]  NULL,
	[Application Collaterals] [varchar](200)  NULL,
	[Created By] [varchar](150)  NULL,
	[Created By (Delegate)] [varchar](150)  NULL,
	[Financial Holding ID] [varchar](150)  NULL,
	[Loan Application] [varchar](150)  NULL,
	[Modified By] [varchar](150)  NULL,
	[Modified By (Delegate)] [varchar](150)  NULL,
	[Owner] [varchar](150)  NULL,
	[Owning Business Unit] [varchar](150)  NULL,
	[Owning Team] [varchar](150)  NULL,
	[Property Holding ID] [varchar](150)  NULL
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

CREATE TABLE [dbo].[Bank]
( 
	[Name] [varchar](50)  NULL,
	[Owner (Lookup)] [varchar](50)  NULL,
	[Status] [varchar](20)  NULL,
	[Address Line 1] [varchar](200)  NULL,
	[Address Line 2] [varchar](200)  NULL,
	[Address Line 3] [varchar](200)  NULL,
	[Bank Code] [int]  NULL,
	[Bank Name] [varchar](50)  NULL,
	[City] [varchar](50)  NULL,
	[Country/Region] [varchar](50)  NULL,
	[State/Province] [varchar](50)  NULL,
	[Telelphone No.] [varchar](50)  NULL,
	[ZIP/Postal Code] [int]  NULL,
	[Created By (Lookup)] [varchar](20)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](20)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [int]  NULL,
	[Modified By (Lookup)] [varchar](20)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](20)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](100)  NULL,
	[Owning Team (Lookup)] [varchar](100)  NULL,
	[Record Created On] [datetime]  NULL,
	[Status Reason] [varchar](50)  NULL,
	[Time Zone Rule Version Number] [varchar](30)  NULL,
	[UTC Conversion Time Zone Code] [varchar](30)  NULL,
	[Version Number] [int]  NULL,
	[Bank] [varchar](100)  NULL,
	[Created By] [varchar](50)  NULL,
	[Created By (Delegate)] [varchar](50)  NULL,
	[Modified By] [varchar](50)  NULL,
	[Modified By (Delegate)] [varchar](100)  NULL,
	[Owner] [varchar](100)  NULL,
	[Owning Business Unit] [varchar](100)  NULL,
	[Owning Team] [varchar](100)  NULL
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

CREATE TABLE [dbo].[Branches]
( 
	[Name] [varchar](50)  NULL,
	[Owner (Lookup)] [varchar](30)  NULL,
	[Status] [varchar](10)  NULL,
	[Address Line 1] [varchar](200)  NULL,
	[Address Line 2] [varchar](200)  NULL,
	[Address Line 3] [varchar](200)  NULL,
	[Bank (Lookup)] [varchar](15)  NULL,
	[Branch Code] [int]  NULL,
	[Branch Manager (Lookup)] [varchar](20)  NULL,
	[Branch Name] [varchar](100)  NULL,
	[Country/Region] [varchar](100)  NULL,
	[State/Province] [varchar](30)  NULL,
	[Telephone No.] [varchar](30)  NULL,
	[ZIP/Postal Code] [int]  NULL,
	[Created By (Lookup)] [varchar](20)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](20)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [varchar](20)  NULL,
	[Modified By (Lookup)] [varchar](20)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](20)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](100)  NULL,
	[Owning Team (Lookup)] [varchar](100)  NULL,
	[Record Created On] [datetime]  NULL,
	[Status Reason] [varchar](10)  NULL,
	[Time Zone Rule Version Number] [varchar](100)  NULL,
	[UTC Conversion Time Zone Code] [varchar](100)  NULL,
	[Version Number] [bigint]  NULL,
	[Branch] [varchar](200)  NULL,
	[Bank] [varchar](150)  NULL,
	[Branch Manager] [varchar](100)  NULL,
	[Created By] [varchar](100)  NULL,
	[Created By (Delegate)] [varchar](100)  NULL,
	[Modified By] [varchar](100)  NULL,
	[Modified By (Delegate)] [varchar](100)  NULL,
	[Owner] [varchar](100)  NULL,
	[Owning Business Unit] [varchar](100)  NULL,
	[Owning Team] [varchar](100)  NULL
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

CREATE TABLE [dbo].[Categorytypesrelation]
( 
	[Name] [nvarchar](10)  NULL,
	[Life Moment Type Configurations (Lookup)] [varchar](20)  NULL,
	[LifeMomentCategoryConfigurations (Lookup)] [varchar](20)  NULL,
	[Owner (Lookup)] [varchar](20)  NULL,
	[Status] [varchar](10)  NULL,
	[Created By (Lookup)] [varchar](30)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](30)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [int]  NULL,
	[Modified By (Lookup)] [varchar](30)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](30)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](100)  NULL,
	[Owning Team (Lookup)] [varchar](100)  NULL,
	[Record Created On] [datetime]  NULL,
	[Status Reason] [varchar](20)  NULL,
	[Time Zone Rule Version Number] [varchar](10)  NULL,
	[UTC Conversion Time Zone Code] [varchar](10)  NULL,
	[Version Number] [bigint]  NULL,
	[Category Types Relations] [varchar](150)  NULL,
	[Created By] [varchar](150)  NULL,
	[Created By (Delegate)] [varchar](30)  NULL,
	[Life Moment Type Configurations] [varchar](150)  NULL,
	[LifeMomentCategoryConfigurations] [varchar](150)  NULL,
	[Modified By] [varchar](150)  NULL,
	[Modified By (Delegate)] [varchar](100)  NULL,
	[Owner] [varchar](100)  NULL,
	[Owning Business Unit] [varchar](100)  NULL,
	[Owning Team] [varchar](100)  NULL
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

CREATE TABLE [dbo].[Churnlevelconfig]
( 
	[Name] [varchar](50)  NULL,
	[Owner (Lookup)] [varchar](20)  NULL,
	[Status] [varchar](10)  NULL,
	[Value %] [int]  NULL,
	[Created By (Lookup)] [varchar](30)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](30)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [int]  NULL,
	[Modified By (Lookup)] [varchar](30)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [int]  NULL,
	[Owning Team (Lookup)] [int]  NULL,
	[Record Created On] [datetime]  NULL,
	[Status Reason] [varchar](10)  NULL,
	[Time Zone Rule Version Number] [varchar](10)  NULL,
	[UTC Conversion Time Zone Code] [varchar](10)  NULL,
	[Version Number] [bigint]  NULL,
	[Churn Levels Config] [varchar](100)  NULL,
	[Created By] [varchar](100)  NULL,
	[Created By (Delegate)] [varchar](100)  NULL,
	[Modified By] [varchar](100)  NULL,
	[Modified By (Delegate)] [varchar](100)  NULL,
	[Owner] [varchar](100)  NULL,
	[Owning Business Unit] [varchar](100)  NULL,
	[Owning Team] [varchar](100)  NULL
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

CREATE TABLE [dbo].[CreditCheck]
( 
	[Name] [nvarchar](max)  NULL,
	[Owner (Lookup)] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[Has Bankrupted] [nvarchar](max)  NULL,
	[Has Defaulted] [nvarchar](max)  NULL,
	[Has Missed Payments] [nvarchar](max)  NULL,
	[Last Bankrupt Date] [nvarchar](max)  NULL,
	[Last Credit Check Assessment] [nvarchar](max)  NULL,
	[Last Default Date] [nvarchar](max)  NULL,
	[Last Missed Payment] [nvarchar](max)  NULL,
	[Score] [nvarchar](max)  NULL,
	[Status2] [nvarchar](max)  NULL,
	[Created By (Lookup)] [nvarchar](max)  NULL,
	[Created By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Created On] [nvarchar](max)  NULL,
	[Import Sequence Number] [nvarchar](max)  NULL,
	[Modified By (Lookup)] [nvarchar](max)  NULL,
	[Modified By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Modified On] [nvarchar](max)  NULL,
	[Owning Business Unit (Lookup)] [nvarchar](max)  NULL,
	[Owning Team (Lookup)] [nvarchar](max)  NULL,
	[Record Created On] [nvarchar](max)  NULL,
	[Status Reason] [nvarchar](max)  NULL,
	[Time Zone Rule Version Number] [nvarchar](max)  NULL,
	[UTC Conversion Time Zone Code] [nvarchar](max)  NULL,
	[Version Number] [nvarchar](max)  NULL,
	[Credit Check] [nvarchar](max)  NULL,
	[Created By] [nvarchar](max)  NULL,
	[Created By (Delegate)] [nvarchar](max)  NULL,
	[Modified By] [nvarchar](max)  NULL,
	[Modified By (Delegate)] [nvarchar](max)  NULL,
	[Owner] [nvarchar](max)  NULL,
	[Owning Business Unit] [nvarchar](max)  NULL,
	[Owning Team] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[ExternalFinancialInstitute]
( 
	[Name] [nvarchar](max)  NULL,
	[Institute  Name] [nvarchar](max)  NULL,
	[Owner (Lookup)] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[Address Line 1] [nvarchar](max)  NULL,
	[Address Line 2] [nvarchar](max)  NULL,
	[Address Line 3] [nvarchar](max)  NULL,
	[City] [nvarchar](max)  NULL,
	[Country/Region] [nvarchar](max)  NULL,
	[State/Province] [nvarchar](max)  NULL,
	[ZIP/Postal Code] [nvarchar](max)  NULL,
	[Created By (Lookup)] [nvarchar](max)  NULL,
	[Created By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Created On] [nvarchar](max)  NULL,
	[Import Sequence Number] [nvarchar](max)  NULL,
	[Modified By (Lookup)] [nvarchar](max)  NULL,
	[Modified By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Modified On] [nvarchar](max)  NULL,
	[Owning Business Unit (Lookup)] [nvarchar](max)  NULL,
	[Owning Team (Lookup)] [nvarchar](max)  NULL,
	[Record Created On] [nvarchar](max)  NULL,
	[Status Reason] [nvarchar](max)  NULL,
	[Time Zone Rule Version Number] [nvarchar](max)  NULL,
	[UTC Conversion Time Zone Code] [nvarchar](max)  NULL,
	[Version Number] [nvarchar](max)  NULL,
	[External Financial Institute] [nvarchar](max)  NULL,
	[Created By] [nvarchar](max)  NULL,
	[Created By (Delegate)] [nvarchar](max)  NULL,
	[Modified By] [nvarchar](max)  NULL,
	[Modified By (Delegate)] [nvarchar](max)  NULL,
	[Owner] [nvarchar](max)  NULL,
	[Owning Business Unit] [nvarchar](max)  NULL,
	[Owning Team] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Financialholdinginstrument]
( 
	[Name] [nvarchar](max)  NULL,
	[FinancialHolding1] [nvarchar](max)  NULL,
	[Financialinstrumenttype] [nvarchar](max)  NULL,
	[Owner3] [nvarchar](max)  NULL,
	[Status4] [nvarchar](max)  NULL,
	[ActivationDate] [nvarchar](max)  NULL,
	[Amount] [int]  NULL,
	[CardNetwork] [nvarchar](max)  NULL,
	[Cardnumber] [nvarchar](max)  NULL,
	[CardType] [nvarchar](max)  NULL,
	[Creditoraccount] [int]  NULL,
	[Creditoridentifier] [nvarchar](max)  NULL,
	[Creditorname] [nvarchar](max)  NULL,
	[Dateoflastcashwithdrawal] [nvarchar](max)  NULL,
	[Dateoflasttransaction] [nvarchar](max)  NULL,
	[Dayofmonth] [nvarchar](max)  NULL,
	[Dayofweek] [nvarchar](max)  NULL,
	[Debtoraccount] [int]  NULL,
	[EmbossingName] [nvarchar](max)  NULL,
	[ExpiryDate] [nvarchar](max)  NULL,
	[Firstpaymentdate] [nvarchar](max)  NULL,
	[Frequency] [nvarchar](max)  NULL,
	[IssueDate] [nvarchar](max)  NULL,
	[Lastitemamount23] [nvarchar](max)  NULL,
	[Lastitemamount24] [nvarchar](max)  NULL,
	[Lastitemdate] [nvarchar](max)  NULL,
	[Lastitemstatus] [nvarchar](max)  NULL,
	[Lastitemstatusreason] [nvarchar](max)  NULL,
	[Mandateenddate] [nvarchar](max)  NULL,
	[Mandateid] [nvarchar](max)  NULL,
	[Mandatelimit30] [nvarchar](max)  NULL,
	[Mandatelimit31] [nvarchar](max)  NULL,
	[Mandatestartdate] [nvarchar](max)  NULL,
	[Nextitemamount33] [nvarchar](max)  NULL,
	[Nextitemamount34] [nvarchar](max)  NULL,
	[Nextitemdate] [nvarchar](max)  NULL,
	[Numberofcashwithdrawals] [int]  NULL,
	[Numberoftransactions] [int]  NULL,
	[Orderenddate] [nvarchar](max)  NULL,
	[OverdraftLimit39] [int]  NULL,
	[OverdraftLimit40] [int]  NULL,
	[OverdraftLimitUsed41] [int]  NULL,
	[OverdraftLimitUsed42] [int]  NULL,
	[OverdraftRate] [int]  NULL,
	[ProductName] [nvarchar](max)  NULL,
	[PurchasingLimit45] [int]  NULL,
	[PurchasingLimit46] [int]  NULL,
	[Status47] [nvarchar](max)  NULL,
	[WithdrawalLimit48] [int]  NULL,
	[WithdrawalLimit49] [int]  NULL,
	[CreatedBy50] [nvarchar](max)  NULL,
	[CreatedBy51] [nvarchar](max)  NULL,
	[CreatedOn] [date]  NULL,
	[Currency53] [nvarchar](max)  NULL,
	[ExchangeRate] [int]  NULL,
	[ImportSequenceNumber] [nvarchar](max)  NULL,
	[ModifiedBy56] [nvarchar](max)  NULL,
	[ModifiedBy57] [nvarchar](max)  NULL,
	[ModifiedOn] [nvarchar](max)  NULL,
	[OwningBusinessUnit59] [nvarchar](max)  NULL,
	[OwningTeam60] [nvarchar](max)  NULL,
	[RecordCreatedOn] [nvarchar](max)  NULL,
	[StatusReason] [nvarchar](max)  NULL,
	[TimeZoneRuleVersionNumber] [nvarchar](max)  NULL,
	[UTCConversionTimeZoneCode] [nvarchar](max)  NULL,
	[VersionNumber] [nvarchar](max)  NULL,
	[Financialinstrument] [nvarchar](max)  NULL,
	[CreatedBy67] [nvarchar](max)  NULL,
	[CreatedBy68] [nvarchar](max)  NULL,
	[Currency69] [nvarchar](max)  NULL,
	[FinancialHolding70] [nvarchar](max)  NULL,
	[ModifiedBy71] [nvarchar](max)  NULL,
	[ModifiedBy72] [nvarchar](max)  NULL,
	[Owner73] [nvarchar](max)  NULL,
	[OwningBusinessUnit74] [nvarchar](max)  NULL,
	[OwningTeam75] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[FinYears]
( 
	[Id] [bigint]  NOT NULL,
	[Name] [nvarchar](50)  NULL,
	[FromDate] [datetime]  NOT NULL,
	[ToDate] [datetime]  NOT NULL
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

CREATE TABLE [dbo].[FORMAT]
( 
	[DATES] [datetime]  NULL
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

CREATE TABLE [dbo].[FORMAT2]
( 
	[ID] [money]  NULL
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

CREATE TABLE [dbo].[Ledgers]
( 
	[Id] [bigint]  NOT NULL,
	[DrAmount] [decimal](18,2)  NOT NULL,
	[CrAmount] [decimal](18,2)  NOT NULL,
	[AccountId] [bigint]  NOT NULL,
	[DateTime] [datetime]  NOT NULL,
	[SourceId] [bigint]  NULL,
	[FinYearId] [bigint]  NOT NULL,
	[AccountHeadId] [bigint]  NOT NULL
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

CREATE TABLE [dbo].[kyc]
( 
	[Name] [nvarchar](max)  NULL,
	[Owner (Lookup)] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[Status2] [nvarchar](max)  NULL,
	[Is Match] [nvarchar](max)  NULL,
	[Last KYC Check] [nvarchar](max)  NULL,
	[Previous First Name] [nvarchar](max)  NULL,
	[Previous Last Name] [nvarchar](max)  NULL,
	[Previous Middle Name] [nvarchar](max)  NULL,
	[Score] [nvarchar](max)  NULL,
	[Source] [nvarchar](max)  NULL,
	[Created By (Lookup)] [nvarchar](max)  NULL,
	[Created By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Created On] [nvarchar](max)  NULL,
	[Import Sequence Number] [nvarchar](max)  NULL,
	[Modified By (Lookup)] [nvarchar](max)  NULL,
	[Modified By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Modified On] [nvarchar](max)  NULL,
	[Owning Business Unit (Lookup)] [nvarchar](max)  NULL,
	[Owning Team (Lookup)] [nvarchar](max)  NULL,
	[Record Created On] [nvarchar](max)  NULL,
	[Status Reason] [nvarchar](max)  NULL,
	[Time Zone Rule Version Number] [nvarchar](max)  NULL,
	[UTC Conversion Time Zone Code] [nvarchar](max)  NULL,
	[Version Number] [nvarchar](max)  NULL,
	[KYC] [nvarchar](max)  NULL,
	[Created By] [nvarchar](max)  NULL,
	[Created By (Delegate)] [nvarchar](max)  NULL,
	[Modified By] [nvarchar](max)  NULL,
	[Modified By (Delegate)] [nvarchar](max)  NULL,
	[Owner] [nvarchar](max)  NULL,
	[Owning Business Unit] [nvarchar](max)  NULL,
	[Owning Team] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Incomes]
( 
	[Name] [varchar](150)  NULL,
	[Income Frequency] [int]  NULL,
	[Income Type] [varchar](150)  NULL,
	[Owner (Lookup)] [varchar](150)  NULL,
	[Status] [varchar](150)  NULL,
	[Business Phone] [varchar](150)  NULL,
	[City] [varchar](150)  NULL,
	[Country/Region] [varchar](150)  NULL,
	[Does Pension Plan Has Beneficiary] [int]  NULL,
	[Employment Start Date] [datetime]  NULL,
	[Employment Type] [varchar](150)  NULL,
	[Employment Work Months] [int]  NULL,
	[Gross Income] [money]  NULL,
	[Gross Income (Base)] [money]  NULL,
	[Income Provider Name] [varchar](150)  NULL,
	[Job Title] [varchar](300)  NULL,
	[Loan Application Contact ID (Lookup)] [varchar](150)  NULL,
	[Net Income] [money]  NULL,
	[Net Income (Base)] [money]  NULL,
	[Pension Beneficiary Percentage] [int]  NULL,
	[Pension Plan End Date] [varchar](150)  NULL,
	[State/Province] [varchar](150)  NULL,
	[Street 1] [varchar](150)  NULL,
	[Street 2] [varchar](150)  NULL,
	[Street 3] [varchar](150)  NULL,
	[Zip/Postal Code] [bigint]  NULL,
	[Created By (Lookup)] [varchar](150)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](150)  NULL,
	[Created On] [varchar](150)  NULL,
	[Currency (Lookup)] [varchar](150)  NULL,
	[Exchange Rate] [int]  NULL,
	[Import Sequence Number] [varchar](150)  NULL,
	[Modified By (Lookup)] [varchar](150)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](150)  NULL,
	[Modified On] [varchar](150)  NULL,
	[Owning Business Unit (Lookup)] [varchar](200)  NULL,
	[Owning Team (Lookup)] [varchar](150)  NULL,
	[Record Created On] [varchar](150)  NULL,
	[Status Reason] [varchar](150)  NULL,
	[Time Zone Rule Version Number] [varchar](150)  NULL,
	[UTC Conversion Time Zone Code] [varchar](150)  NULL,
	[Version Number] [varchar](150)  NULL,
	[Income] [varchar](150)  NULL,
	[Created By] [varchar](150)  NULL,
	[Created By (Delegate)] [varchar](150)  NULL,
	[Currency] [varchar](150)  NULL,
	[Loan Application Contact ID] [varchar](150)  NULL,
	[Modified By] [varchar](150)  NULL,
	[Modified By (Delegate)] [varchar](150)  NULL,
	[Owner] [varchar](150)  NULL,
	[Owning Business Unit] [varchar](150)  NULL,
	[Owning Team] [varchar](150)  NULL
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

CREATE TABLE [dbo].[GroupMembers]
( 
	[Name] [varchar](150)  NULL,
	[Group (Lookup)] [varchar](50)  NULL,
	[Is Group Type Primary] [varchar](5)  NULL,
	[Owner (Lookup)] [varchar](30)  NULL,
	[Role] [varchar](30)  NULL,
	[Status] [varchar](10)  NULL,
	[Created By (Lookup)] [varchar](30)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](20)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [int]  NULL,
	[Modified By (Lookup)] [varchar](30)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](10)  NULL,
	[Owning Team (Lookup)] [varchar](10)  NULL,
	[Record Created On] [datetime]  NULL,
	[Status Reason] [varchar](10)  NULL,
	[Time Zone Rule Version Number] [varchar](10)  NULL,
	[UTC Conversion Time Zone Code] [varchar](10)  NULL,
	[Version Number] [bigint]  NULL,
	[Group Member] [varchar](150)  NULL,
	[Created By] [varchar](150)  NULL,
	[Created By (Delegate)] [varchar](10)  NULL,
	[Group] [varchar](150)  NULL,
	[Modified By] [varchar](150)  NULL,
	[Modified By (Delegate)] [varchar](10)  NULL,
	[Owner] [varchar](150)  NULL,
	[Owning Business Unit] [varchar](150)  NULL,
	[Owning Team] [varchar](10)  NULL
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

CREATE TABLE [dbo].[GroupFinancialHolding]
( 
	[Name] [varchar](100)  NULL,
	[FinancialHolding1] [varchar](50)  NULL,
	[Group2] [varchar](50)  NULL,
	[Owner3] [varchar](30)  NULL,
	[Status] [varchar](10)  NULL,
	[CreatedBy5] [varchar](30)  NULL,
	[CreatedBy6] [varchar](10)  NULL,
	[CreatedOn] [datetime]  NULL,
	[ImportSequenceNumber] [varchar](10)  NULL,
	[ModifiedBy9] [varchar](30)  NULL,
	[ModifiedBy10] [varchar](10)  NULL,
	[ModifiedOn] [datetime]  NULL,
	[OwningBusinessUnit12] [varchar](10)  NULL,
	[OwningTeam13] [varchar](10)  NULL,
	[RecordCreatedOn] [varchar](10)  NULL,
	[StatusReason] [varchar](10)  NULL,
	[TimeZoneRuleVersionNumber] [varchar](10)  NULL,
	[UTCConversionTimeZoneCode] [varchar](10)  NULL,
	[VersionNumber] [varchar](10)  NULL,
	[GroupFinancialHolding] [varchar](100)  NULL,
	[CreatedBy20] [varchar](100)  NULL,
	[CreatedBy21] [varchar](10)  NULL,
	[FinancialHolding22] [varchar](100)  NULL,
	[Group23] [varchar](100)  NULL,
	[ModifiedBy24] [varchar](100)  NULL,
	[ModifiedBy25] [varchar](10)  NULL,
	[Owner26] [varchar](100)  NULL,
	[OwningBusinessUnit27] [varchar](100)  NULL,
	[OwningTeam28] [varchar](10)  NULL
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

CREATE TABLE [dbo].[Group]
( 
	[Name] [varchar](50)  NULL,
	[Address] [varchar](100)  NULL,
	[Owner2] [varchar](30)  NULL,
	[Status] [varchar](10)  NULL,
	[Type] [varchar](20)  NULL,
	[PrimaryMember5] [varchar](100)  NULL,
	[CreatedBy6] [varchar](30)  NULL,
	[CreatedBy7] [varchar](10)  NULL,
	[CreatedOn] [datetime]  NULL,
	[ImportSequenceNumber] [varchar](10)  NULL,
	[ModifiedBy10] [varchar](30)  NULL,
	[ModifiedBy11] [varchar](10)  NULL,
	[ModifiedOn] [datetime]  NULL,
	[OwningBusinessUnit13] [varchar](10)  NULL,
	[OwningTeam14] [varchar](10)  NULL,
	[RecordCreatedOn] [varchar](10)  NULL,
	[StatusReason] [varchar](10)  NULL,
	[TimeZoneRuleVersionNumber] [varchar](10)  NULL,
	[UTCConversionTimeZoneCode] [varchar](10)  NULL,
	[VersionNumber] [varchar](10)  NULL,
	[Group] [varchar](100)  NULL,
	[AddressSource] [varchar](100)  NULL,
	[CreatedBy22] [varchar](100)  NULL,
	[CreatedBy23] [varchar](10)  NULL,
	[ModifiedBy24] [varchar](100)  NULL,
	[ModifiedBy25] [varchar](10)  NULL,
	[Owner26] [varchar](100)  NULL,
	[OwningBusinessUnit27] [varchar](100)  NULL,
	[OwningTeam28] [varchar](10)  NULL,
	[PrimaryMember29] [varchar](100)  NULL
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

CREATE TABLE [dbo].[FSI-Twitter-Data]
( 
	[TwitterData] [nvarchar](4000)  NULL
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

CREATE TABLE [dbo].[LoanApplicationContact]
( 
	[Name] [nvarchar](max)  NULL,
	[Is Primary Borrower] [nvarchar](max)  NULL,
	[Loan Application Role] [nvarchar](max)  NULL,
	[Owner (Lookup)] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[Is Borrower Employer Relationship] [nvarchar](max)  NULL,
	[Loan Application ID (Lookup)] [nvarchar](max)  NULL,
	[Created By (Lookup)] [nvarchar](max)  NULL,
	[Created By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Created On] [nvarchar](max)  NULL,
	[Import Sequence Number] [nvarchar](max)  NULL,
	[Modified By (Lookup)] [nvarchar](max)  NULL,
	[Modified By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Modified On] [nvarchar](max)  NULL,
	[Owning Business Unit (Lookup)] [nvarchar](max)  NULL,
	[Owning Team (Lookup)] [nvarchar](max)  NULL,
	[Record Created On] [nvarchar](max)  NULL,
	[Status Reason] [nvarchar](max)  NULL,
	[Time Zone Rule Version Number] [nvarchar](max)  NULL,
	[UTC Conversion Time Zone Code] [nvarchar](max)  NULL,
	[Version Number] [nvarchar](max)  NULL,
	[Loan Application Contact ID] [nvarchar](max)  NULL,
	[Created By] [nvarchar](max)  NULL,
	[Created By (Delegate)] [nvarchar](max)  NULL,
	[Loan Application ID] [nvarchar](max)  NULL,
	[Modified By] [nvarchar](max)  NULL,
	[Modified By (Delegate)] [nvarchar](max)  NULL,
	[Owner] [nvarchar](max)  NULL,
	[Owning Business Unit] [nvarchar](max)  NULL,
	[Owning Team] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[LoanApplicationContacts]
( 
	[Name] [varchar](20)  NULL,
	[Is Primary Borrower] [varchar](20)  NULL,
	[Loan Application Role] [varchar](10)  NULL,
	[Owner (Lookup)] [varchar](30)  NULL,
	[Status] [varchar](10)  NULL,
	[Is Borrower Employer Relationship] [varchar](5)  NULL,
	[Loan Application ID (Lookup)] [varchar](30)  NULL,
	[Created By (Lookup)] [varchar](20)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [bigint]  NULL,
	[Modified By (Lookup)] [varchar](30)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](20)  NULL,
	[Owning Team (Lookup)] [varchar](10)  NULL,
	[Record Created On] [datetime]  NULL,
	[Status Reason] [varchar](10)  NULL,
	[Time Zone Rule Version Number] [int]  NULL,
	[UTC Conversion Time Zone Code] [int]  NULL,
	[Version Number] [bigint]  NULL,
	[Loan Application Contact ID] [varchar](100)  NULL,
	[Created By] [varchar](100)  NULL,
	[Created By (Delegate)] [varchar](100)  NULL,
	[Loan Application ID] [varchar](100)  NULL,
	[Modified By] [varchar](100)  NULL,
	[Modified By (Delegate)] [varchar](100)  NULL,
	[Owner] [varchar](100)  NULL,
	[Owning Business Unit] [varchar](100)  NULL,
	[Owning Team] [varchar](10)  NULL
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

CREATE TABLE [dbo].[LoanApplication]
( 
	[Name] [nvarchar](max)  NULL,
	[Application Status] [nvarchar](max)  NULL,
	[Owner (Lookup)] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[Application Type] [nvarchar](max)  NULL,
	[Balloon Amount] [nvarchar](max)  NULL,
	[Balloon Amount (Base)] [nvarchar](max)  NULL,
	[Balloon Term Count] [nvarchar](max)  NULL,
	[Deposit Amount] [nvarchar](max)  NULL,
	[Deposit Amount (Base)] [nvarchar](max)  NULL,
	[Discount Points Total Amount] [nvarchar](max)  NULL,
	[Discount Points Total Amount (Base)] [nvarchar](max)  NULL,
	[Down Payment] [nvarchar](max)  NULL,
	[Down Payment (Base)] [nvarchar](max)  NULL,
	[Escrow Payment Amount] [nvarchar](max)  NULL,
	[Escrow Payment Amount (Base)] [nvarchar](max)  NULL,
	[First Month Interest Amount] [nvarchar](max)  NULL,
	[First Month Interest Amount (Base)] [nvarchar](max)  NULL,
	[Interest Only Term Month Count] [nvarchar](max)  NULL,
	[Interest Rate] [nvarchar](max)  NULL,
	[Interest Type] [nvarchar](max)  NULL,
	[Is Balloon Payment] [nvarchar](max)  NULL,
	[Is Interest Only] [nvarchar](max)  NULL,
	[Is Negative Amortization] [nvarchar](max)  NULL,
	[Lending Limit] [nvarchar](max)  NULL,
	[Lending Limit (Base)] [nvarchar](max)  NULL,
	[Loan Application Closing Date] [nvarchar](max)  NULL,
	[Loan Originator (Lookup)] [nvarchar](max)  NULL,
	[Loan To Value] [nvarchar](max)  NULL,
	[Loan Type] [nvarchar](max)  NULL,
	[Max Loan To Value] [nvarchar](max)  NULL,
	[Meetings] [nvarchar](max)  NULL,
	[Note Amount] [nvarchar](max)  NULL,
	[Note Amount (Base)] [nvarchar](max)  NULL,
	[Overall Completion] [nvarchar](max)  NULL,
	[Principal Amount] [nvarchar](max)  NULL,
	[Principal Amount (Base)] [nvarchar](max)  NULL,
	[Refinance Type] [nvarchar](max)  NULL,
	[Status2] [nvarchar](max)  NULL,
	[Term] [nvarchar](max)  NULL,
	[Workflow stage] [nvarchar](max)  NULL,
	[(Deprecated) Traversed Path] [nvarchar](max)  NULL,
	[Created By (Lookup)] [nvarchar](max)  NULL,
	[Created By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Currency (Lookup)] [nvarchar](max)  NULL,
	[Exchange Rate] [nvarchar](max)  NULL,
	[Import Sequence Number] [nvarchar](max)  NULL,
	[Loan Application Start Date] [nvarchar](max)  NULL,
	[Modified By (Lookup)] [nvarchar](max)  NULL,
	[Modified By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Modified On] [nvarchar](max)  NULL,
	[Owning Business Unit (Lookup)] [nvarchar](max)  NULL,
	[Owning Team (Lookup)] [nvarchar](max)  NULL,
	[Record Created On] [nvarchar](max)  NULL,
	[Status Reason] [nvarchar](max)  NULL,
	[Time Zone Rule Version Number] [nvarchar](max)  NULL,
	[UTC Conversion Time Zone Code] [nvarchar](max)  NULL,
	[Version Number] [nvarchar](max)  NULL,
	[Loan Application] [nvarchar](max)  NULL,
	[(Deprecated) Stage Id] [nvarchar](max)  NULL,
	[Process Id] [nvarchar](max)  NULL,
	[Created By] [nvarchar](max)  NULL,
	[Created By (Delegate)] [nvarchar](max)  NULL,
	[Currency] [nvarchar](max)  NULL,
	[Loan Originator] [nvarchar](max)  NULL,
	[Modified By] [nvarchar](max)  NULL,
	[Modified By (Delegate)] [nvarchar](max)  NULL,
	[Owner] [nvarchar](max)  NULL,
	[Owning Business Unit] [nvarchar](max)  NULL,
	[Owning Team] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[LifeMomentTypeConfigs]
( 
	[Name] [varchar](20)  NULL,
	[Owner (Lookup)] [varchar](30)  NULL,
	[Status] [varchar](15)  NULL,
	[Type Code] [bigint]  NULL,
	[Display Order] [varchar](10)  NULL,
	[Created By (Lookup)] [varchar](20)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [bigint]  NULL,
	[Modified By (Lookup)] [varchar](20)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](150)  NULL,
	[Owning Team (Lookup)] [varchar](30)  NULL,
	[Record Created On] [datetime]  NULL,
	[Status Reason] [varchar](10)  NULL,
	[Time Zone Rule Version Number] [varchar](15)  NULL,
	[UTC Conversion Time Zone Code] [varchar](15)  NULL,
	[Version Number] [bigint]  NULL,
	[Life Moment Type Config] [varchar](150)  NULL,
	[Created By] [varchar](150)  NULL,
	[Created By (Delegate)] [varchar](15)  NULL,
	[Modified By] [varchar](150)  NULL,
	[Modified By (Delegate)] [varchar](15)  NULL,
	[Owner] [varchar](150)  NULL,
	[Owning Business Unit] [varchar](150)  NULL,
	[Owning Team] [varchar](10)  NULL
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

CREATE TABLE [dbo].[LifeMomentTypeConfig]
( 
	[Name] [nvarchar](max)  NULL,
	[Owner (Lookup)] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[Type Code] [nvarchar](max)  NULL,
	[Display Order] [nvarchar](max)  NULL,
	[Created By (Lookup)] [nvarchar](max)  NULL,
	[Created By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Created On] [nvarchar](max)  NULL,
	[Import Sequence Number] [nvarchar](max)  NULL,
	[Modified By (Lookup)] [nvarchar](max)  NULL,
	[Modified By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Modified On] [nvarchar](max)  NULL,
	[Owning Business Unit (Lookup)] [nvarchar](max)  NULL,
	[Owning Team (Lookup)] [nvarchar](max)  NULL,
	[Record Created On] [nvarchar](max)  NULL,
	[Status Reason] [nvarchar](max)  NULL,
	[Time Zone Rule Version Number] [nvarchar](max)  NULL,
	[UTC Conversion Time Zone Code] [nvarchar](max)  NULL,
	[Version Number] [nvarchar](max)  NULL,
	[Life Moment Type Config] [nvarchar](max)  NULL,
	[Created By] [nvarchar](max)  NULL,
	[Created By (Delegate)] [nvarchar](max)  NULL,
	[Modified By] [nvarchar](max)  NULL,
	[Modified By (Delegate)] [nvarchar](max)  NULL,
	[Owner] [nvarchar](max)  NULL,
	[Owning Business Unit] [nvarchar](max)  NULL,
	[Owning Team] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Lifemomentsconfigurations_s]
( 
	[Name] [varchar](10)  NULL,
	[Birthday Category Code] [varchar](20)  NULL,
	[Birthday Type Code] [varchar](20)  NULL,
	[Education Category Code] [varchar](20)  NULL,
	[Focus Indication Period Days] [varchar](5)  NULL,
	[New Moment Indication Period Days] [varchar](5)  NULL,
	[Other Category Code] [varchar](20)  NULL,
	[Other Type Code] [varchar](20)  NULL,
	[Owner (Lookup)] [varchar](30)  NULL,
	[Status] [varchar](10)  NULL,
	[Created By (Lookup)] [varchar](20)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [varchar](10)  NULL,
	[Modified By (Lookup)] [varchar](20)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](10)  NULL,
	[Owning Team (Lookup)] [varchar](10)  NULL,
	[Record Created On] [varchar](10)  NULL,
	[Status Reason] [varchar](10)  NULL,
	[Time Zone Rule Version Number] [varchar](10)  NULL,
	[UTC Conversion Time Zone Code] [varchar](10)  NULL,
	[Version Number] [varchar](10)  NULL,
	[Life Moments Configurations] [varchar](50)  NULL,
	[Created By] [varchar](50)  NULL,
	[Created By (Delegate)] [varchar](10)  NULL,
	[Modified By] [varchar](50)  NULL,
	[Modified By (Delegate)] [varchar](10)  NULL,
	[Owner] [varchar](50)  NULL,
	[Owning Business Unit] [varchar](50)  NULL,
	[Owning Team] [varchar](10)  NULL
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

CREATE TABLE [dbo].[Lifemomentsconfigurations]
( 
	[Name] [nvarchar](max)  NULL,
	[Birthday Category Code] [nvarchar](max)  NULL,
	[Birthday Type Code] [nvarchar](max)  NULL,
	[Education Category Code] [nvarchar](max)  NULL,
	[Focus Indication Period Days] [nvarchar](max)  NULL,
	[New Moment Indication Period Days] [nvarchar](max)  NULL,
	[Other Category Code] [nvarchar](max)  NULL,
	[Other Type Code] [nvarchar](max)  NULL,
	[Owner (Lookup)] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[Created By (Lookup)] [nvarchar](max)  NULL,
	[Created By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Created On] [nvarchar](max)  NULL,
	[Import Sequence Number] [nvarchar](max)  NULL,
	[Modified By (Lookup)] [nvarchar](max)  NULL,
	[Modified By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Modified On] [nvarchar](max)  NULL,
	[Owning Business Unit (Lookup)] [nvarchar](max)  NULL,
	[Owning Team (Lookup)] [nvarchar](max)  NULL,
	[Record Created On] [nvarchar](max)  NULL,
	[Status Reason] [nvarchar](max)  NULL,
	[Time Zone Rule Version Number] [nvarchar](max)  NULL,
	[UTC Conversion Time Zone Code] [nvarchar](max)  NULL,
	[Version Number] [nvarchar](max)  NULL,
	[Life Moments Configurations] [nvarchar](max)  NULL,
	[Created By] [nvarchar](max)  NULL,
	[Created By (Delegate)] [nvarchar](max)  NULL,
	[Modified By] [nvarchar](max)  NULL,
	[Modified By (Delegate)] [nvarchar](max)  NULL,
	[Owner] [nvarchar](max)  NULL,
	[Owning Business Unit] [nvarchar](max)  NULL,
	[Owning Team] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Lifemoments]
( 
	[Name] [varchar](50)  NULL,
	[Contact (Lookup)] [varchar](20)  NULL,
	[Date] [datetime]  NULL,
	[Life Moment Category] [varchar](50)  NULL,
	[Life Moment Type] [varchar](50)  NULL,
	[Owner (Lookup)] [varchar](50)  NULL,
	[Status] [varchar](10)  NULL,
	[Title] [varchar](250)  NULL,
	[Created By (Lookup)] [varchar](50)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](50)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [int]  NULL,
	[Modified By (Lookup)] [varchar](50)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](50)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](150)  NULL,
	[Owning Team (Lookup)] [varchar](150)  NULL,
	[Record Created On] [datetime]  NULL,
	[Status Reason] [varchar](max)  NULL,
	[Time Zone Rule Version Number] [int]  NULL,
	[UTC Conversion Time Zone Code] [varchar](30)  NULL,
	[Version Number] [bigint]  NULL,
	[Life Moment] [varchar](200)  NULL,
	[Contact] [varchar](200)  NULL,
	[Created By] [varchar](150)  NULL,
	[Created By (Delegate)] [varchar](10)  NULL,
	[Modified By] [varchar](150)  NULL,
	[Modified By (Delegate)] [varchar](10)  NULL,
	[Owner] [varchar](150)  NULL,
	[Owning Business Unit] [varchar](150)  NULL,
	[Owning Team] [varchar](10)  NULL
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

CREATE TABLE [dbo].[Lifemomentcategoryconfig]
( 
	[Name] [varchar](150)  NULL,
	[Category Code] [varchar](20)  NULL,
	[Display Order] [varchar](10)  NULL,
	[Icon] [varchar](20)  NULL,
	[Owner (Lookup)] [varchar](30)  NULL,
	[Status] [varchar](10)  NULL,
	[Created By (Lookup)] [varchar](30)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Created On] [datetime]  NULL,
	[Import Sequence Number] [varchar](31)  NULL,
	[Modified By (Lookup)] [varchar](30)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](10)  NULL,
	[Modified On] [datetime]  NULL,
	[Owning Business Unit (Lookup)] [varchar](10)  NULL,
	[Owning Team (Lookup)] [varchar](10)  NULL,
	[Record Created On] [varchar](10)  NULL,
	[Status Reason] [varchar](10)  NULL,
	[Time Zone Rule Version Number] [varchar](10)  NULL,
	[UTC Conversion Time Zone Code] [varchar](10)  NULL,
	[Version Number] [varchar](10)  NULL,
	[Life Moment Category Config] [varchar](50)  NULL,
	[Created By] [varchar](50)  NULL,
	[Created By (Delegate)] [varchar](10)  NULL,
	[Modified By] [varchar](50)  NULL,
	[Modified By (Delegate)] [varchar](10)  NULL,
	[Owner] [varchar](50)  NULL,
	[Owning Business Unit] [varchar](50)  NULL,
	[Owning Team] [varchar](10)  NULL
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

CREATE TABLE [dbo].[OFAC]
( 
	[step] [nvarchar](max)  NULL,
	[type] [nvarchar](max)  NULL,
	[amount] [nvarchar](max)  NULL,
	[nameOrig] [nvarchar](max)  NULL,
	[oldbalanceOrg] [nvarchar](max)  NULL,
	[newbalanceOrig] [nvarchar](max)  NULL,
	[nameDest] [nvarchar](max)  NULL,
	[oldbalanceDest] [nvarchar](max)  NULL,
	[newbalanceDest] [nvarchar](max)  NULL,
	[isFraud] [nvarchar](max)  NULL,
	[isFlaggedFraud] [nvarchar](max)  NULL,
	[id] [nvarchar](max)  NULL,
	[_rid] [nvarchar](max)  NULL,
	[_self] [nvarchar](max)  NULL,
	[_etag] [nvarchar](max)  NULL,
	[_attachments] [nvarchar](max)  NULL,
	[_ts] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[PropertyHoldings]
( 
	[Name] [nvarchar](max)  NULL,
	[Category] [nvarchar](max)  NULL,
	[Owner (Lookup)] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[Address Line 1] [nvarchar](max)  NULL,
	[Address Line 2] [nvarchar](max)  NULL,
	[Address Line 3] [nvarchar](max)  NULL,
	[City] [nvarchar](max)  NULL,
	[Country/Region] [nvarchar](max)  NULL,
	[Description] [nvarchar](max)  NULL,
	[Insurance Amount] [nvarchar](max)  NULL,
	[Insurance Amount (Base)] [nvarchar](max)  NULL,
	[Is Legal Check Successful] [nvarchar](max)  NULL,
	[Latitude] [nvarchar](max)  NULL,
	[Legal Check Completion Date] [nvarchar](max)  NULL,
	[Legal Description] [nvarchar](max)  NULL,
	[Longitude] [nvarchar](max)  NULL,
	[Purchase Date] [nvarchar](max)  NULL,
	[Selected Property Holding Valuation (Lookup)] [nvarchar](max)  NULL,
	[State/Province] [nvarchar](max)  NULL,
	[Tax Amount] [nvarchar](max)  NULL,
	[Tax Amount (Base)] [nvarchar](max)  NULL,
	[Type] [nvarchar](max)  NULL,
	[ZIP/Postal Code] [nvarchar](max)  NULL,
	[Created By (Lookup)] [nvarchar](max)  NULL,
	[Created By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Created On] [nvarchar](max)  NULL,
	[Currency (Lookup)] [nvarchar](max)  NULL,
	[Exchange Rate] [nvarchar](max)  NULL,
	[Import Sequence Number] [nvarchar](max)  NULL,
	[Modified By (Lookup)] [nvarchar](max)  NULL,
	[Modified By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Modified On] [nvarchar](max)  NULL,
	[Owning Business Unit (Lookup)] [nvarchar](max)  NULL,
	[Owning Team (Lookup)] [nvarchar](max)  NULL,
	[Record Created On] [nvarchar](max)  NULL,
	[Status Reason] [nvarchar](max)  NULL,
	[Owner] [nvarchar](max)  NULL,
	[Owning Business Unit] [nvarchar](max)  NULL,
	[Owning Team] [nvarchar](max)  NULL,
	[Selected Property Holding Valuation] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[RoleNew]
( 
	[RoleID] [nvarchar](max)  NULL,
	[Name] [nvarchar](max)  NULL,
	[Email] [nvarchar](max)  NULL,
	[Roles] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Source]
( 
	[Id] [bigint]  NOT NULL,
	[Name] [nvarchar](50)  NOT NULL
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

CREATE TABLE [dbo].[USHeaderMapReport]
( 
	[City] [nvarchar](255)  NULL,
	[Total Patients] [float]  NULL,
	[Number of Patients] [float]  NULL,
	[Rating] [nvarchar](255)  NULL,
	[OccupancyRate%] [float]  NULL,
	[Margin] [float]  NULL,
	[Readmission Rate] [float]  NULL
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

CREATE TABLE [dbo].[ApplicationCollaterals]
( 
	[Name] [nvarchar](max)  NULL,
	[Owner (Lookup)] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[Type] [nvarchar](max)  NULL,
	[Financial Holding ID (Lookup)] [nvarchar](max)  NULL,
	[Loan Application (Lookup)] [nvarchar](max)  NULL,
	[Property Holding ID (Lookup)] [nvarchar](max)  NULL,
	[Created By (Lookup)] [nvarchar](max)  NULL,
	[Created By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Created On] [nvarchar](max)  NULL,
	[Import Sequence Number] [nvarchar](max)  NULL,
	[Modified By (Lookup)] [nvarchar](max)  NULL,
	[Modified By (Delegate) (Lookup)] [nvarchar](max)  NULL,
	[Modified On] [nvarchar](max)  NULL,
	[Owning Business Unit (Lookup)] [nvarchar](max)  NULL,
	[Owning Team (Lookup)] [nvarchar](max)  NULL,
	[Record Created On] [nvarchar](max)  NULL,
	[Status Reason] [nvarchar](max)  NULL,
	[Time Zone Rule Version Number] [nvarchar](max)  NULL,
	[UTC Conversion Time Zone Code] [nvarchar](max)  NULL,
	[Version Number] [nvarchar](max)  NULL,
	[Application Collaterals] [nvarchar](max)  NULL,
	[Created By] [nvarchar](max)  NULL,
	[Created By (Delegate)] [nvarchar](max)  NULL,
	[Financial Holding ID] [nvarchar](max)  NULL,
	[Loan Application] [nvarchar](max)  NULL,
	[Modified By] [nvarchar](max)  NULL,
	[Modified By (Delegate)] [nvarchar](max)  NULL,
	[Owner] [nvarchar](max)  NULL,
	[Owning Business Unit] [nvarchar](max)  NULL,
	[Owning Team] [nvarchar](max)  NULL,
	[Property Holding ID] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[LoanApplications]
( 
	[Name] [varchar](20)  NULL,
	[Application Status] [varchar](10)  NULL,
	[Owner (Lookup)] [varchar](20)  NULL,
	[Status] [varchar](20)  NULL,
	[Application Type] [varchar](10)  NULL,
	[Balloon Amount] [decimal](10,2)  NULL,
	[Balloon Amount (Base)] [decimal](10,2)  NULL,
	[Balloon Term Count] [decimal](10,2)  NULL,
	[Deposit Amount] [decimal](10,2)  NULL,
	[Deposit Amount (Base)] [decimal](10,2)  NULL,
	[Discount Points Total Amount] [decimal](10,2)  NULL,
	[Discount Points Total Amount (Base)] [decimal](10,2)  NULL,
	[Down Payment] [decimal](10,2)  NULL,
	[Down Payment (Base)] [decimal](10,2)  NULL,
	[Escrow Payment Amount] [decimal](10,2)  NULL,
	[Escrow Payment Amount (Base)] [decimal](10,2)  NULL,
	[First Month Interest Amount] [decimal](10,2)  NULL,
	[First Month Interest Amount (Base)] [decimal](10,2)  NULL,
	[Interest Only Term Month Count] [decimal](10,2)  NULL,
	[Interest Rate] [decimal](10,2)  NULL,
	[Interest Type] [varchar](20)  NULL,
	[Is Balloon Payment] [varchar](30)  NULL,
	[Is Interest Only] [varchar](30)  NULL,
	[Is Negative Amortization] [varchar](20)  NULL,
	[Lending Limit] [varchar](20)  NULL,
	[Lending Limit (Base)] [varchar](20)  NULL,
	[Loan Application Closing Date] [datetime]  NULL,
	[Loan Originator (Lookup)] [varchar](20)  NULL,
	[Loan To Value] [varchar](20)  NULL,
	[Loan Type] [varchar](20)  NULL,
	[Max Loan To Value] [varchar](20)  NULL,
	[Meetings] [varchar](20)  NULL,
	[Note Amount] [varchar](100)  NULL,
	[Note Amount (Base)] [varchar](100)  NULL,
	[Overall Completion] [varchar](100)  NULL,
	[Principal Amount] [varchar](100)  NULL,
	[Principal Amount (Base)] [varchar](100)  NULL,
	[Refinance Type] [varchar](100)  NULL,
	[Status2] [varchar](100)  NULL,
	[Term] [varchar](100)  NULL,
	[Workflow stage] [varchar](100)  NULL,
	[(Deprecated) Traversed Path] [varchar](100)  NULL,
	[Created By (Lookup)] [varchar](100)  NULL,
	[Created By (Delegate) (Lookup)] [varchar](100)  NULL,
	[Currency (Lookup)] [varchar](100)  NULL,
	[Exchange Rate] [varchar](100)  NULL,
	[Import Sequence Number] [varchar](100)  NULL,
	[Loan Application Start Date] [varchar](100)  NULL,
	[Modified By (Lookup)] [varchar](100)  NULL,
	[Modified By (Delegate) (Lookup)] [varchar](100)  NULL,
	[Modified On] [varchar](100)  NULL,
	[Owning Business Unit (Lookup)] [varchar](100)  NULL,
	[Owning Team (Lookup)] [varchar](100)  NULL,
	[Record Created On] [varchar](100)  NULL,
	[Status Reason] [varchar](100)  NULL,
	[Time Zone Rule Version Number] [varchar](100)  NULL,
	[UTC Conversion Time Zone Code] [varchar](100)  NULL,
	[Version Number] [varchar](100)  NULL,
	[Loan Application] [varchar](100)  NULL,
	[(Deprecated) Stage Id] [varchar](100)  NULL,
	[Process Id] [varchar](100)  NULL,
	[Created By] [varchar](100)  NULL,
	[Created By (Delegate)] [varchar](100)  NULL,
	[Currency] [varchar](100)  NULL,
	[Loan Originator] [varchar](100)  NULL,
	[Modified By] [varchar](100)  NULL,
	[Modified By (Delegate)] [varchar](100)  NULL,
	[Owner] [varchar](100)  NULL,
	[Owning Business Unit] [varchar](100)  NULL,
	[Owning Team] [varchar](100)  NULL
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

CREATE TABLE [dbo].[SynapseLinkFSIData]
( 
	[UpdatedOn] [datetime]  NULL,
	[TransactionType] [varchar](20)  NULL,
	[TransactionInitiated] [decimal](10,2)  NULL,
	[TransactionCompleted] [decimal](10,2)  NULL,
	[OFACCompleted] [decimal](10,2)  NULL,
	[OFACReported] [decimal](10,2)  NULL,
	[ComplianceReport] [decimal](10,2)  NULL,
	[TransactionVerified] [decimal](10,2)  NULL,
	[TransactionAmount] [int]  NULL,
	[TransactionCount] [int]  NULL,
	[Quality] [decimal](10,2)  NULL,
	[ComplianceVerified] [int]  NULL
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

CREATE TABLE [dbo].[SynapseLinkFSIDataHTAP]
( 
	[UpdatedOn] [datetime]  NULL,
	[TransactionType] [varchar](20)  NULL,
	[TransactionInitiated] [decimal](10,2)  NULL,
	[TransactionCompleted] [decimal](10,2)  NULL,
	[OFACCompleted] [decimal](10,2)  NULL,
	[OFACReported] [decimal](10,2)  NULL,
	[ComplianceReport] [decimal](10,2)  NULL,
	[TransactionVerified] [decimal](10,2)  NULL,
	[TransactionAmount] [int]  NULL,
	[TransactionCount] [int]  NULL,
	[ComplianceVerified] [int]  NULL,
	[Quality] [decimal](10,2)  NULL
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

CREATE TABLE [dbo].[pbiInterestRevenue]
( 
	[InstitutionId] [int]  NULL,
	[InterestRevenue] [int]  NULL,
	[TargetInterestRevenue] [int]  NULL,
	[Date] [date]  NULL
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

CREATE TABLE [dbo].[pbiIncidentsSsDocument]
( 
	[PartitionKey] [nvarchar](max)  NULL,
	[RowKey] [nvarchar](max)  NULL,
	[Timestamp] [datetimeoffset](7)  NULL,
	[Amputation] [bigint]  NULL,
	[CaseId] [bigint]  NULL,
	[Documentid] [nvarchar](max)  NULL,
	[Employer] [nvarchar](max)  NULL,
	[EventDate] [nvarchar](max)  NULL,
	[EventTitle] [nvarchar](max)  NULL,
	[FinalNarrative] [nvarchar](max)  NULL,
	[Hospitalized] [bigint]  NULL,
	[Location] [nvarchar](max)  NULL,
	[NatureTitle] [nvarchar](max)  NULL,
	[PartofBodyTitle] [nvarchar](max)  NULL,
	[SourceTitle] [nvarchar](max)  NULL,
	[jsons] [nvarchar](max)  NULL,
	[languageCode] [nvarchar](max)  NULL,
	[metadata_storage_content_md5] [nvarchar](max)  NULL,
	[metadata_storage_content_type] [nvarchar](max)  NULL,
	[metadata_storage_file_extension] [nvarchar](max)  NULL,
	[metadata_storage_last_modified] [nvarchar](max)  NULL,
	[metadata_storage_name] [nvarchar](max)  NULL,
	[metadata_storage_path] [nvarchar](max)  NULL,
	[metadata_storage_size] [bigint]  NULL,
	[pdf] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[pbiCustomerTransactionsCopy]
( 
	[CustomerTransactionsId] [nvarchar](max)  NULL,
	[InstitutionId] [nvarchar](max)  NULL,
	[Country] [nvarchar](max)  NULL,
	[City] [nvarchar](max)  NULL,
	[Domain] [nvarchar](max)  NULL,
	[CustomerId] [nvarchar](max)  NULL,
	[TransactionAmount] [nvarchar](max)  NULL,
	[CtrFlag] [nvarchar](max)  NULL,
	[SarFlag] [nvarchar](max)  NULL,
	[FalseFlag] [nvarchar](max)  NULL,
	[Description] [nvarchar](max)  NULL,
	[DateTime] [nvarchar](max)  NULL,
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

CREATE VIEW [dbo].[vwSynapseLinkSynapseLast3HoursOFAC]
AS SELECT
        UpdatedOn
        ,AVG(quality) OFACCompleted
    FROM
        [SynapseLinkFSIData]
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 20
        AND DATEPART(HOUR, UpdatedOn) <= 22
    GROUP BY
        UpdatedOn;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseKPIsHTAP]
AS SELECT
        DATEPART(HOUR, UpdatedOn) ForHour
        ,AVG(OFACReported) OFACReported
        ,AVG(OFACCompleted) OFACCompleted
        ,AVG(ComplianceReport)*0.98 ComplianceReport
        ,AVG(TransactionVerified)*0.98 TransactionVerified
		,SUM(TransactionAmount)*195  TransactionAmount
		,SUM(TransactionCount)*18 TransactionCount
    FROM
        [SynapseLinkFSIDataHTAP]
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 17
        AND DATEPART(HOUR, UpdatedOn) <= 22
    GROUP BY
        DATEPART(HOUR, UpdatedOn);
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseKPIs]
AS SELECT
        DATEPART(HOUR, UpdatedOn) ForHour
        ,AVG(OFACReported) OFACReported
        ,AVG(OFACCompleted) OFACCompleted
        ,AVG(ComplianceReport) ComplianceReport
        ,AVG(TransactionVerified) TransactionVerified
		,SUM(TransactionAmount)*170  TransactionAmount
		,SUM(TransactionCount)*12 TransactionCount
    FROM
        [SynapseLinkFSIData]
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 17
        AND DATEPART(HOUR, UpdatedOn) <= 22
    GROUP BY
        DATEPART(HOUR, UpdatedOn);
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwPbiESGSlicerOrganizations]
AS SELECT
        InstitutionId
        , 0 AS InstitutionUnitId
        , 0 AS IsInstitutionUnit
        , InstitutionName AS DisplayName
    FROM
        pbiInstitution
    UNION
    SELECT
        InstitutionId
        , InstitutionUnitId
        , 1 AS IsInstitutionUnit
        , InstitutionUnitName AS DisplayName
    FROM
        pbiInstitutionUnit;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseWorkloadHTAP]
AS SELECT 
        [UpdatedOn]
        ,TransactionType
		,AVG(TransactionInitiated) TransactionInitiated
		,AVG(TransactionCompleted) TransactionCompleted
		,AVG(OFACCompleted) OFACCompleted
		,AVG(OFACReported) OFACReported
		,AVG(ComplianceReport ) ComplianceReport     
		,AVG(TransactionVerified) TransactionVerified

    FROM
        [SynapseLinkFSIDataHTAP]
WHERE  DATEPART(HOUR, UpdatedOn) < 23
   		GROUP BY TransactionType,[UpdatedOn];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseWorkload]
AS SELECT 
        [UpdatedOn]
        ,TransactionType
		,AVG(TransactionInitiated) TransactionInitiated
		,AVG(TransactionCompleted) TransactionCompleted
		,AVG(OFACCompleted) OFACCompleted
		,AVG(OFACReported) OFACReported
		,AVG(ComplianceReport ) ComplianceReport     
		,AVG(TransactionVerified) TransactionVerified
    FROM
        [SynapseLinkFSIData]
WHERE  DATEPART(HOUR, UpdatedOn) < 23
   		GROUP BY TransactionType,[UpdatedOn];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseLast7HoursOFACVerifiedHTAP]
AS SELECT
        DATEPART(HOUR, UpdatedOn) AS ForHour
      	,AVG(quality) OFACReported
		,AVG(ComplianceVerified) OFACCompleted
		FROM
        [SynapseLinkFSIDataHTAP]
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 17
        AND DATEPART(HOUR, UpdatedOn) <= 23
    GROUP BY
       DATEPART(HOUR, UpdatedOn);
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseLast7HoursOFACVerified]
AS SELECT
        LEFT(RIGHT(CONVERT(CHAR(19),UpdatedOn,100),7),2) + ':00 ' + RIGHT(RIGHT(CONVERT(CHAR(19),UpdatedOn,100),7),2) ForHours
      	,AVG(Quality) OFACReported
		,AVG([ComplianceVerified]) OFACCompleted
		FROM
        [SynapseLinkFSIData]
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 17
        AND DATEPART(HOUR, UpdatedOn) <= 22
    GROUP BY
         LEFT(RIGHT(CONVERT(CHAR(19),UpdatedOn,100),7),2) + ':00 ' + RIGHT(RIGHT(CONVERT(CHAR(19),UpdatedOn,100),7),2);
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwSynapseLinkSynapseLast3HoursOFACHTAP]
AS SELECT
         dateadd(HOUR, 7, UpdatedOn) UpdatedOn
		 ,AVG(quality) OFACCompleted
    FROM
        [SynapseLinkFSIDataHTAP]
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 21
        AND DATEPART(HOUR, UpdatedOn) <= 23
    GROUP BY
        UpdatedOn;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[testviewcls]
AS (
select  Top 100 * from Campaign_Analytics);

CREATE PROC [dbo].[Confirm DDM] AS 
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl   ON c.[object_id] = tbl.[object_id]  WHERE 
is_masked = 1 and tbl.name='CustomerInfo';
