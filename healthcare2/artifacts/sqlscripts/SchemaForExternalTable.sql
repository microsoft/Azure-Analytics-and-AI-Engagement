----Create Database
-- Create DATABASE SQLServerlessPool
use SQLServerlessPool

--Creates an external file format object that defines external data stored in Data Lake.
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseParquetFormat') 
	CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat] 
	WITH ( FORMAT_TYPE = PARQUET)
GO
-------For CSV Files
CREATE EXTERNAL FILE FORMAT DataCSV
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = ',',
          STRING_DELIMITER = '"',
          FIRST_ROW = 2,
          USE_TYPE_DEFAULT = True)
)

---Create Master Key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'L9835edf@12@$'
-- Use 'SQLServerlessPool' Serverless SQL Database
Use SQLServerlessPool

--Create Credential
CREATE DATABASE SCOPED CREDENTIAL sqlondemand
WITH IDENTITY='SHARED ACCESS SIGNATURE',
SECRET='#SAS_TOKEN#';

-- Create External Data Source
CREATE EXTERNAL DATA SOURCE [ADLSSource] 
	WITH (
		LOCATION = 'abfss://delta-files@#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net',
		CREDENTIAL =sqlondemand
	)

----------------- Create External Tables -------------------
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[AqiData]
(
	[MsrDeviceNbr] [nvarchar](4000),
	[ReadingDateTimeUTC] [nvarchar](4000),
	[TempCelcius] [nvarchar](4000),
	[Humidity] [nvarchar](4000),
	[Pressure] [nvarchar](4000),
	[PM25] [nvarchar](4000),
	[PM10] [nvarchar](4000),
	[PM1] [nvarchar](4000),
	[AQI] [nvarchar](4000),
	[Merge] [nvarchar](4000),
	[Hour] [nvarchar](4000),
	[Date] [nvarchar](4000),
	[Time] [nvarchar](4000),
	[Commute] [nvarchar](4000),
	[LocationKey] [nvarchar](4000),
	[TimeInHrs] [nvarchar](4000),
	[MonthName] [nvarchar](4000),
	[Year] [nvarchar](4000),
	[WeekNumber] [nvarchar](4000),
	[AQILabel] [nvarchar](4000),
	[AQILabelID] [nvarchar](4000),
	[latitude] [nvarchar](4000),
	[longitude] [nvarchar](4000),
	[City] [nvarchar](4000)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/AQI_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Bed_Occupancy_AQI_Map]
(
	[MsrDeviceNbr] [nvarchar](50),
	[ReadingDateTimeUTC] [nvarchar](50),
	[TempCelcius] [nvarchar](50),
	[Humidity] [nvarchar](50),
	[Pressure] [nvarchar](50),
	[PM25] [nvarchar](50),
	[PM10] [nvarchar](50),
	[PM1] [nvarchar](50),
	[AQI] [nvarchar](50),
	[Hour] [nvarchar](50),
	[Date] [nvarchar](50),
	[Time] [nvarchar](50),
	[Commute] [nvarchar](50),
	[LocationKey] [nvarchar](50),
	[TimeInHrs] [nvarchar](50),
	[MonthName] [nvarchar](50),
	[Year] [nvarchar](50),
	[WeekNumber] [nvarchar](50),
	[AQILabel] [nvarchar](50),
	[AQILabelID] [nvarchar](50),
	[latitude] [nvarchar](50),
	[longitude] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/AQI_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Bed_Occupancy_Healthdata]
(
	[Date] [nvarchar](50),
	[City] [nvarchar](50),
	[Region] [nvarchar](50),
	[BedOccupancyPercentage] [nvarchar](50),
	[AQI_Index] [nvarchar](50),
	[Latitude] [nvarchar](50),
	[Longitude] [nvarchar](50),
	[CountOfID] [nvarchar](50),
	[BySmptom] [nvarchar](50),
	[ShippingDelay] [nvarchar](50),
	[AvailableCencus] [nvarchar](50),
	[MaxBed] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/OccupancyHealthcareData_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Bed_Occupancy_Suppliers]
(
	[ID] [nvarchar](50),
	[City] [nvarchar](50),
	[Region] [nvarchar](50),
	[Date] [nvarchar](50),
	[DelayedMedicalShipments] [nvarchar](50),
	[ShippingPartnersNo] [nvarchar](50),
	[MedicalSuppliers] [nvarchar](50),
	[MedicalSupplierswithPortFacility] [nvarchar](50),
	[Latitude] [nvarchar](50),
	[Longitude] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/Supplier_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Call_Center]
(
	[vruline] [nvarchar](50),
	[priority] [nvarchar](50),
	[type] [nvarchar](50),
	[date] [nvarchar](50),
	[outcome] [nvarchar](50),
	[Agent] [nvarchar](50),
	[AnsweredCallEndTime] [nvarchar](50),
	[AnsweredCallStartTime] [nvarchar](50),
	[CallDurations] [nvarchar](50),
	[callid] [nvarchar](50),
	[customerid] [nvarchar](50),
	[QueueExitTime] [nvarchar](50),
	[QueueStartTime] [nvarchar](50),
	[QueueDurations] [nvarchar](50),
	[vrudurations] [nvarchar](50),
	[vruentrytime] [nvarchar](50),
	[vruexittime] [nvarchar](50),
	[NPS] [nvarchar](50),
	[Pleasantry] [nvarchar](50),
	[Proficiency] [nvarchar](50),
	[Efficiency] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/CallsCenterData_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Campaigns_gold]
