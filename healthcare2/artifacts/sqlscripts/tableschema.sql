SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Campaign_Analytics]
( 
	[Region] [varchar](50)  NULL,
	[Country] [varchar](50)  NULL,
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
	[Region] [nvarchar](4000)  NULL,
	[Country] [nvarchar](4000)  NULL,
	[Campaign_Name] [nvarchar](4000)  NULL,
	[Revenue] [nvarchar](4000)  NULL,
	[Revenue_Target] [nvarchar](4000)  NULL,
	[City] [nvarchar](4000)  NULL,
	[State] [nvarchar](4000)  NULL,
	[RoleID] [nvarchar](4000)  NULL
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

CREATE TABLE [dbo].[City and Race Data]
( 
	[ID] [nvarchar](max)  NULL,
	[City] [nvarchar](max)  NULL,
	[disease] [nvarchar](max)  NULL,
	[month] [nvarchar](max)  NULL,
	[patient_category] [nvarchar](max)  NULL,
	[prescription_rejection_rate] [nvarchar](max)  NULL,
	[Race] [nvarchar](max)  NULL,
	[readmission_rate] [nvarchar](max)  NULL,
	[reason_for_prescription_not_taken] [nvarchar](max)  NULL,
	[year] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Claim]
( 
	[<referenceId>] [nvarchar](max)  NULL,
	[Claim Date] [nvarchar](max)  NULL,
	[Claim Id] [nvarchar](max)  NULL,
	[Claim Time] [nvarchar](max)  NULL,
	[created] [nvarchar](max)  NULL,
	[Custom Url] [nvarchar](max)  NULL,
	[display] [nvarchar](max)  NULL,
	[End of billablePeriod] [nvarchar](max)  NULL,
	[id] [nvarchar](max)  NULL,
	[Insurance Coverage] [nvarchar](max)  NULL,
	[item.diagnosisSequence] [nvarchar](max)  NULL,
	[item.informationSequence] [nvarchar](max)  NULL,
	[item.net.currency] [nvarchar](max)  NULL,
	[item.net.value] [nvarchar](max)  NULL,
	[item.procedureSequence] [nvarchar](max)  NULL,
	[Measure % Claim Clearance] [nvarchar](max)  NULL,
	[Patient Id Number] [nvarchar](max)  NULL,
	[prescription.reference] [nvarchar](max)  NULL,
	[priority.coding.code] [nvarchar](max)  NULL,
	[provider.display] [nvarchar](max)  NULL,
	[reference] [nvarchar](max)  NULL,
	[Start of billablePeriod] [nvarchar](max)  NULL,
	[total.currency] [nvarchar](max)  NULL,
	[total.value] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Diagnostic Report]
( 
	[id] [nvarchar](max)  NULL,
	[<referenceId>] [nvarchar](max)  NULL,
	[conclusion] [nvarchar](max)  NULL,
	[conclusionCode.coding.code] [nvarchar](max)  NULL,
	[conclusionCode.coding.display] [nvarchar](max)  NULL,
	[Custom Url] [nvarchar](max)  NULL,
	[effective.dateTime] [nvarchar](max)  NULL,
	[encounter.reference] [nvarchar](max)  NULL,
	[imagingStudy.display] [nvarchar](max)  NULL,
	[implicitRules] [nvarchar](max)  NULL,
	[Index] [nvarchar](max)  NULL,
	[issued] [nvarchar](max)  NULL,
	[language] [nvarchar](max)  NULL,
	[status] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Document Reference]
( 
	[<referenceId>] [nvarchar](max)  NULL,
	[code] [nvarchar](max)  NULL,
	[code.1] [nvarchar](max)  NULL,
	[Combined] [nvarchar](max)  NULL,
	[Converted Data] [nvarchar](max)  NULL,
	[Custom IFrame] [nvarchar](max)  NULL,
	[data] [nvarchar](max)  NULL,
	[date] [nvarchar](max)  NULL,
	[display] [nvarchar](max)  NULL,
	[display.1] [nvarchar](max)  NULL,
	[docStatus] [nvarchar](max)  NULL,
	[Encounter Reference] [nvarchar](max)  NULL,
	[id] [nvarchar](max)  NULL,
	[lastUpdated] [nvarchar](max)  NULL,
	[Patient ID] [nvarchar](max)  NULL,
	[Patient Id Number] [nvarchar](max)  NULL,
	[Practitioner Name] [nvarchar](max)  NULL,
	[Practitioner Reference] [nvarchar](max)  NULL,
	[status] [nvarchar](max)  NULL,
	[Vitals Reason/Code/Name] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[dump]
( 
	[<referenceId>] [nvarchar](max)  NULL,
	[Age] [nvarchar](max)  NULL,
	[Birthdate] [nvarchar](max)  NULL,
	[gender] [nvarchar](max)  NULL,
	[lastUpdated] [nvarchar](max)  NULL,
	[Patient First Name] [nvarchar](max)  NULL,
	[Patient Last Name] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[encounter]
( 
	[<referenceId>] [nvarchar](max)  NULL,
	[id] [nvarchar](max)  NULL,
	[implicitRules] [nvarchar](max)  NULL,
	[Index_Column] [nvarchar](max)  NULL,
	[language] [nvarchar](max)  NULL,
	[Next 10] [nvarchar](max)  NULL,
	[participant.individual.display] [nvarchar](max)  NULL,
	[Participant.period.end] [nvarchar](max)  NULL,
	[participant.period.start] [nvarchar](max)  NULL,
	[participant.type.text] [nvarchar](max)  NULL,
	[Reason] [nvarchar](max)  NULL,
	[serviceProvider.display] [nvarchar](max)  NULL,
	[status] [nvarchar](max)  NULL,
	[subject.display] [nvarchar](max)  NULL,
	[subject.reference] [nvarchar](max)  NULL,
	[type.coding.code] [nvarchar](max)  NULL,
	[type.coding.display] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[HealthCare-FactSales]
( 
	[CareManager] [nvarchar](4000)  NULL,
	[PayerName] [nvarchar](4000)  NULL,
	[CampaignName] [nvarchar](4000)  NULL,
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

CREATE TABLE [dbo].[healthcare-pcr-json]
( 
	[pcrdata] [nvarchar](4000)  NULL
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

CREATE TABLE [dbo].[healthcare-tablevalued]
( 
	[patientId] [nvarchar](4000)  NULL,
	[patientAge] [nvarchar](4000)  NULL,
	[datetime] [nvarchar](4000)  NULL,
	[bodyTemperature] [nvarchar](4000)  NULL,
	[heartRate] [nvarchar](4000)  NULL,
	[breathingRate] [nvarchar](4000)  NULL,
	[spo2] [nvarchar](4000)  NULL,
	[systolicPressure] [nvarchar](4000)  NULL,
	[diastolicPressure] [nvarchar](4000)  NULL,
	[numberOfSteps] [nvarchar](4000)  NULL,
	[activityTime] [nvarchar](4000)  NULL,
	[numberOfTimesPersonStoodUp] [nvarchar](4000)  NULL,
	[calories] [nvarchar](4000)  NULL,
	[vo2] [nvarchar](4000)  NULL,
	[SyntheticPartitionKey] [nvarchar](4000)  NULL,
	[id] [nvarchar](4000)  NULL,
	[_rid] [nvarchar](4000)  NULL,
	[_self] [nvarchar](4000)  NULL,
	[_etag] [nvarchar](4000)  NULL,
	[_attachments] [nvarchar](4000)  NULL,
	[_ts] [nvarchar](4000)  NULL
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

CREATE TABLE [dbo].[Healthcare-Twitter-Data]
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

CREATE TABLE [dbo].[HospitalEmpPIIData]
( 
	[Id] [int]  NULL,
	[EmpName] [nvarchar](61)  NULL,
	[Address] [nvarchar](30)  NULL,
	[City] [nvarchar](30)  NULL,
	[County] [nvarchar](30)  NULL,
	[State] [nvarchar](10)  NULL,
	[Phone] [varchar](100)  NULL,
	[Email] [varchar](100)  NULL,
	[Designation] [varchar](20)  NULL,
	[SSN] [varchar](100)  NULL,
	[SSN_encrypted] [nvarchar](100)  NULL
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

CREATE TABLE [dbo].[ImmunizationData]
( 
	[ResourceType] [nvarchar](max)  NULL,
	[Id] [nvarchar](max)  NULL,
	[Status] [nvarchar](max)  NULL,
	[OccurrenceDateTime] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Media]
( 
	[<referenceId>] [nvarchar](max)  NULL,
	[content.contentType] [nvarchar](max)  NULL,
	[Custom iframe] [nvarchar](max)  NULL,
	[deviceName] [nvarchar](max)  NULL,
	[duration] [nvarchar](max)  NULL,
	[encounter.reference] [nvarchar](max)  NULL,
	[frames] [nvarchar](max)  NULL,
	[Header Medium] [nvarchar](max)  NULL,
	[height] [nvarchar](max)  NULL,
	[id] [nvarchar](max)  NULL,
	[Image Url] [nvarchar](max)  NULL,
	[implicitRules] [nvarchar](max)  NULL,
	[language] [nvarchar](max)  NULL,
	[Photo] [nvarchar](max)  NULL,
	[status] [nvarchar](max)  NULL,
	[subject.reference] [nvarchar](max)  NULL,
	[URL] [nvarchar](max)  NULL,
	[width] [nvarchar](max)  NULL,
	[issued] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[medication request]
( 
	[<referenceId>] [nvarchar](max)  NULL,
	[authoredOn] [nvarchar](max)  NULL,
	[doNotPerform] [nvarchar](max)  NULL,
	[Encounter Reference] [nvarchar](max)  NULL,
	[id] [nvarchar](max)  NULL,
	[implicitRules] [nvarchar](max)  NULL,
	[intent] [nvarchar](max)  NULL,
	[language] [nvarchar](max)  NULL,
	[Medications] [nvarchar](max)  NULL,
	[priority] [nvarchar](max)  NULL,
	[status] [nvarchar](max)  NULL,
	[Subject Reference] [nvarchar](max)  NULL,
	[Trans Background color] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Miamihospitaloverview_Bed Occupancy]
( 
	[Month Name] [nvarchar](255)  NULL,
	[OccupancyRate] [float]  NULL,
	[Sum of OccupancyRate] [float]  NULL
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

CREATE TABLE [dbo].[Mkt_CampaignAnalyticLatest]
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Mkt_WebsiteSocialAnalyticsPBIData]
( 
	[Country] [nvarchar](4000)  NULL,
	[Product_Category] [nvarchar](4000)  NULL,
	[Product] [nvarchar](4000)  NULL,
	[Channel] [nvarchar](4000)  NULL,
	[Gender] [nvarchar](4000)  NULL,
	[Sessions] [nvarchar](4000)  NULL,
	[Device_Category] [nvarchar](4000)  NULL,
	[Sources] [nvarchar](4000)  NULL,
	[Conversations] [nvarchar](4000)  NULL,
	[Page] [nvarchar](4000)  NULL,
	[Visits] [nvarchar](4000)  NULL,
	[Unique_Visitors] [nvarchar](4000)  NULL,
	[Browser] [nvarchar](4000)  NULL,
	[Sentiment] [nvarchar](4000)  NULL,
	[Duration_min] [nvarchar](4000)  NULL,
	[Region] [nvarchar](4000)  NULL,
	[Customer_Segment] [nvarchar](4000)  NULL,
	[Daily_Users] [nvarchar](4000)  NULL,
	[Conversion_Rate] [nvarchar](4000)  NULL,
	[Return_Visitors] [nvarchar](4000)  NULL,
	[Tweets] [nvarchar](4000)  NULL,
	[Retweets] [nvarchar](4000)  NULL,
	[Hashtags] [nvarchar](4000)  NULL,
	[Campaign_Name] [nvarchar](4000)  NULL
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

CREATE TABLE [dbo].[new race]
( 
	[Race] [nvarchar](max)  NULL,
	[MDR] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[observation]
( 
	[<referenceId>.1] [nvarchar](max)  NULL,
	[<referenceId>.2] [nvarchar](max)  NULL,
	[Blood press Type] [nvarchar](max)  NULL,
	[Blood pressure Values] [nvarchar](max)  NULL,
	[Category] [nvarchar](max)  NULL,
	[code.coding.system] [nvarchar](max)  NULL,
	[component.code.id] [nvarchar](max)  NULL,
	[Data Filteration obsv] [nvarchar](max)  NULL,
	[Date (bins)] [nvarchar](max)  NULL,
	[Effective DateTime] [nvarchar](max)  NULL,
	[Effective DateTime (bins)] [nvarchar](max)  NULL,
	[Encounter Reference Key] [nvarchar](max)  NULL,
	[Gender Identification] [nvarchar](max)  NULL,
	[High] [nvarchar](max)  NULL,
	[id] [nvarchar](max)  NULL,
	[implicitRules] [nvarchar](max)  NULL,
	[issued] [nvarchar](max)  NULL,
	[language] [nvarchar](max)  NULL,
	[Low] [nvarchar](max)  NULL,
	[Measure] [nvarchar](max)  NULL,
	[Month - Day] [nvarchar](max)  NULL,
	[Month-Day Sort Key] [nvarchar](max)  NULL,
	[Patient Reference Key] [nvarchar](max)  NULL,
	[Previous Vitals] [nvarchar](max)  NULL,
	[Range] [nvarchar](max)  NULL,
	[status] [nvarchar](max)  NULL,
	[value.Quantity.code] [nvarchar](max)  NULL,
	[value.Quantity.system] [nvarchar](max)  NULL,
	[Vital code/name] [nvarchar](max)  NULL,
	[Vital Param Code] [nvarchar](max)  NULL,
	[Vital Param Names] [nvarchar](max)  NULL,
	[Vital Values] [nvarchar](max)  NULL,
	[Vital Values Unit] [nvarchar](max)  NULL,
	[Vital-name with Unit] [nvarchar](max)  NULL,
	[Vitals Name] [nvarchar](max)  NULL,
	[Vitals Reason/Code/Name] [nvarchar](max)  NULL,
	[Year] [nvarchar](max)  NULL,
	[Year Sort Key] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[patient]
( 
	[id] [nvarchar](max)  NULL,
	[active] [nvarchar](max)  NULL,
	[Age] [nvarchar](max)  NULL,
	[Age n Gender] [nvarchar](max)  NULL,
	[birth filter] [nvarchar](max)  NULL,
	[Birthdate] [nvarchar](max)  NULL,
	[Blood Group] [nvarchar](max)  NULL,
	[Button_Text] [nvarchar](max)  NULL,
	[City] [nvarchar](max)  NULL,
	[Contact Number] [nvarchar](max)  NULL,
	[country] [nvarchar](max)  NULL,
	[district] [nvarchar](max)  NULL,
	[Full Name] [nvarchar](max)  NULL,
	[filter Data] [nvarchar](max)  NULL,
	[Gender] [nvarchar](max)  NULL,
	[identifier.type.coding.code] [nvarchar](max)  NULL,
	[implicitRules] [nvarchar](max)  NULL,
	[language] [nvarchar](max)  NULL,
	[lastUpdated] [nvarchar](max)  NULL,
	[Martial Status] [nvarchar](max)  NULL,
	[Medical Record Number] [nvarchar](max)  NULL,
	[name Usage] [nvarchar](max)  NULL,
	[Patient First Name] [nvarchar](max)  NULL,
	[Patient Last Name] [nvarchar](max)  NULL,
	[Patient Ref Id] [nvarchar](max)  NULL,
	[postalCode] [nvarchar](max)  NULL,
	[Select Age] [nvarchar](max)  NULL,
	[Select_First_Name] [nvarchar](max)  NULL,
	[Select_Last_Name] [nvarchar](max)  NULL,
	[Selected Date] [nvarchar](max)  NULL,
	[Selected Value] [nvarchar](max)  NULL,
	[state] [nvarchar](max)  NULL,
	[versionId] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[PatientInformation]
( 
	[Patient Name] [nvarchar](4000)  NULL,
	[Gender] [nvarchar](4000)  NULL,
	[Phone] [nvarchar](4000)  NULL,
	[Email] [nvarchar](4000)  NULL,
	[Medical Insurance Card] [nvarchar](19)  NULL
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

CREATE TABLE [dbo].[pbiDepartment]
( 
	[dept_id] [int]  NULL,
	[department_name] [nvarchar](4000)  NULL,
	[department_type] [nvarchar](4000)  NULL
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

CREATE TABLE [dbo].[pbiManagementEmployee]
( 
	[hospital_info_id] [int]  NULL,
	[management_employees] [int]  NULL
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

CREATE TABLE [dbo].[pbiPatient]
( 
	[encounter_id] [int]  NULL,
	[hospital_id] [int]  NULL,
	[department_id] [int]  NULL,
	[city] [nvarchar](500)  NULL,
	[patient_id] [nvarchar](500)  NULL,
	[patient_age] [int]  NULL,
	[risk_level] [int]  NULL,
	[acute_type] [nvarchar](500)  NULL,
	[patient_category] [nvarchar](500)  NULL,
	[doctor_id] [int]  NULL,
	[length_of_stay] [int]  NULL,
	[wait_time] [int]  NULL,
	[type_of_stay] [nvarchar](500)  NULL,
	[treatment_cost] [float]  NULL,
	[claim_cost] [int]  NULL,
	[drug_cost] [int]  NULL,
	[hospital_expense] [int]  NULL,
	[follow_up] [int]  NULL,
	[readmitted_patient] [int]  NULL,
	[payment_type] [nvarchar](1000)  NULL,
	[date] [datetime]  NULL,
	[month] [nvarchar](1000)  NULL,
	[year] [int]  NULL
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

CREATE TABLE [dbo].[pbiPatientSurvey]
( 
	[id] [int]  NULL,
	[survey_id] [int]  NULL,
	[patient_encounter_id] [int]  NULL,
	[score] [int]  NULL
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

CREATE TABLE [dbo].[race mapping]
( 
	[Race] [nvarchar](max)  NULL,
	[Medical Record Number] [nvarchar](max)  NULL
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
	[RoleID] [nvarchar](4000)  NULL,
	[Name] [nvarchar](4000)  NULL,
	[Email] [nvarchar](4000)  NULL,
	[Roles] [nvarchar](4000)  NULL
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

CREATE TABLE [dbo].[SynapseLinkCosmosDBKPIs]
( 
	[ForHour] [int]  NULL,
	[Quality] [float]  NULL,
	[SampleVerified] [int]  NULL,
	[SampleRejected] [int]  NULL,
	[SampleRetested] [int]  NULL
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

CREATE TABLE [dbo].[SynapseLinkCosmosDBLast3HoursQuality]
( 
	[UpdatedOn] [datetime]  NULL,
	[Quality] [float]  NULL
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

CREATE TABLE [dbo].[SynapseLinkCosmosDBLast7HoursQualityVerified]
( 
	[ForHour] [int]  NULL,
	[Quality] [float]  NULL,
	[SampleVerified] [int]  NULL
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

CREATE TABLE [dbo].[SynapseLinkCosmosDBWorkload]
( 
	[BatchId] [varchar](512)  NULL,
	[PathologyProcessed] [float]  NULL,
	[PathologyVerified] [float]  NULL,
	[PathologyAuthenticated] [float]  NULL,
	[RadiologyProcessed] [float]  NULL,
	[RadiologyVerified] [float]  NULL,
	[RadiologyAuthenticated] [float]  NULL,
	[CardioProcessed] [float]  NULL
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

CREATE TABLE [dbo].[SynapseLinkLabData]
( 
	[UpdatedOn] [datetime]  NULL,
	[BatchId] [varchar](255)  NULL,
	[SampleAuthenticated] [int]  NULL,
	[SampleVerified] [int]  NULL,
	[SampleRejected] [int]  NULL,
	[SampleRetested] [int]  NULL,
	[Quality] [decimal](5,2)  NULL,
	[PathologyProcessed] [decimal](5,2)  NULL,
	[PathologyVerified] [decimal](5,2)  NULL,
	[PathologyAuthenticated] [decimal](5,2)  NULL,
	[RadiologyProcessed] [decimal](5,2)  NULL,
	[RadiologyVerified] [decimal](5,2)  NULL,
	[RadiologyAuthenticated] [decimal](5,2)  NULL,
	[CardioProcessed] [decimal](5,2)  NULL,
	[CardioVerified] [decimal](5,2)  NULL,
	[CardioAuthenticated] [decimal](5,2)  NULL
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

CREATE TABLE [dbo].[SynPatient]
( 
	[Id] [nvarchar](4000)  NULL,
	[BIRTHDATE] [nvarchar](4000)  NULL,
	[DEATHDATE] [nvarchar](4000)  NULL,
	[SSN] [nvarchar](4000)  NULL,
	[DRIVERS] [nvarchar](4000)  NULL,
	[PASSPORT] [nvarchar](4000)  NULL,
	[PREFIX] [nvarchar](4000)  NULL,
	[FIRST] [nvarchar](4000)  NULL,
	[LAST] [nvarchar](4000)  NULL,
	[SUFFIX] [nvarchar](4000)  NULL,
	[MAIDEN] [nvarchar](4000)  NULL,
	[MARITAL] [nvarchar](4000)  NULL,
	[RACE] [nvarchar](4000)  NULL,
	[ETHNICITY] [nvarchar](4000)  NULL,
	[GENDER] [nvarchar](4000)  NULL,
	[BIRTHPLACE] [nvarchar](4000)  NULL,
	[ADDRESS] [nvarchar](4000)  NULL,
	[CITY] [nvarchar](4000)  NULL,
	[STATE] [nvarchar](4000)  NULL,
	[COUNTY] [nvarchar](4000)  NULL,
	[ZIP] [nvarchar](4000)  NULL,
	[LAT] [nvarchar](4000)  NULL,
	[LON] [nvarchar](4000)  NULL,
	[HEALTHCARE_EXPENSES] [nvarchar](4000)  NULL,
	[HEALTHCARE_COVERAGE] [nvarchar](4000)  NULL
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

CREATE TABLE [dbo].[Vitals Graph]
( 
	[Vitals Name] [nvarchar](max)  NULL,
	[Vital Values Unit] [nvarchar](max)  NULL,
	[Vital Values] [nvarchar](max)  NULL,
	[Range] [nvarchar](max)  NULL,
	[Previous Vitals] [nvarchar](max)  NULL,
	[Patient Reference Key] [nvarchar](max)  NULL,
	[Low] [nvarchar](max)  NULL,
	[Labs Selection Filter] [nvarchar](max)  NULL,
	[High] [nvarchar](max)  NULL,
	[Font Color Result Vitals] [nvarchar](max)  NULL,
	[Effective DateTime] [nvarchar](max)  NULL,
	[Data Filteration] [nvarchar](max)  NULL,
	[Category] [nvarchar](max)  NULL,
	[Blood pressure Values] [nvarchar](max)  NULL,
	[Blood press Type] [nvarchar](max)  NULL
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

CREATE TABLE [dbo].[Web table]
( 
	[webpage Html] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

