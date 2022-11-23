SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AvgDailyRidership]
( 
	[CityID] [nvarchar](max)  NULL,
	[Year] [nvarchar](max)  NULL,
	[Day] [nvarchar](max)  NULL,
	[Ridership] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Facility-FactSales]
( 
	[Designation] [nvarchar](max)  NULL,
	[PayerName] [nvarchar](max)  NULL,
	[CampaignName] [nvarchar](max)  NULL,
	[Region] [nvarchar](max)  NULL,
	[State] [nvarchar](max)  NULL,
	[City] [nvarchar](max)  NULL,
	[Revenue] [nvarchar](max)  NULL,
	[RevenueTarget] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[FacilityInfo]
( 
	[FacilityName] [nvarchar](max)  NULL,
	[location] [nvarchar](max)  NULL,
	[Phone] [nvarchar](max)  NULL,
	[Email] [nvarchar](max)  NULL,
	[FacilitySecurityNumber] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Fact_Airquality]
( 
	[deploymentName] [nvarchar](20)  NULL,
	[msrDeviceNbr] [int]  NULL,
	[readingDateTimeLocal] [datetime]  NULL,
	[latitude] [nvarchar](20)  NULL,
	[longitude] [nvarchar](20)  NULL,
	[tempC] [nvarchar](20)  NULL,
	[humidity] [nvarchar](20)  NULL,
	[pressure] [nvarchar](20)  NULL,
	[pM25] [nvarchar](20)  NULL,
	[pM10] [nvarchar](20)  NULL,
	[pM1] [nvarchar](20)  NULL,
	[aqi] [int]  NULL
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

CREATE TABLE [dbo].[Fact_Airqualitydetails]
( 
	[deploymentName] [nvarchar](20)  NULL,
	[msrDeviceNbr] [int]  NULL,
	[readingDateTimeLocal] [datetime]  NULL,
	[latitude] [nvarchar](20)  NULL,
	[longitude] [nvarchar](20)  NULL,
	[tempC] [nvarchar](20)  NULL,
	[humidity] [nvarchar](20)  NULL,
	[pressure] [nvarchar](20)  NULL,
	[pM25] [nvarchar](20)  NULL,
	[pM10] [nvarchar](20)  NULL,
	[pM1] [nvarchar](20)  NULL,
	[aqi] [int]  NULL
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

CREATE TABLE [dbo].[Fact_ArticlePublished]
( 
	[Month/year] [date]  NULL,
	[Articles published (Positive)] [int]  NULL,
	[Articles published (Negative)] [int]  NULL
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

CREATE TABLE [dbo].[Fact_Citizensentimentdetail]
( 
	[Date] [datetime]  NULL,
	[Year] [int]  NULL,
	[Months] [int]  NULL,
	[Social Sentiment score %] [nvarchar](10)  NULL,
	[Governance Sentiment Score] [nvarchar](10)  NULL,
	[Environment Sentiment Score] [nvarchar](10)  NULL,
	[Facilities (power) Management Score] [nvarchar](10)  NULL,
	[Articles published (Positive)] [int]  NULL,
	[Articles published (Negative)] [int]  NULL,
	[Resolved] [int]  NULL,
	[Requests] [int]  NULL,
	[Sentiment] [nvarchar](10)  NULL
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

CREATE TABLE [dbo].[Fact_Citizensentimentsummmary]
( 
	[Month] [nvarchar](max)  NULL,
	[Vehicle Maintenance Sentiment] [nvarchar](max)  NULL,
	[Air Quality Sentiment] [nvarchar](max)  NULL,
	[Articles published] [nvarchar](max)  NULL,
	[Sentiment Transport] [nvarchar](max)  NULL,
	[OpenServiceRequest] [nvarchar](max)  NULL,
	[ClosedServiceRequest] [nvarchar](max)  NULL,
	[Falling behind Service compliance] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Fact_Eneryconsumptionsdetails]
( 
	[ID] [nvarchar](max)  NULL,
	[StartOfMonth] [nvarchar](max)  NULL,
	[FacilityGasCost ] [nvarchar](max)  NULL,
	[FacilityPowerConsumptionKWH] [nvarchar](max)  NULL,
	[FleetFuelCost] [nvarchar](max)  NULL,
	[FleetServicingCost] [nvarchar](max)  NULL,
	[TransortationFuelCost] [nvarchar](max)  NULL,
	[TransortationServicingCost] [nvarchar](max)  NULL,
	[Months] [nvarchar](max)  NULL,
	[Year] [nvarchar](max)  NULL,
	[BudgetPowerConKWH] [money]  NULL,
	[GasCostBudget] [money]  NULL
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

CREATE TABLE [dbo].[Fact_FacilityManagementdetails]
( 
	[BuildingId] [nvarchar](max)  NULL,
	[Department] [nvarchar](max)  NULL,
	[BuildingType] [nvarchar](max)  NULL,
	[Date] [nvarchar](max)  NULL,
	[KWhConsumed] [nvarchar](max)  NULL,
	[ElecCostAmt] [nvarchar](max)  NULL,
	[Gas Usage] [nvarchar](max)  NULL,
	[GasCostAmount] [nvarchar](max)  NULL,
	[TotalCostELecGas] [nvarchar](max)  NULL,
	[Numb of facilities with Gas] [nvarchar](max)  NULL,
	[TotalCostELec] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Fact_Fleetmaintenancecost]
( 
	[CityID] [nvarchar](max)  NULL,
	[Month] [nvarchar](max)  NULL,
	[EMS] [nvarchar](max)  NULL,
	[Police] [nvarchar](max)  NULL,
	[Fire Truck] [nvarchar](max)  NULL,
	[Utility Vehicle] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Fact_Fleetmanagementdetails]
( 
	[VehicleID] [varchar](30)  NULL,
	[Fueltype] [nvarchar](50)  NULL,
	[Mileage] [float]  NULL,
	[Date] [datetime]  NULL,
	[Distance] [float]  NULL,
	[CO2Emission(kg)] [nvarchar](50)  NULL,
	[FuelConsumption] [float]  NULL,
	[Vehicle Type] [nvarchar](100)  NULL,
	[Year] [int]  NULL,
	[Months] [int]  NULL,
	[FuelCost] [float]  NULL,
	[TranFuelBudget] [float]  NULL,
	[CostOverrun] [nvarchar](50)  NULL,
	[FleetFlueCost] [money]  NULL,
	[FleetServicingCost] [money]  NULL,
	[TransortationFuelCost] [money]  NULL,
	[TransortationServicingCost] [money]  NULL,
	[NoOfStops] [int]  NULL,
	[NoOfVehicleserviceMonth] [int]  NULL,
	[TargetNoOfVehicleserviceMonth] [int]  NULL,
	[VehicleservicedYear] [int]  NULL,
	[TargetVehicleservicedYear] [int]  NULL,
	[%VehicleserviceMonth] [float]  NULL,
	[%GoalVehicleserviceMonth] [float]  NULL,
	[%VehicleserviceYear] [float]  NULL,
	[%GoalVehicleserviceYear] [float]  NULL,
	[AvgRouteAdherance] [float]  NULL,
	[TargetAvgRouteAdherance] [float]  NULL,
	[WaitTimeBusStopsinMin] [int]  NULL,
	[GOALWaitTimeBusStopsinMin] [int]  NULL,
	[VehicleBreakdown] [int]  NULL,
	[VehicleMaintenanceCost] [money]  NULL,
	[Service Cost] [money]  NULL,
	[BudgetServiceCost] [money]  NULL
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

CREATE TABLE [dbo].[Fact_TransportMaintenanceCost]
( 
	[Months] [nvarchar](max)  NULL,
	[Service Cost] [nvarchar](max)  NULL,
	[Mini Bus] [nvarchar](max)  NULL,
	[Bus] [nvarchar](max)  NULL,
	[e Bus] [nvarchar](max)  NULL,
	[BudgetServiceCost] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Fact_VehicleBreakdown]
( 
	[Month] [nvarchar](max)  NULL,
	[Vehicle Break down] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Fact_VehicleManufacturingData]
( 
	[DateOfManufacturing] [nvarchar](max)  NULL,
	[Dept] [nvarchar](max)  NULL,
	[fueltype] [nvarchar](max)  NULL,
	[manufacturer] [nvarchar](max)  NULL,
	[Recommended Service] [nvarchar](max)  NULL,
	[VehicleID] [nvarchar](max)  NULL,
	[Vehicle Type] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Fact_vehiclesdetails]
( 
	[VehicleID] [nvarchar](max)  NULL,
	[Fueltype] [nvarchar](max)  NULL,
	[Mileage] [nvarchar](max)  NULL,
	[Date] [nvarchar](max)  NULL,
	[Distance] [nvarchar](max)  NULL,
	[CO2Emission(kg)] [nvarchar](max)  NULL,
	[FuelConsumption] [nvarchar](max)  NULL,
	[Vehicle Type] [nvarchar](max)  NULL,
	[Year] [nvarchar](max)  NULL,
	[Months] [nvarchar](max)  NULL,
	[FuelCost] [nvarchar](max)  NULL,
	[TranFuelBudget] [nvarchar](max)  NULL,
	[CostOverrun] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Fact_VehicleServicingTrend]
( 
	[Month/year] [date]  NULL,
	[Service Due Vehicle] [float]  NULL,
	[MPG] [float]  NULL,
	[Before] [float]  NULL,
	[Mid] [float]  NULL,
	[After] [float]  NULL
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

CREATE TABLE [dbo].[Fact_VehicleServicingTrend_old]
( 
	[Month/year] [date]  NULL,
	[Service Due Vehicle] [float]  NULL,
	[MPG] [float]  NULL,
	[Before] [float]  NULL,
	[Mid] [float]  NULL,
	[After] [float]  NULL
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

CREATE TABLE [dbo].[Fleet-FactExpense]
( 
	[VehicleID] [varchar](30)  NULL,
	[Fueltype] [nvarchar](50)  NULL,
	[Vehicle Type] [nvarchar](100)  NULL,
	[FleetFlueCost] [money]  NULL,
	[FleetServicingCost] [money]  NULL,
	[TransortationFuelCost] [money]  NULL,
	[TransortationServicingCost] [money]  NULL,
	[City] [varchar](50)  NOT NULL,
	[Designation] [varchar](100)  NULL
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

CREATE TABLE [dbo].[KPIsValuesFleetManager]
( 
	[CityID] [nvarchar](max)  NULL,
	[Month] [nvarchar](max)  NULL,
	[KPIName] [nvarchar](max)  NULL,
	[Values] [nvarchar](max)  NULL,
	[Goal] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[KPIsValuesFleetManager_old]
( 
	[CityID] [nvarchar](max)  NULL,
	[Month] [nvarchar](max)  NULL,
	[KPIName] [nvarchar](max)  NULL,
	[Values] [nvarchar](max)  NULL,
	[Goal] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[PowerManagement]
( 
	[BuildingId] [nvarchar](max)  NULL,
	[BuildingType] [nvarchar](max)  NULL,
	[Department] [nvarchar](max)  NULL,
	[MonthOfConsuption] [date]  NULL,
	[KWhConsumed] [float]  NULL,
	[ElecCostAmt] [float]  NULL,
	[GasUsage] [float]  NULL,
	[GasCost] [float]  NULL,
	[IsAutoPowerOff] [nvarchar](max)  NULL,
	[IsSensors] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[RealtimeAIRQualityAPI]
( 
	[mean_AQI] [nvarchar](max)  NULL,
	[mean_AQI_before] [nvarchar](max)  NULL,
	[mean_AQI_mid] [nvarchar](max)  NULL,
	[mean_AQI_Target] [nvarchar](max)  NULL,
	[mean_PM1] [nvarchar](max)  NULL,
	[mean_PM1_before] [nvarchar](max)  NULL,
	[mean_PM1_mid] [nvarchar](max)  NULL,
	[mean_PM1_Target] [nvarchar](max)  NULL,
	[mean_PM10_before] [nvarchar](max)  NULL,
	[mean_PM10] [nvarchar](max)  NULL,
	[mean_PM10_mid] [nvarchar](max)  NULL,
	[mean_PM10_Target] [nvarchar](max)  NULL,
	[mean_PM25] [nvarchar](max)  NULL,
	[mean_PM25_before] [nvarchar](max)  NULL,
	[ReadingDateTimeUTC] [nvarchar](max)  NULL,
	[mean_PM25_Target] [nvarchar](max)  NULL,
	[mean_PM25_mid] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[TweeterSentiments]
( 
	[City] [nvarchar](max)  NULL,
	[Hashtag] [nvarchar](max)  NULL,
	[HourOfDay] [nvarchar](max)  NULL,
	[IsRetweet] [nvarchar](max)  NULL,
	[Language] [nvarchar](max)  NULL,
	[Sentiment] [nvarchar](max)  NULL,
	[SentimentScore] [nvarchar](max)  NULL,
	[Tweet] [nvarchar](max)  NULL,
	[UserName] [nvarchar](max)  NULL,
	[Time] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[TweeterUserInfo]
( 
	[UserName] [nvarchar](max)  NULL,
	[Gender] [nvarchar](max)  NULL,
	[Phone] [nvarchar](max)  NULL,
	[Email] [nvarchar](max)  NULL,
	[Hashtag] [nvarchar](max)  NULL,
	[HourOfDay] [nvarchar](max)  NULL,
	[Sentiment] [nvarchar](max)  NULL,
	[SentimentScore] [nvarchar](max)  NULL,
	[Time] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[twitterRawData]
( 
	[ID] [varchar](8000)  NULL,
	[TwitterData] [varchar](8000)  NULL
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

CREATE TABLE [dbo].[twitterRawData_old]
( 
	[ID] [varchar](8000)  NULL,
	[TwitterData] [varchar](8000)  NULL
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

CREATE TABLE [dbo].[Vehicle_Analytics]
( 
	[VehicleID] [nvarchar](max)  NULL,
	[VIN] [nvarchar](max)  NULL,
	[Fueltype] [nvarchar](max)  NULL,
	[Mileage] [nvarchar](max)  NULL,
	[Year] [nvarchar](max)  NULL,
	[Months] [nvarchar](max)  NULL,
	[Distance] [nvarchar](max)  NULL,
	[FuelConsumption] [nvarchar](max)  NULL,
	[CO2Emission(kg)] [nvarchar](max)  NULL,
	[Date] [nvarchar](max)  NULL,
	[FuelCost] [nvarchar](max)  NULL,
	[VehicleType] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[VehicleBreakDown]
( 
	[VehicleID] [nvarchar](max)  NULL,
	[Date] [nvarchar](max)  NULL,
	[BreakDown] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[VehicleBreakDown_old]
( 
	[VehicleID] [nvarchar](max)  NULL,
	[Date] [nvarchar](max)  NULL,
	[BreakDown] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[VehicleDetails]
( 
	[VehicleID] [nvarchar](max)  NULL,
	[Fueltype] [nvarchar](max)  NULL,
	[Mileage] [nvarchar](max)  NULL,
	[Year] [nvarchar](max)  NULL,
	[Months] [nvarchar](max)  NULL,
	[Distance] [nvarchar](max)  NULL,
	[FuelConsumption] [nvarchar](max)  NULL,
	[CO2Emission(kg)] [nvarchar](max)  NULL,
	[Date] [nvarchar](max)  NULL,
	[FuelCost] [nvarchar](max)  NULL,
	[VehicleType] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[VehicleDetails_old]
( 
	[VehicleID] [nvarchar](max)  NULL,
	[Fueltype] [nvarchar](max)  NULL,
	[Mileage] [nvarchar](max)  NULL,
	[Year] [nvarchar](max)  NULL,
	[Months] [nvarchar](max)  NULL,
	[Distance] [nvarchar](max)  NULL,
	[FuelConsumption] [nvarchar](max)  NULL,
	[CO2Emission(kg)] [nvarchar](max)  NULL,
	[Date] [nvarchar](max)  NULL,
	[FuelCost] [nvarchar](max)  NULL,
	[VehicleType] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[VehicleServiceLog]
( 
	[VehicleID] [nvarchar](max)  NULL,
	[Fueltype] [nvarchar](max)  NULL,
	[Year] [int]  NULL,
	[ServiceDueOn] [date]  NULL,
	[ServiceDelayedBy] [int]  NULL,
	[ServicedOn] [date]  NULL,
	[DelayCounter] [int]  NULL,
	[Month] [int]  NULL,
	[DateToday] [date]  NULL,
	[Compliance] [nvarchar](max)  NULL,
	[VehicleMaintenanceCost] [float]  NULL
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

CREATE TABLE [dbo].[VehicleServiceLog_old]
( 
	[VehicleID] [nvarchar](max)  NULL,
	[ServiceDueOn] [nvarchar](max)  NULL,
	[ServicedOn] [nvarchar](max)  NULL,
	[ServiceDelayedBy] [nvarchar](max)  NULL,
	[VehicleMaintenanceCost] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[aqi_test_df]
( 
	[ds] [nvarchar](max)  NULL,
	[y] [nvarchar](max)  NULL,
	[tempC] [nvarchar](max)  NULL,
	[humidity] [nvarchar](max)  NULL,
	[pressure] [nvarchar](max)  NULL,
	[pM25] [nvarchar](max)  NULL,
	[pM10] [nvarchar](max)  NULL,
	[pM1] [nvarchar](max)  NULL
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

CREATE VIEW [dbo].[VehicleServiceLogDetails]
AS select 
 vd.[VehicleID]
    ,vd.[Fueltype]
    ,vd.[Mileage]
 	,vd.[Date] AS TransactionDate
    ,vd.[Year]
    ,vd.[Months]
    ,vd.[Distance]
    ,vd.[FuelConsumption]
    ,vd.[CO2Emission(kg)]
    ,vd.[FuelCost]
    ,vd.[VehicleType]
	,sl.[ServiceDueOn]
    ,sl.[ServiceDelayedBy]
    ,sl.[ServicedOn]
    ,sl.[DelayCounter]
    ,sl.[Compliance]
    ,sl.[VehicleMaintenanceCost]
from VehicleDetails vd
Left Join VehicleServiceLog sl on vd.VehicleID=sl.VehicleID and cast (vd.[Date] as [Date]) = cast (sl.[DateToday] as Date);
GO