(
	[Campaigns_ID] [nvarchar](255),
	[CampaignID] [nvarchar](255),
	[CampaignName] [nvarchar](255),
	[SubCampaignID] [nvarchar](255),
	[FullAd_FileName] [nvarchar](255),
	[HalfAd_FileName] [nvarchar](255),
	[Logo_FileName] [nvarchar](255),
	[SoundFile_FileName] [nvarchar](255),
	[FullAd] [nvarchar](255),
	[HalfAd] [nvarchar](255),
	[Logo] [nvarchar](255),
	[SoundFile] [nvarchar](255)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/Campaigns_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Glb_BedOccupancy]
(
	[City] [nvarchar](4000),
	[MonthNumber] [nvarchar](4000),
	[BedOccupancyRate] [nvarchar](4000)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/GlbBedOccupancy_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Glb_MarginRate]
(
	[City] [nvarchar](4000),
	[MarginPercent] [nvarchar](4000),
	[MonthName] [nvarchar](4000)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/GlbMarginRate_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Glb_PatientExperience]
(
	[City] [nvarchar](4000),
	[PatientExperience] [nvarchar](4000),
	[MonthName] [nvarchar](4000)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/GlbPatientExperience_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Global_Overview_BedOccupancy]
(
	[City] [nvarchar](50),
	[MonthNumber] [nvarchar](50),
	[BedOccupancyRate] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/GlbBedOccupancy_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Global_Overview_MarginRate]
(
	[City] [nvarchar](50),
	[MarginPercent] [nvarchar](50),
	[MonthName] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/GlbMarginRate_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Global_Overview_Patient_Experience]
(
	[City] [nvarchar](50),
	[PatientExperience] [nvarchar](50),
	[MonthName] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/GlbPatientExperience_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Healthcare_OccupancyData]
(
	[Date] [nvarchar](4000),
	[City] [nvarchar](4000),
	[Region] [nvarchar](4000),
	[BedOccupancyPercentage] [nvarchar](4000),
	[AQI_Index] [nvarchar](4000),
	[Latitude] [nvarchar](4000),
	[Longitude] [nvarchar](4000),
	[CountOfID] [nvarchar](4000),
	[BySmptom] [nvarchar](4000),
	[ShippingDelay] [nvarchar](4000),
	[AvailableCencus] [nvarchar](4000),
	[MaxBed] [nvarchar](4000)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/OccupancyHealthcareData_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Hospital_Overview_BedOccupancy]
(
	[MonthName] [nvarchar](50),
	[OccupancyRate] [nvarchar](50),
	[SumofOccupancyRate] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/HospitalOverviewBedOccupancy_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Patient_Profile]
(
	[Date] [nvarchar](50),
	[DataIndex] [nvarchar](50),
	[Brand] [nvarchar](50),
	[CreditScoreSort] [nvarchar](50),
	[AgeGroupSort] [nvarchar](50),
	[Value01] [nvarchar](50),
	[Value02] [nvarchar](50),
	[Value6A] [nvarchar](50),
	[Value6b] [nvarchar](50),
	[Value6C] [nvarchar](50),
	[CountryId] [nvarchar](50),
	[GenerationId] [nvarchar](50),
	[PurchasedSpaVisitId] [nvarchar](50),
	[RentedSportsEquipmentId] [nvarchar](50),
	[SourceId] [nvarchar](50),
	[ProductSearchId] [nvarchar](50),
	[DeviceTypeId] [nvarchar](50),
	[PrimaryInterestId] [nvarchar](50),
	[AgeId] [nvarchar](50),
	[Happiness] [nvarchar](50),
	[PercentageCount] [nvarchar](50),
	[MonthYear] [nvarchar](50),
	[BounceRate] [nvarchar](50),
	[SortMonth] [nvarchar](50),
	[Patients] [nvarchar](50),
	[PatientId] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/Patient_Profile_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[Supplier]
(
	[ID] [nvarchar](4000),
	[City] [nvarchar](4000),
	[Region] [nvarchar](4000),
	[Date] [nvarchar](4000),
	[DelayedMedicalShipments] [nvarchar](4000),
	[ShippingPartnersNo] [nvarchar](4000),
	[MedicalSuppliers] [nvarchar](4000),
	[MedicalSupplierswithPortFacility] [nvarchar](4000),
	[Latitude] [nvarchar](4000),
	[Longitude] [nvarchar](4000)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/Supplier_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[US_MAP]
(
	[City] [nvarchar](50),
	[Total_Patients] [nvarchar](50),
	[NumberofPatients] [nvarchar](50),
	[Rating] [nvarchar](50),
	[OccupancyRate_percentage] [nvarchar](50),
	[Margin] [nvarchar](50),
	[Readmission_Rate] [nvarchar](50),
	[New_Readmission_Rate1] [nvarchar](50),
	[New_Readmission_Rate] [nvarchar](50)
)
WITH (DATA_SOURCE = [ADLSSource],LOCATION = N'tables/USMap_gold/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO
----------------------