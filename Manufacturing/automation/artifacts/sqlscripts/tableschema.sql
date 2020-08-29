/****** Object:  Table [dbo].[mfg-OEE]    Script Date: 7/24/2020 8:20:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mfg-OEE]
(
	[OEEId] [bigint] NULL,
	[Date] [datetime] NULL,
	[LocationId] [bigint] NULL,
	[Availability] [decimal](5, 2) NULL,
	[Performance] [decimal](5, 2) NULL,
	[Quality] [decimal](5, 2) NULL,
	[OEE] [decimal](5, 2) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE [dbo].[mfg-iot-lathe-peck-drill]
( 
	[EpochTime] [bigint]  NULL,
	[StringDateTime] [varchar](50)  NULL,
	[JobCode] [varchar](200)  NULL,
	[OperationId] [int]  NULL,
	[BatchCode] [varchar](2000)  NULL,
	[MachineCode] [varchar](2000)  NULL,
	[VibrationX] [float]  NULL,
	[VibrationY] [float]  NULL,
	[VibrationZ] [float]  NULL,
	[SpindleSpeed] [bigint]  NULL,
	[CoolantTemperature] [bigint]  NULL,
	[zAxis] [float]  NULL,
	[EventProcessedUtcTime] [datetime]  NULL,
	[PartitionId] [bigint]  NULL,
	[EventEnqueuedUtcTime] [datetime]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)

CREATE TABLE [dbo].[mfg-iot-lathe-thread-cut]
( 
	[EpochTime] [bigint]  NULL,
	[StringDateTime] [varchar](50)  NULL,
	[JobCode] [varchar](200)  NULL,
	[OperationId] [int]  NULL,
	[BatchCode] [varchar](2000)  NULL,
	[MachineCode] [varchar](2000)  NULL,
	[VibrationX] [float]  NULL,
	[VibrationY] [float]  NULL,
	[VibrationZ] [float]  NULL,
	[SpindleSpeed] [bigint]  NULL,
	[CoolantTemperature] [bigint]  NULL,
	[xAxis] [float]  NULL,
	[zAxis] [float]  NULL,
	[EventProcessedUtcTime] [datetime]  NULL,
	[PartitionId] [bigint]  NULL,
	[EventEnqueuedUtcTime] [datetime]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)

CREATE TABLE [dbo].[mfg-iot-milling-canning]
( 
	[EpochTime] [bigint]  NULL,
	[StringDateTime] [varchar](50)  NULL,
	[JobCode] [varchar](200)  NULL,
	[OperationId] [int]  NULL,
	[BatchCode] [varchar](2000)  NULL,
	[MachineCode] [varchar](2000)  NULL,
	[VibrationX] [float]  NULL,
	[VibrationY] [float]  NULL,
	[VibrationZ] [float]  NULL,
	[SpindleSpeed] [bigint]  NULL,
	[CoolantTemperature] [bigint]  NULL,
	[xAxis] [float]  NULL,
	[yAxis] [float]  NULL,
	[zAxis] [float]  NULL,
	[EventProcessedUtcTime] [datetime]  NULL,
	[PartitionId] [bigint]  NULL,
	[EventEnqueuedUtcTime] [datetime]  NULL,
	[AnomalyTemperature] [bigint]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
------------------------------------------
/****** Object:  Table [dbo].[mfg-MachineAlert]    Script Date: 7/24/2020 8:21:21 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mfg-MachineAlert]
(
	[RaisedTime] [datetime] NULL,
	[ClearedTime] [datetime] NULL,
	[JobCode] [varchar](100) NULL,
	[OperationId] [int] NULL,
	[MachineCode] [varchar](2000) NULL,
	[BatchCode] [varchar](2000) NULL,
	[AlarmCodeId] [bigint] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [BatchCode] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

--------------------------------------------------------------
/****** Object:  Table [dbo].[MSFT mfg demo]    Script Date: 7/24/2020 9:36:30 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MSFT mfg demo]
(
	[Timestamp] [nvarchar](4000) NULL,
	[Power] [nvarchar](4000) NULL,
	[Temperature] [nvarchar](4000) NULL,
	[SuctionPressure] [nvarchar](4000) NULL,
	[Vibration] [nvarchar](4000) NULL,
	[DischargePressure] [nvarchar](4000) NULL,
	[VibrationVelocity] [nvarchar](4000) NULL,
	[VibrationAcceleration] [nvarchar](4000) NULL,
	[AnomalyDischargeCavitation] [nvarchar](4000) NULL,
	[AnomalySealFailure] [nvarchar](4000) NULL,
	[AnomalyCouplingFailure] [nvarchar](4000) NULL,
	[UpdatedDate] [nvarchar](4000) NULL,
	[Date] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

------------------------------------------------------
/****** Object:  Table [dbo].[OperationsCaseData]    Script Date: 7/24/2020 9:37:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[OperationsCaseData]
(
	[City] [nvarchar](4000) NULL,
	[CasesCreated] [nvarchar](4000) NULL,
	[CasesResolved] [nvarchar](4000) NULL,
	[CasesCancelled] [nvarchar](4000) NULL,
	[CasesPending] [nvarchar](4000) NULL,
	[SLACompliance] [nvarchar](4000) NULL,
	[SLANonCompliance] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
--------------------------------------------------
/****** Object:  Table [dbo].[Sales]    Script Date: 7/24/2020 9:38:20 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Sales]
(
	[Date] [datetime] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[DeliveryDate] [datetime] NULL,
	[ProductId] [bigint] NOT NULL,
	[Quantity] [decimal](18, 2) NOT NULL,
	[UnitPrice] [decimal](18, 2) NOT NULL,
	[TaxAmount] [decimal](18, 2) NOT NULL,
	[TotalExcludingTax] [decimal](18, 2) NOT NULL,
	[TotalIncludingTax] [decimal](18, 2) NOT NULL,
	[GrossPrice] [decimal](18, 2) NOT NULL,
	[Discount] [decimal](18, 2) NOT NULL,
	[NetPrice] [decimal](18, 2) NOT NULL,
	[GrossRevenue] [decimal](18, 2) NOT NULL,
	[NetRevenue] [decimal](18, 2) NOT NULL,
	[COGS_PER] [decimal](18, 2) NOT NULL,
	[COGS] [decimal](18, 2) NOT NULL,
	[GrossProfit] [decimal](18, 2) NOT NULL,
	[OrderKey] [nvarchar](50) NULL,
	[SaleKey] [nvarchar](100) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CustomerId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

--------------------------------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Campaignproducts]
( 
	[Campaign] [varchar](250)  NULL,
	[ProductCategory] [varchar](250)  NULL,
	[Hashtag] [varchar](250)  NULL,
	[Counts] [varchar](250)  NULL,
	[ProductID] [int]  NULL,
	[CampaignRowKey] [varchar](20)  NULL,
	[SelectedFlag] [bit]  NULL,
	[Sentiment] [varchar](20)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
ALTER TABLE [dbo].[Campaignproducts] ADD  DEFAULT ((0)) FOR [SelectedFlag]
GO

------------------------------
/****** Object:  Table [dbo].[CampaignData]    Script Date: 7/24/2020 9:42:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CampaignData]
(
	[ID] [bigint] NOT NULL,
	[CampaignName] [varchar](18) NOT NULL,
	[CampaignTactic] [varchar](16) NOT NULL,
	[CampaignStartDate] [date] NULL,
	[Expense] [decimal](10, 2) NULL,
	[MarketingCost] [decimal](10, 2) NULL,
	[Profit] [decimal](10, 2) NULL,
	[LocationID] [bigint] NULL,
	[Revenue] [decimal](10, 2) NULL,
	[RevenueTarget] [decimal](10, 2) NULL,
	[ROI] [decimal](10, 2) NULL,
	[Status] [varchar](13) NOT NULL,
	[ProductID] [bigint] NULL,
	[Sentiment] [nvarchar](20) NULL,
	[Response] [bigint] NULL,
	[CampaignID] [bigint] NULL,
	[CampaignRowKey] [bigint] IDENTITY(1,1) NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

-------------------------------------------
/****** Object:  Table [dbo].[CampaignData_exl]    Script Date: 7/24/2020 9:43:25 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CampaignData_Bubble]
( 
	[ID] [int]  NOT NULL,
	[CampaignName] [varchar](18)  NOT NULL,
	[CampaignTactic] [varchar](16)  NOT NULL,
	[Expense] [int]  NOT NULL,
	[MarketingCost] [int]  NOT NULL,
	[Profit] [int]  NOT NULL,
	[LocationID] [int]  NOT NULL,
	[Revenue] [numeric](9,1)  NOT NULL,
	[RevenueTarget] [int]  NOT NULL,
	[ROI] [numeric](11,5)  NOT NULL,
	[Status] [varchar](13)  NOT NULL,
	[ProductID] [int]  NOT NULL,
	[Sentiment] [varchar](8)  NOT NULL,
	[Response] [varchar](4)  NOT NULL,
	[CampaignStartDate] [date]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE [dbo].[Campaignsales]
( 
	[Date] [date]  NOT NULL,
	[CustomerId] [bigint]  NOT NULL,
	[DeliveryDate] [date]  NULL,
	[ProductId] [bigint]  NOT NULL,
	[Quantity] [decimal](18,2)  NOT NULL,
	[UnitPrice] [decimal](18,2)  NOT NULL,
	[TaxAmount] [decimal](18,2)  NOT NULL,
	[TotalExcludingTax] [decimal](18,2)  NOT NULL,
	[TotalIncludingTax] [decimal](18,2)  NOT NULL,
	[GrossPrice] [decimal](18,2)  NOT NULL,
	[Discount] [decimal](18,2)  NOT NULL,
	[NetPrice] [decimal](18,2)  NOT NULL,
	[GrossRevenue] [decimal](18,2)  NOT NULL,
	[NetRevenue] [decimal](18,2)  NOT NULL,
	[COGS_PER] [decimal](18,2)  NOT NULL,
	[COGS] [decimal](18,2)  NOT NULL,
	[GrossProfit] [decimal](18,2)  NOT NULL,
	[CampaignRowKey] [bigint]  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [ProductId] ),
	CLUSTERED COLUMNSTORE INDEX
)

CREATE TABLE [dbo].[Customer]
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
	[UserName] [nvarchar](4000)  NULL,
	[Customer_type] [varchar](3)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE [dbo].[historical-data-adf]
( 
	[Timestamp] [datetime]  NULL,
	[Power] [float]  NULL,
	[Temperature] [float]  NULL,
	[SuctionPressure] [float]  NULL,
	[Vibration] [float]  NULL,
	[DischargePressure] [float]  NULL,
	[VibrationVelocity] [float]  NULL,
	[VibrationAcceleration] [float]  NULL,
	[AnomalyDischargeCavitation] [float]  NULL,
	[AnomalySealFailure] [float]  NULL,
	[AnomalyCouplingFailure] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
CREATE TABLE [dbo].[vCampaignSales]
( 
	[Year] [int]  NULL,
	[Month] [int]  NULL,
	[MonthName] [nvarchar](30)  NULL,
	[CampaignRowKey] [int]  NULL,
	[Profit] [decimal](38,2)  NULL,
	[Revenue] [decimal](38,2)  NULL,
	[QuantitySold] [decimal](38,2)  NULL,
	[cb] [bigint]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE [dbo].[CampaignData_exl]
(
	[ID] [nvarchar](4000) NULL,
	[CampaignName] [nvarchar](4000) NULL,
	[CampaignTactic] [nvarchar](4000) NULL,
	[CampaignStartDate] [nvarchar](4000) NULL,
	[Expense] [nvarchar](4000) NULL,
	[MarketingCost] [nvarchar](4000) NULL,
	[Profit] [nvarchar](4000) NULL,
	[LocationID] [nvarchar](4000) NULL,
	[Revenue] [nvarchar](4000) NULL,
	[RevenueTarget] [nvarchar](4000) NULL,
	[ROI] [nvarchar](4000) NULL,
	[Status] [nvarchar](4000) NULL,
	[ProductID] [nvarchar](4000) NULL,
	[Sentiment] [nvarchar](4000) NULL,
	[Response] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
----------------------------------------
/****** Object:  Table [dbo].[Date]    Script Date: 7/24/2020 9:44:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Date]
(
	[Date] [date] NULL,
	[Day] [int] NULL,
	[DaySuffix] [char](2) NULL,
	[DayName] [nvarchar](30) NULL,
	[DayOfWeek] [int] NULL,
	[DayOfWeekInMonth] [tinyint] NULL,
	[DayOfYear] [int] NULL,
	[IsWeekend] [int] NOT NULL,
	[Week] [int] NULL,
	[ISOweek] [int] NULL,
	[FirstOfWeek] [date] NULL,
	[LastOfWeek] [date] NULL,
	[WeekOfMonth] [tinyint] NULL,
	[Month] [int] NULL,
	[MonthName] [nvarchar](30) NULL,
	[FirstOfMonth] [date] NULL,
	[LastOfMonth] [date] NULL,
	[FirstOfNextMonth] [date] NULL,
	[LastOfNextMonth] [date] NULL,
	[Quarter] [int] NULL,
	[FirstOfQuarter] [date] NULL,
	[LastOfQuarter] [date] NULL,
	[Year] [int] NULL,
	[ISOYear] [int] NULL,
	[FirstOfYear] [date] NULL,
	[LastOfYear] [date] NULL,
	[IsLeapYear] [bit] NULL,
	[Has53Weeks] [int] NOT NULL,
	[Has53ISOWeeks] [int] NOT NULL,
	[MonthNumber] [int] NULL,
	[DateKey] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

-----------------------------------
/****** Object:  Table [dbo].[Product]    Script Date: 7/24/2020 9:45:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Product]
(
	[ProductID] [int] NOT NULL,
	[ProductCode] [nvarchar](50) NULL,
	[BarCode] [nvarchar](23) NULL,
	[Name] [nvarchar](100) NULL,
	[Description] [nvarchar](500) NULL,
	[Price] [decimal](10, 2) NULL,
	[Category] [nvarchar](20) NULL,
	[Thumbnail_FileName] [nvarchar](500) NULL,
	[AdImage_FileName] [nvarchar](500) NULL,
	[SoundFile_FileName] [nvarchar](500) NULL,
	[CreatedDate] [nvarchar](40) NULL,
	[Dimensions] [nvarchar](50) NULL,
	[Colour] [nvarchar](50) NULL,
	[Weight] [decimal](10, 2) NULL,
	[MaxLoad] [decimal](10, 2) NULL,
	[BasePrice] [int] NULL,
	[id] [int] NULL,
	[TaxRate] [int] NULL,
	[SellingPrice] [decimal](18, 2) NULL,
	[COGS_PER] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
----------------------------------------------
/****** Object:  Table [dbo].[Campaign]    Script Date: 7/24/2020 9:46:34 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Campaign]
(
	[ID] [int] NOT NULL,
	[CampaignName] [varchar](50) NULL,
	[CampaignLaunchDate] [date] NULL,
	[SortOrder] [int] NULL,
	[RevenueTarget] [decimal](15, 2) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

------------------------------------------
/****** Object:  Table [dbo].[Location]    Script Date: 7/24/2020 9:47:24 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Location]
(
	[LocationId] [bigint] NULL,
	[LocationCode] [varchar](10) NULL,
	[LocationName] [varchar](2000) NULL,
	[Country] [nvarchar](50) NULL,
	[Region] [varchar](50) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

-------------------------------------
/****** Object:  Table [dbo].[Incident Probabilities Rio and Stuttgart]    Script Date: 7/24/2020 9:47:58 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Incident Probabilities Rio and Stuttgart]
(
	[FactoryName] [nvarchar](4000) NULL,
	[FactoryLocation] [nvarchar](4000) NULL,
	[AreaName] [nvarchar](4000) NULL,
	[FloorName] [nvarchar](4000) NULL,
	[Score] [nvarchar](4000) NULL,
	[P_Incident] [nvarchar](4000) NULL,
	[Risk Category] [nvarchar](4000) NULL,
	[Goal] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

--------------------------------------------
/****** Object:  Table [dbo].[Anomaly Detection XYZ Job Movement Data]    Script Date: 7/24/2020 9:55:20 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Anomaly Detection XYZ Job Movement Data]
(
	[Date_Time] [nvarchar](4000) NULL,
	[X-Axis Job Movement ] [nvarchar](4000) NULL,
	[Y-Axis Job Movement ] [nvarchar](4000) NULL,
	[Z-Axis Job Movement ] [nvarchar](4000) NULL,
	[Longitude] [nvarchar](4000) NULL,
	[Latitude] [nvarchar](4000) NULL,
	[InstanceNum] [nvarchar](4000) NULL,
	[PC1] [nvarchar](4000) NULL,
	[PC2] [nvarchar](4000) NULL,
	[Anomaly Detected ] [nvarchar](4000) NULL,
	[Scored Probabilities] [nvarchar](4000) NULL,
	[X-Movement] [nvarchar](4000) NULL,
	[Y-Movement] [nvarchar](4000) NULL,
	[Z-Movement] [nvarchar](4000) NULL,
	[url] [nvarchar](4000) NULL,
	[Location] [nvarchar](4000) NULL,
	[Row Num] [nvarchar](4000) NULL,
	[Probability Goal] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

----------------------------------
/****** Object:  Table [dbo].[mfg-OEE-agg]    Script Date: 7/24/2020 10:16:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mfg-OEE-agg]
(
	[Date] [nvarchar](4000) NULL,
	[LocationID] [nvarchar](4000) NULL,
	[Availability] [nvarchar](4000) NULL,
	[Performance] [nvarchar](4000) NULL,
	[Quality] [nvarchar](4000) NULL,
	[OEE] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
------------------------------------
/****** Object:  Table [dbo].[mfg-Location]    Script Date: 7/24/2020 10:22:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mfg-Location]
(
	[LocationId] [bigint] NOT NULL,
	[LocationCode] [varchar](10) NULL,
	[LocationName] [varchar](2000) NULL,
	[Country] [nvarchar](50) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [LocationId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

---------------------------------------
/****** Object:  Table [dbo].[mfg-AlertAlarm]    Script Date: 7/24/2020 10:29:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mfg-AlertAlarm]
(
	[AlarmCodeId] [bigint] NOT NULL,
	[AlarmCode] [varchar](2000) NULL,
	[AlarmType] [varchar](2000) NULL,
	[Severity] [varchar](2000) NULL,
	[Description] [varchar](2000) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [AlarmCodeId] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

---------------------------------
/****** Object:  Table [dbo].[jobquality]    Script Date: 7/24/2020 10:34:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[jobquality]
(
	[jobId] [nvarchar](50) NULL,
	[good] [int] NULL,
	[snag] [int] NULL,
	[reject] [int] NULL,
	[timestamp] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

---------------------------
/****** Object:  Table [dbo].[mfg-ProductQuality]    Script Date: 7/24/2020 10:38:44 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mfg-ProductQuality]
(
	[SKUs] [nvarchar](50) NULL,
	[good] [int] NULL,
	[snag] [int] NULL,
	[reject] [int] NULL,
	[OrderQty] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

----------------------------
/****** Object:  Table [dbo].[FactoryOverviewTable]    Script Date: 7/24/2020 10:40:18 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactoryOverviewTable]
(
	[Prop_0] [nvarchar](4000) NULL,
	[Prop_1] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

-------------------------------------

