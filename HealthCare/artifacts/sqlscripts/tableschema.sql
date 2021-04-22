/****** Object:  Table [dbo].[pbiHospitalInfo]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiPatientSurvey]
(
	[id] [int] NULL,
	[survey_id] [int] NULL,
	[patient_encounter_id] [int] NULL,
	[score] [int] NULL
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

CREATE TABLE [dbo].[HighSpeedStreamingAggregate]
(
	[Dspl] [nvarchar](4000) NULL,
	[AvgTemp] [float] NULL,
	[MaxHmdt] [float] NULL,
	[PartitionId] [float] NULL
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

CREATE TABLE [dbo].[HighSpeedStreamingRaw]
(
	[Pkey] [float] NULL,
	[Time] [nvarchar](4000) NULL,
	[Dspl] [nvarchar](4000) NULL,
	[Dspl2] [nvarchar](4000) NULL,
	[Temp] [float] NULL,
	[Hmdt] [float] NULL,
	[EventProcessedUtcTime] [datetime] NULL,
	[PartitionId] [float] NULL,
	[EventEnqueuedUtcTime] [datetime] NULL
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

CREATE TABLE [dbo].[SynthiaEncounter]
(
	[Id] [nvarchar](100) NULL,
	[START] [datetime] NULL,
	[STOP] [datetime] NULL,
	[PATIENT] [nvarchar](100) NULL,
	[ORGANIZATION] [nvarchar](100) NULL,
	[PROVIDER] [nvarchar](100) NULL,
	[PAYER] [nvarchar](100) NULL,
	[ENCOUNTERCLASS] [nvarchar](100) NULL,
	[CODE] [nvarchar](100) NULL,
	[DESCRIPTION] [nvarchar](1000) NULL,
	[BASE_ENCOUNTER_COST] [float] NULL,
	[TOTAL_CLAIM_COST] [float] NULL,
	[PAYER_COVERAGE] [float] NULL,
	[REASONCODE] [nvarchar](100) NULL,
	[REASONDESCRIPTION] [nvarchar](100) NULL
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

CREATE TABLE [dbo].[SynthiaPatient]
( 
	[Id] [nvarchar](100)  NULL,
	[BIRTHDATE] [datetime]  NULL,
	[DEATHDATE] [datetime]  NULL,
	[SSN] [nvarchar](100)  NULL,
	[DRIVERS] [nvarchar](100)  NULL,
	[PASSPORT] [nvarchar](100)  NULL,
	[PREFIX] [nvarchar](20)  NULL,
	[FIRST] [nvarchar](50)  NULL,
	[LAST] [nvarchar](50)  NULL,
	[SUFFIX] [nvarchar](20)  NULL,
	[MAIDEN] [nvarchar](20)  NULL,
	[MARITAL] [nvarchar](100)  NULL,
	[RACE] [nvarchar](100)  NULL,
	[ETHNICITY] [nvarchar](100)  NULL,
	[GENDER] [nvarchar](100)  NULL,
	[BIRTHPLACE] [nvarchar](100)  NULL,
	[ADDRESS] [nvarchar](100)  NULL,
	[CITY] [nvarchar](100)  NULL,
	[STATE] [nvarchar](100)  NULL,
	[COUNTY] [nvarchar](100)  NULL,
	[ZIP] [nvarchar](100)  NULL,
	[LAT] [float]  NULL,
	[LON] [float]  NULL,
	[HEALTHCARE_EXPENSES] [float]  NULL,
	[HEALTHCARE_COVERAGE] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE SynapseLinkLabData
( 
	UpdatedOn DATETIME NULL,
	BatchId varchar(255) NULL,
	SampleAuthenticated INT NULL,
	SampleVerified INT NULL,
	SampleRejected INT NULL,
	SampleRetested INT NULL,
	Quality DECIMAL(5,2) NULL,
	PathologyProcessed DECIMAL(5,2) NULL,
	PathologyVerified DECIMAL(5,2) NULL,
	PathologyAuthenticated DECIMAL(5,2) NULL,
	RadiologyProcessed DECIMAL(5,2) NULL,
	RadiologyVerified DECIMAL(5,2) NULL,
	RadiologyAuthenticated DECIMAL(5,2) NULL,
	CardioProcessed DECIMAL(5,2) NULL,
	CardioVerified DECIMAL(5,2) NULL,
	CardioAuthenticated DECIMAL(5,2) NULL
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
CREATE TABLE [dbo].[pbiHospitalInfo]
(
	[id] [int] NULL,
	[hospital_name] [nvarchar](4000) NULL,
	[address] [nvarchar](4000) NULL,
	[state] [nvarchar](4000) NULL,
	[city] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[pbiHospitalMetaData]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pbiHospitalMetaData]
(
	[id] [int] NULL,
	[hospital_info_id] [int] NULL,
	[Departments_dept_id] [int] NULL,
	[total_doctors] [int] NULL,
	[total_nurses] [int] NULL,
	[total_beds] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[pbiPatient]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pbiPatient]
(
	[encounter_id] [int] NULL,
	[hospital_id] [int] NULL,
	[department_id] [int] NULL,
	[city] [nvarchar](500) NULL,
	[patient_id] [nvarchar](500) NULL,
	[patient_age] [int] NULL,
	[risk_level] [int] NULL,
	[acute_type] [nvarchar](500) NULL,
	[patient_category] [nvarchar](500) NULL,
	[doctor_id] [int] NULL,
	[length_of_stay] [int] NULL,
	[wait_time] [int] NULL,
	[type_of_stay] [nvarchar](500) NULL,
	[treatment_cost] [int] NULL,
	[claim_cost] [int] NULL,
	[drug_cost] [int] NULL,
	[hospital_expense] [int] NULL,
	[follow_up] [int] NULL,
	[readmitted_patient] [int] NULL,
	[payment_type] [nvarchar](1000) NULL,
	[date] [datetime] NULL,
	[month] [nvarchar](1000) NULL,
	[year] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  View [dbo].[vw_PbiBedOccupancyRate]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_PbiBedOccupancyRate]
AS (
SELECT MonthName, city as CityName, MonthNumber, (((Total_patients)*100)/30)/Total_beds as OccupancyRate FROM
(SELECT
    month as MonthName, hospital_id,DATEPART(month, [Date]) AS MonthNumber
    , COUNT(patient_category) AS total_patients
FROM
    dbo.pbiPatient
WHERE
    [Date] BETWEEN '2020-01-01' AND '2020-11-30'
    AND patient_category = 'InPatient'
GROUP BY
    month,DATEPART(month, [Date]), hospital_id) as patient_count_table
LEFT JOIN (SELECT hospital_info_id,[city],SUM([total_beds]) as total_beds
FROM [dbo].[pbiHospitalMetaData] JOIN [dbo].[pbiHospitalInfo] ON [hospital_info_id]=[dbo].[pbiHospitalInfo].[id]
GROUP BY hospital_info_id,city) as bed_count
ON bed_count.hospital_info_id = patient_count_table.hospital_id
);
GO
/****** Object:  View [dbo].[vwSynapseLinkSynapseKPIs]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwSynapseLinkSynapseKPIs]
AS SELECT
        DATEPART(HOUR, UpdatedOn) ForHour
        , AVG(Quality) AS Quality
        , AVG(SampleVerified) AS SampleVerified
        , AVG(SampleRejected) AS SampleRejected
        , AVG(SampleRetested) AS SampleRetested
    FROM
        SynapseLinkLabData
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 17
        AND DATEPART(HOUR, UpdatedOn) <= 22
    GROUP BY
        DATEPART(HOUR, UpdatedOn);
GO
/****** Object:  View [dbo].[vwSynapseLinkSynapseLast3HoursQuality]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwSynapseLinkSynapseLast3HoursQuality]
AS SELECT
        UpdatedOn
        , AVG(Quality) AS Quality
    FROM
        SynapseLinkLabData
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 20
        AND DATEPART(HOUR, UpdatedOn) <= 22
    GROUP BY
        UpdatedOn;
GO
/****** Object:  View [dbo].[vwSynapseLinkSynapseLast7HoursQualityVerified]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwSynapseLinkSynapseLast7HoursQualityVerified] AS SELECT
        LEFT(RIGHT(CONVERT(CHAR(19),UpdatedOn,100),7),2) + ':00 ' + RIGHT(RIGHT(CONVERT(CHAR(19),UpdatedOn,100),7),2) ForHours
        , AVG(Quality) AS Quality
		,AVG(SampleVerified) AS SampleVerified
    FROM
        SynapseLinkLabData
    WHERE
        DATEPART(HOUR, UpdatedOn) >= 17
        AND DATEPART(HOUR, UpdatedOn) <= 22
    GROUP BY
         LEFT(RIGHT(CONVERT(CHAR(19),UpdatedOn,100),7),2) + ':00 ' + RIGHT(RIGHT(CONVERT(CHAR(19),UpdatedOn,100),7),2);
GO
/****** Object:  View [dbo].[vwSynapseLinkSynapseWorkload]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwSynapseLinkSynapseWorkload]
AS SELECT
        BatchId
        , AVG(PathologyProcessed) AS PathologyProcessed
        , AVG(PathologyVerified) AS PathologyVerified
        , AVG(PathologyAuthenticated) AS PathologyAuthenticated
        , AVG(RadiologyProcessed) AS RadiologyProcessed
        , AVG(RadiologyVerified) AS RadiologyVerified
        , AVG(RadiologyAuthenticated) AS RadiologyAuthenticated
        , AVG(CardioProcessed) AS CardioProcessed
    FROM
        SynapseLinkLabData
    WHERE
        DATEPART(HOUR, UpdatedOn) < 23
    GROUP BY
        BatchId;
GO
/****** Object:  Table [dbo].[Campaign_Analytics]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Campaign_Analytics]
(
	[Region] [varchar](50) NULL,
	[Country] [varchar](50) NULL,
	[Campaign_Name] [varchar](50) NULL,
	[Revenue] [varchar](50) NULL,
	[Revenue_Target] [varchar](50) NULL,
	[City] [varchar](50) NULL,
	[State] [varchar](50) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[Campaign_Analytics_New]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Campaign_Analytics_New]
(
	[Region] [nvarchar](4000) NULL,
	[Country] [nvarchar](4000) NULL,
	[Campaign_Name] [nvarchar](4000) NULL,
	[Revenue] [nvarchar](4000) NULL,
	[Revenue_Target] [nvarchar](4000) NULL,
	[City] [nvarchar](4000) NULL,
	[State] [nvarchar](4000) NULL,
	[RoleID] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[Campaign_Analytics_NewUS]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Campaign_Analytics_NewUS]
(
	[Region] [nvarchar](4000) NULL,
	[Country] [nvarchar](4000) NULL,
	[Campaign_Name] [nvarchar](4000) NULL,
	[Revenue] [nvarchar](4000) NULL,
	[Revenue_Target] [nvarchar](4000) NULL,
	[City] [nvarchar](4000) NULL,
	[State] [nvarchar](4000) NULL,
	[RoleID] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[Campaignreport_Top5hospitalsbysatisfactionscore]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Campaignreport_Top5hospitalsbysatisfactionscore]
(
	[id] [int] NULL,
	[Hospital_name] [nvarchar](4000) NULL,
	[Satisfaction] [int] NULL,
	[TotalCount] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[CustomerSalesHana]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerSalesHana]
(
	[ProductKey] [nvarchar](4000) NULL,
	[OrderDateKey] [nvarchar](4000) NULL,
	[DueDateKey] [nvarchar](4000) NULL,
	[ShipDateKey] [int] NULL,
	[CustomerKey] [nvarchar](4000) NULL,
	[PromotionKey] [nvarchar](4000) NULL,
	[CurrencyKey] [nvarchar](4000) NULL,
	[SalesTerritoryKey] [nvarchar](4000) NULL,
	[SalesOrderNumber] [nvarchar](4000) NULL,
	[SalesOrderLineNumber] [nvarchar](4000) NULL,
	[RevisionNumber] [int] NULL,
	[OrderQuantity] [int] NULL,
	[UnitPrice] [float] NULL,
	[ExtendedAmount] [float] NULL,
	[UnitPriceDiscountPct] [float] NULL,
	[DiscountAmount] [float] NULL,
	[ProductStandardCost] [float] NULL,
	[TotalProductCost] [float] NULL,
	[SalesAmount] [float] NULL,
	[TaxAmt] [float] NULL,
	[Freight] [float] NULL,
	[CarrierTrackingNumber] [nvarchar](4000) NULL,
	[CustomerPONumber] [nvarchar](4000) NULL,
	[OrderDate] [int] NULL,
	[DueDate] [int] NULL,
	[ShipDate] [date] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO
/****** Object:  Table [dbo].[GlobalOverviewReport_Bed Occupancy]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GlobalOverviewReport_Bed Occupancy]
(
	[city] [nvarchar](255) NULL,
	[MonthNumber] [nvarchar](255) NULL,
	[Bed Occupancy Rate] [float] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[GlobalOverviewReport_Margin Rate]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GlobalOverviewReport_Margin Rate]
(
	[city] [nvarchar](255) NULL,
	[marginPercent] [float] NULL,
	[month] [nvarchar](255) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[GlobalOverviewReport_Patient Experience]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GlobalOverviewReport_Patient Experience]
(
	[city] [nvarchar](255) NULL,
	[Patient Experience] [float] NULL,
	[month] [nvarchar](255) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[HealthCare-FactSales]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HealthCare-FactSales]
(
	[CareManager] [nvarchar](4000) NULL,
	[PayerName] [nvarchar](4000) NULL,
	[CampaignName] [nvarchar](4000) NULL,
	[Region] [nvarchar](4000) NULL,
	[State] [nvarchar](4000) NULL,
	[City] [nvarchar](4000) NULL,
	[Revenue] [nvarchar](4000) NULL,
	[RevenueTarget] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[HealthCare-iomt-parameterized]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HealthCare-iomt-parameterized]
(
	[PatientId] [nvarchar](4000) NULL,
	[PatientAge] [nvarchar](4000) NULL,
	[BodyTemperature] [nvarchar](4000) NULL,
	[HeartRate] [nvarchar](4000) NULL,
	[BreathingRate] [nvarchar](4000) NULL,
	[numberOfSteps] [nvarchar](4000) NULL,
	[Calories] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[healthcare-pcr-json]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[healthcare-pcr-json]
(
	[pcrdata] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[healthcare-tablevalued]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[healthcare-tablevalued]
(
	[patientId] [nvarchar](4000) NULL,
	[patientAge] [nvarchar](4000) NULL,
	[datetime] [nvarchar](4000) NULL,
	[bodyTemperature] [nvarchar](4000) NULL,
	[heartRate] [nvarchar](4000) NULL,
	[breathingRate] [nvarchar](4000) NULL,
	[spo2] [nvarchar](4000) NULL,
	[systolicPressure] [nvarchar](4000) NULL,
	[diastolicPressure] [nvarchar](4000) NULL,
	[numberOfSteps] [nvarchar](4000) NULL,
	[activityTime] [nvarchar](4000) NULL,
	[numberOfTimesPersonStoodUp] [nvarchar](4000) NULL,
	[calories] [nvarchar](4000) NULL,
	[vo2] [nvarchar](4000) NULL,
	[SyntheticPartitionKey] [nvarchar](4000) NULL,
	[id] [nvarchar](4000) NULL,
	[_rid] [nvarchar](4000) NULL,
	[_self] [nvarchar](4000) NULL,
	[_etag] [nvarchar](4000) NULL,
	[_attachments] [nvarchar](4000) NULL,
	[_ts] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[Healthcare-Twitter-Data]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Healthcare-Twitter-Data]
(
	[TwitterData] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[Healthcare-Iomt-Data]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Healthcare-Iomt-Data]
(
	[numberOfSteps] [float] NULL,
	[heartrate] [float] NULL,
	[systolicPressure] [float] NULL,
	[diastolicPressure] [float] NULL,
	[calories] [float] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[HospitalEmpPIIData]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HospitalEmpPIIData]
(
	[Id] [int] NULL,
	[EmpName] [nvarchar](61) NULL,
	[Address] [nvarchar](30) NULL,
	[City] [nvarchar](30) NULL,
	[County] [nvarchar](30) NULL,
	[State] [nvarchar](10) NULL,
	[Phone] [varchar](100) NULL,
	[Email] [varchar](100) NULL,
	[Designation] [varchar](20) NULL,
	[SSN] [varchar](100) NULL,
	[SSN_encrypted] [nvarchar](100) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[Iot-Iomt-Data]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Iot-Iomt-Data]
(
	[numberOfSteps] [int] NULL,
	[heartrate] [int] NULL,
	[systolicPressure] [int] NULL,
	[diastolicPressure] [int] NULL,
	[calories] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[Miamihospitaloverview_Bed Occupancy]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Miamihospitaloverview_Bed Occupancy]
(
	[Month Name] [nvarchar](255) NULL,
	[OccupancyRate] [float] NULL,
	[Sum of OccupancyRate] [float] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[Mkt_CampaignAnalyticLatest]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mkt_CampaignAnalyticLatest]
(
	[Region] [nvarchar](4000) NULL,
	[Country] [nvarchar](4000) NULL,
	[ProductCategory] [nvarchar](4000) NULL,
	[Campaign_ID] [nvarchar](4000) NULL,
	[Campaign_Name] [nvarchar](4000) NULL,
	[Qualification] [nvarchar](4000) NULL,
	[Qualification_Number] [nvarchar](4000) NULL,
	[Response_Status] [nvarchar](4000) NULL,
	[Responses] [nvarchar](4000) NULL,
	[Cost] [nvarchar](4000) NULL,
	[Revenue] [nvarchar](4000) NULL,
	[ROI] [nvarchar](4000) NULL,
	[Lead_Generation] [nvarchar](4000) NULL,
	[Revenue_Target] [nvarchar](4000) NULL,
	[Campaign_Tactic] [nvarchar](4000) NULL,
	[Customer_Segment] [nvarchar](4000) NULL,
	[Status] [nvarchar](4000) NULL,
	[Profit] [nvarchar](4000) NULL,
	[Marketing_Cost] [nvarchar](4000) NULL,
	[CampaignID] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[Mkt_WebsiteSocialAnalyticsPBIData]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mkt_WebsiteSocialAnalyticsPBIData]
(
	[Country] [nvarchar](4000) NULL,
	[Product_Category] [nvarchar](4000) NULL,
	[Product] [nvarchar](4000) NULL,
	[Channel] [nvarchar](4000) NULL,
	[Gender] [nvarchar](4000) NULL,
	[Sessions] [nvarchar](4000) NULL,
	[Device_Category] [nvarchar](4000) NULL,
	[Sources] [nvarchar](4000) NULL,
	[Conversations] [nvarchar](4000) NULL,
	[Page] [nvarchar](4000) NULL,
	[Visits] [nvarchar](4000) NULL,
	[Unique_Visitors] [nvarchar](4000) NULL,
	[Browser] [nvarchar](4000) NULL,
	[Sentiment] [nvarchar](4000) NULL,
	[Duration_min] [nvarchar](4000) NULL,
	[Region] [nvarchar](4000) NULL,
	[Customer_Segment] [nvarchar](4000) NULL,
	[Daily_Users] [nvarchar](4000) NULL,
	[Conversion_Rate] [nvarchar](4000) NULL,
	[Return_Visitors] [nvarchar](4000) NULL,
	[Tweets] [nvarchar](4000) NULL,
	[Retweets] [nvarchar](4000) NULL,
	[Hashtags] [nvarchar](4000) NULL,
	[Campaign_Name] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[PatientInformation]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PatientInformation]
(
	[Patient Name] [nvarchar](4000) NULL,
	[Gender] [nvarchar](4000) NULL,
	[Phone] [nvarchar](4000) NULL,
	[Email] [nvarchar](4000) NULL,
	[Medical Insurance Card] [nvarchar](19) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[pbiBedOccupancyForecasted]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pbiBedOccupancyForecasted]
(
	[Date] [nvarchar](4000) NULL,
	[city] [nvarchar](4000) NULL,
	[occupancy_rate] [nvarchar](4000) NULL,
	[forecasted] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[pbiDepartment]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pbiDepartment]
(
	[dept_id] [int] NULL,
	[department_name] [nvarchar](4000) NULL,
	[department_type] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[pbiManagementEmployee]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pbiManagementEmployee]
(
	[hospital_info_id] [int] NULL,
	[management_employees] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[PbiReadmissionPrediction]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PbiReadmissionPrediction]
(
	[hospital_id] [nvarchar](4000) NULL,
	[department_id] [nvarchar](4000) NULL,
	[city] [nvarchar](4000) NULL,
	[patient_age] [int] NULL,
	[risk_level] [nvarchar](4000) NULL,
	[acute_type] [nvarchar](4000) NULL,
	[patient_category] [nvarchar](1000) NULL,
	[doctor_id] [nvarchar](4000) NULL,
	[length_of_stay] [bigint] NULL,
	[wait_time] [bigint] NULL,
	[type_of_stay] [nvarchar](4000) NULL,
	[treatment_cost] [bigint] NULL,
	[claim_cost] [bigint] NULL,
	[drug_cost] [bigint] NULL,
	[hospital_expense] [bigint] NULL,
	[follow_up] [nvarchar](4000) NULL,
	[readmitted_patient] [nvarchar](4000) NULL,
	[payment_type] [nvarchar](4000) NULL,
	[date] [nvarchar](4000) NULL,
	[month] [nvarchar](4000) NULL,
	[year] [nvarchar](4000) NULL,
	[disease] [nvarchar](4000) NULL,
	[reason_for_readmission] [nvarchar](4000) NULL,
	[Actual_Flag] [nvarchar](4000) NULL,
	[Predicted_Flag] [nvarchar](4000) NULL,
	[Prediction_Probability] [decimal](38, 18) NULL,
	[Actual_Readmission_Rate] [decimal](38, 18) NULL,
	[Predicted_Readmission_Rate] [decimal](38, 18) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[PbiWaitTimeForecast]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PbiWaitTimeForecast]
(
	[date] [nvarchar](4000) NULL,
	[wait_time] [nvarchar](4000) NULL,
	[city] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[pred_anomaly]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pred_anomaly]
(
	[Date_Time] [datetime2](7) NULL,
	[PrincipalComponent1] [bigint] NULL,
	[PrincipalComponent2] [bigint] NULL,
	[PrincipalComponent3] [bigint] NULL,
	[Longitude] [decimal](38, 18) NULL,
	[Latitude] [decimal](38, 18) NULL,
	[PatientID] [nvarchar](4000) NULL,
	[Anomaly Detected ] [nvarchar](4000) NULL,
	[Scored Probabilities] [decimal](38, 18) NULL,
	[PC1] [decimal](38, 18) NULL,
	[PC2] [decimal](38, 18) NULL,
	[PC3] [decimal](38, 18) NULL,
	[url] [nvarchar](4000) NULL,
	[Location] [nvarchar](4000) NULL,
	[Row Num] [nvarchar](4000) NULL,
	[Probability Goal] [decimal](38, 18) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[RoleNew]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RoleNew]
(
	[RoleID] [nvarchar](4000) NULL,
	[Name] [nvarchar](4000) NULL,
	[Email] [nvarchar](4000) NULL,
	[Roles] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[SynCondition]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SynCondition]
(
	[START] [nvarchar](4000) NULL,
	[STOP] [nvarchar](4000) NULL,
	[PATIENT] [nvarchar](4000) NULL,
	[ENCOUNTER] [nvarchar](4000) NULL,
	[CODE] [nvarchar](4000) NULL,
	[DESCRIPTION] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[SynObservation]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SynObservation]
(
	[DATE] [nvarchar](4000) NULL,
	[PATIENT] [nvarchar](4000) NULL,
	[ENCOUNTER] [nvarchar](4000) NULL,
	[CODE] [nvarchar](4000) NULL,
	[DESCRIPTION] [nvarchar](4000) NULL,
	[VALUE] [nvarchar](4000) NULL,
	[UNITS] [nvarchar](4000) NULL,
	[TYPE] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[SynPatient]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SynPatient]
(
	[Id] [nvarchar](4000) NULL,
	[BIRTHDATE] [nvarchar](4000) NULL,
	[DEATHDATE] [nvarchar](4000) NULL,
	[SSN] [nvarchar](4000) NULL,
	[DRIVERS] [nvarchar](4000) NULL,
	[PASSPORT] [nvarchar](4000) NULL,
	[PREFIX] [nvarchar](4000) NULL,
	[FIRST] [nvarchar](4000) NULL,
	[LAST] [nvarchar](4000) NULL,
	[SUFFIX] [nvarchar](4000) NULL,
	[MAIDEN] [nvarchar](4000) NULL,
	[MARITAL] [nvarchar](4000) NULL,
	[RACE] [nvarchar](4000) NULL,
	[ETHNICITY] [nvarchar](4000) NULL,
	[GENDER] [nvarchar](4000) NULL,
	[BIRTHPLACE] [nvarchar](4000) NULL,
	[ADDRESS] [nvarchar](4000) NULL,
	[CITY] [nvarchar](4000) NULL,
	[STATE] [nvarchar](4000) NULL,
	[COUNTY] [nvarchar](4000) NULL,
	[ZIP] [nvarchar](4000) NULL,
	[LAT] [nvarchar](4000) NULL,
	[LON] [nvarchar](4000) NULL,
	[HEALTHCARE_EXPENSES] [nvarchar](4000) NULL,
	[HEALTHCARE_COVERAGE] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO
/****** Object:  Table [dbo].[USHeaderMapReport]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USHeaderMapReport]
(
	[City] [nvarchar](255) NULL,
	[Total Patients] [float] NULL,
	[Number of Patients] [float] NULL,
	[Rating] [nvarchar](255) NULL,
	[OccupancyRate%] [float] NULL,
	[Margin] [float] NULL,
	[Readmission Rate] [float] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

/****** Object:  Table [dbo].[Observations]    Script Date: 29-01-2021 00:27:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Observations]
( 
	[DATE] [datetime]  NULL,
	[PATIENT] [nvarchar](100)  NULL,
	[ENCOUNTER] [nvarchar](100)  NULL,
	[CODE] [nvarchar](50)  NULL,
	[DESCRIPTION] [nvarchar](500)  NULL,
	[VALUE] [nvarchar](100)  NULL,
	[UNITS] [nvarchar](50)  NULL,
	[TYPE] [nvarchar](10)  NULL,
	[IsOrignal] [bit]  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [ENCOUNTER] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

/****** Object:  Table [dbo].[SynEncounter]    Script Date: 29-01-2021 00:27:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SynEncounter]
(
	[Id] [nvarchar](100) NULL,
	[START] [datetime] NULL,
	[PATIENT] [nvarchar](100) NULL,
	[ENCOUNTERCLASS] [nvarchar](100) NULL,
	[TOTAL_CLAIM_COST] [float] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

/****** Object:  Table [dbo].[SynPatientsFinal]    Script Date: 29-01-2021 00:32:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SynPatientsFinal]
(
	[Id] [nvarchar](4000) NULL,
	[City] [nvarchar](4000) NULL,
	[State] [nvarchar](4000) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

/****** Object:  StoredProcedure [dbo].[CLS_ChiefOperatingManager]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CLS_ChiefOperatingManager] AS 
Revert;
GRANT SELECT ON Campaign_Analytics TO ChiefOperatingManager;  --Full access to all columns.
-- Step:6 Let us check if our ChiefOperatingManager user can see all the information that is present. Assign Current User As 'CEO' and the execute the query
EXECUTE AS USER ='ChiefOperatingManager'
select * from Campaign_Analytics
GO
/****** Object:  StoredProcedure [dbo].[CLS_DAM_AC_New]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CLS_DAM_AC_New] AS 
GRANT SELECT ON Campaign_Analytics([Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State]) TO CareManagerMiami;
EXECUTE AS USER ='CareManagerMiami'
select [Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State] from Campaign_Analytics
GO
/****** Object:  StoredProcedure [dbo].[CLS_DAM_F_New]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CLS_DAM_F_New] AS 
BEGIN TRY
-- Generate a divide-by-zero error  
	
		GRANT SELECT ON Campaign_Analytics([Region],[Country],[Campaign_Name],[Revenue_Target],[CITY],[State]) TO CareManagerMiami;
		EXECUTE AS USER ='CareManagerMiami'
		select * from Campaign_Analytics
END TRY
BEGIN CATCH
	SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		
		ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO
/****** Object:  StoredProcedure [dbo].[Sp_HealthCareRLS]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_HealthCareRLS] AS 
Begin	
	-- After creating the users, read access is provided to all three users on FactSales table
	GRANT SELECT ON [HealthCare-FactSales] TO ChiefOperatingManager, CareManagerMiami, CareManagerLosAngeles;  

	IF EXISts (SELECT 1 FROM sys.security_predicates sp where sp.predicate_definition='([Security].[fn_securitypredicate]([SalesRep]))')
	BEGIN
		DROP SECURITY POLICY SalesFilter;
		DROP FUNCTION Security.fn_securitypredicate;
	END
	
	IF  EXISTS (SELECT * FROM sys.schemas where name='Security')
	BEGIN	
	DROP SCHEMA Security;
	End
	
	/* Moving ahead, we Create a new schema, and an inline table-valued function. 
	The function returns 1 when a row in the SalesRep column is the same as the user executing the query (@SalesRep = USER_NAME())
	or if the user executing the query is the Manager user (USER_NAME() = 'ChiefOperatingManager').
	*/
end
GO
/****** Object:  StoredProcedure [dbo].[SP_RLS_CareManagerLosAngeles]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SP_RLS_CareManagerLosAngeles] AS
EXECUTE AS USER = 'CareManagerLosAngeles'; 
SELECT * FROM [HealthCare-FactSales];
revert;
GO
/****** Object:  StoredProcedure [dbo].[SP_RLS_CareManagerMiami]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SP_RLS_CareManagerMiami] AS
EXECUTE AS USER = 'CareManagerMiami' 
SELECT * FROM [HealthCare-FactSales];
revert;
GO
/****** Object:  StoredProcedure [dbo].[SP_RLS_ChiefOperatingManager]    Script Date: 12/22/2020 12:52:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SP_RLS_ChiefOperatingManager] AS
EXECUTE AS USER = 'ChiefOperatingManager';  
SELECT * FROM [HealthCare-FactSales];
revert;
GO
/****** Object:  StoredProcedure [dbo].[Confirm DDM]    Script Date: 30-12-2020 15:20:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Confirm DDM] AS 
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl   ON c.[object_id] = tbl.[object_id]  WHERE is_masked = 1;
