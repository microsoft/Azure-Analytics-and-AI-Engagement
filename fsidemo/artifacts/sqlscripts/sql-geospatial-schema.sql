ALTER DATABASE [db-geospatial] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [db-geospatial] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [db-geospatial] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [db-geospatial] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [db-geospatial] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [db-geospatial] SET ARITHABORT OFF 
GO
ALTER DATABASE [db-geospatial] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [db-geospatial] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [db-geospatial] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [db-geospatial] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [db-geospatial] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [db-geospatial] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [db-geospatial] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [db-geospatial] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [db-geospatial] SET ALLOW_SNAPSHOT_ISOLATION ON 
GO
ALTER DATABASE [db-geospatial] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [db-geospatial] SET READ_COMMITTED_SNAPSHOT ON 
GO
ALTER DATABASE [db-geospatial] SET  MULTI_USER 
GO
ALTER DATABASE [db-geospatial] SET ENCRYPTION ON
GO
ALTER DATABASE [db-geospatial] SET QUERY_STORE = ON
GO
ALTER DATABASE [db-geospatial] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 100, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
/*** The scripts of database scoped configurations in Azure should be executed inside the target database connection. ***/
GO
-- ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 8;
GO

/****** Object:  Table [dbo].[Geo_Cities]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Geo_Cities](
	[CityID] [int] NOT NULL,
	[CityName] [nvarchar](50) NOT NULL,
	[StateProvinceID] [int] NOT NULL,
	[Location] [geography] NULL,
	[LatestRecordedPopulation] [bigint] NULL,
	[LastEditedBy] [int] NOT NULL,
	[ValidFrom] [datetime2](7) NOT NULL,
	[ValidTo] [datetime2](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[geo_cities1]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[geo_cities1] as
(select CityID as City_ID,
       CityName as City,
       StateProvinceID as Province,
	   Location as Loc

from dbo.Geo_Cities)



GO
/****** Object:  Table [dbo].[Geo_HurricaneCustomerDetails]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Geo_HurricaneCustomerDetails](
	[CustomerId] [float] NULL,
	[FirstName] [nvarchar](255) NULL,
	[LastName] [nvarchar](255) NULL,
	[Gender] [nvarchar](255) NULL,
	[EmailId] [nvarchar](255) NULL,
	[ContactNo] [nvarchar](255) NULL,
	[BankName] [nvarchar](255) NULL,
	[LoanNo] [float] NULL,
	[LoanAmount] [float] NULL,
	[PayableAmount] [float] NULL,
	[InterestRate] [float] NULL,
	[TenureInYear] [float] NULL,
	[EMI] [float] NULL,
	[TotalEMI] [float] NULL,
	[EMIPaid] [float] NULL,
	[EMIRemaining] [float] NULL,
	[LoanStatus] [nvarchar](255) NULL,
	[CityID] [float] NULL,
	[HurricaneId] [float] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Geo_HurricaneDetailsFlorida]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Geo_HurricaneDetailsFlorida](
	[Id] [float] NULL,
	[Storm] [nvarchar](255) NULL,
	[SaffirSimpsonCategory] [float] NULL,
	[Date] [float] NULL,
	[Month] [float] NULL,
	[Year] [float] NULL,
	[LandfallIntensityInKnots] [float] NULL,
	[LandfallLocation] [nvarchar](255) NULL,
	[CityID] [int] NULL,
	[Location] [geography] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[RiskAreas]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[RiskAreas] as (

select 
	max(h.SaffirSimpsonCategory) as MaxSaffirSimpsonCategory, 
	h.CityId as CityId, 
	h.LandFallLocation as CityName, 
	h.[Location].Lat AS [Latitude],
    h.[Location].Long AS [Longitude],
	WoodGroveCustomerCount = (SELECT sum(case when c.BankName = 'Woodgrove' and (c.LoanStatus = 'Defaulting' or c.LoanStatus = 'Ongoing') then 1 else 0 end) FROM [Geo_HurricaneCustomerDetails] c where c.CityID = h.CityId)
from [Geo_HurricaneDetailsFlorida] h
where h.Location IS NOT NULL
group by h.CityID, h.LandFallLocation, h.[Location].Lat, h.[Location].Long

);

GO
/****** Object:  Table [dbo].[Geo_StateProvinces]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Geo_StateProvinces](
	[StateProvinceID] [int] NOT NULL,
	[StateProvinceCode] [nvarchar](5) NOT NULL,
	[StateProvinceName] [nvarchar](50) NOT NULL,
	[CountryID] [int] NOT NULL,
	[SalesTerritory] [nvarchar](50) NOT NULL,
	[Border] [geography] NULL,
	[LatestRecordedPopulation] [bigint] NULL,
	[LastEditedBy] [int] NOT NULL,
	[ValidFrom] [datetime2](7) NOT NULL,
	[ValidTo] [datetime2](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  StoredProcedure [dbo].[GetHurricaneDataFlorida]    Script Date: 18-06-2021 18:11:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetHurricaneDataFlorida]
AS
BEGIN
	DECLARE @featureList nvarchar(max) =
	(
		SELECT * FROM
		(
			SELECT
				ROW_NUMBER() OVER (
					PARTITION BY T1.[CityID]
					ORDER BY T1.[SaffirSimpsonCategory] DESC
				) AS row_no,
				'Feature'									AS 'type',
				CAST(T1.[Id] AS VARCHAR)					AS 'properties.Id',
				T1.[Storm]									AS 'properties.Storm',
				CAST(T1.[SaffirSimpsonCategory] AS INT)		AS 'properties.SaffirSimpsonCategory',
				CAST(T1.[Date] AS INT)						AS 'properties.Date',
				CAST(T1.[Month] AS INT)						AS 'properties.Month',
				CAST(T1.[Year] AS INT)						AS 'properties.Year',
				CAST(T1.[LandfallIntensityInKnots] AS INT)	AS 'properties.LandfallIntensityInKnots',
				T1.[LandfallLocation]						AS 'properties.LandfallLocation',
				T1.[CityID]									AS 'properties.CityID',
				T2.[CustomerCount]							AS 'properties.CustomerCount',
				T1.[Location].STGeometryType()				AS 'geometry.type',
				JSON_QUERY('[' + CAST([Location].Long AS VARCHAR) + ', ' + CAST([Location].Lat AS VARCHAR) + ']') AS 'geometry.coordinates'
			FROM [dbo].[Geo_HurricaneDetailsFlorida] T1
			INNER JOIN
			(
				SELECT 
					COUNT(1) AS CustomerCount,
					CityID
				FROM [dbo].[Geo_HurricaneCustomerDetails]
				WHERE ([LoanStatus] = 'Defaulting' or [LoanStatus] = 'Ongoing') AND [BankName] = 'Woodgrove'
				GROUP BY CityID
			) T2
			ON T1.CityID = T2.CityID
		) DataResult
		WHERE DataResult.row_no = 1
		ORDER BY [properties.SaffirSimpsonCategory] DESC
		FOR JSON PATH
	);

	DECLARE @featureCollection nvarchar(max) = (
		SELECT 'FeatureCollection' AS 'type',
		JSON_QUERY(@featureList)   AS 'features'
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	);

	SELECT @featureCollection AS data;

END
GO

/****** Object:  StoredProcedure [dbo].[GetHurricaneDataFloridaV1]    Script Date: 18-06-2021 18:11:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetHurricaneDataFloridaV1]
AS
BEGIN

	DECLARE @featureList nvarchar(max) =
	(
		SELECT
			'Feature'									AS 'type',
			CAST([Id] AS VARCHAR)						AS 'id',
			[Storm]										AS 'properties.Storm',
			CAST(([SaffirSimpsonCategory]) AS VARCHAR)	AS 'properties.SaffirSimpsonCategory',
			CAST([Date] AS VARCHAR)						AS 'properties.Date',
			CAST([Month] AS VARCHAR)					AS 'properties.Month',
			CAST([Year] AS VARCHAR)						AS 'properties.Year',
			CAST([LandfallIntensityInKnots] AS VARCHAR) AS 'properties.LandfallIntensityInKnots',
			[LandfallLocation]							AS 'properties.LandfallLocation',
			T1.[CityID]									AS 'properties.CityID',
			T2.[CustomerCount]							AS 'properties.CustomerCount',
			[Location].STGeometryType()                 AS 'geometry.type',
			JSON_QUERY('[' + CAST([Location].Long AS VARCHAR) + ', ' + CAST([Location].Lat AS VARCHAR) + ']') AS 'geometry.coordinates'
		FROM [dbo].[Geo_HurricaneDetailsFlorida] T1
		INNER JOIN
		(
			SELECT 
				COUNT(1) AS CustomerCount,
				CityID
			FROM [dbo].[Geo_HurricaneCustomerDetails]
			WHERE ([LoanStatus] = 'Defaulting' or [LoanStatus] = 'Ongoing') AND [BankName] = 'Woodgrove'
			GROUP BY CityID
		) T2
		ON T1.CityID = T2.CityID
		--GROUP BY [Id], [Storm], [Date], [Month], [Year], [LandfallIntensityInKnots], [LandfallLocation], T1.[CityID], T2.[CustomerCount], [Location].STAsText()
		FOR JSON PATH
	);

	DECLARE @featureCollection nvarchar(max) = (
		SELECT 'FeatureCollection' AS 'type',
		JSON_QUERY(@featureList)   AS 'features'
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	);

	SELECT @featureCollection AS data;

END
GO

/****** Object:  StoredProcedure [dbo].[GetGeospatialHurricaneDataFlorida]    Script Date: 26-07-2021 19:12:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetGeospatialHurricaneDataFlorida]
AS
BEGIN
	-- declare variables of type table for high risk, medium risk and low risk areas
	DECLARE @LowRiskAreas TABLE (SaffirSimpsonCategory int, CityId int, CityName varchar(50), CityLocation geometry, WoodGroveCustomerCount int )  
	DECLARE @MediumRiskAreas TABLE (SaffirSimpsonCategory int, CityId int, CityName varchar(50), CityLocation geometry, WoodGroveCustomerCount int )  
	DECLARE @HighRiskAreas TABLE (SaffirSimpsonCategory int, CityId int, CityName varchar(50), CityLocation geometry, WoodGroveCustomerCount int )  

	-- insert into temporary table named LowRiskAreas where SaffirSimpsonCategory is less than 3
	INSERT INTO @LowRiskAreas
	select 
		max(h.SaffirSimpsonCategory) as MaxSaffirSimpsonCategory, 
		h.CityId as CityId, 
		h.LandFallLocation as CityName, 
		GEOMETRY::STGeomFromText(h.Location.STAsText(), 4326) as CityLocation,
		WoodGroveCustomerCount = (SELECT sum(case when c.BankName = 'Woodgrove' and (c.LoanStatus = 'Defaulting' or c.LoanStatus = 'Ongoing') then 1 else 0 end) FROM [Geo_HurricaneCustomerDetails] c where c.CityID = h.CityId)
	from [Geo_HurricaneDetailsFlorida] h
	where h.Location IS NOT NULL
	group by h.CityID, h.LandFallLocation, h.Location.STAsText()
	having max(h.SaffirSimpsonCategory) < 3

	-- insert into temporary table named MediumRiskAreas where SaffirSimpsonCategory is less than 5 and greater than equal to 3
	INSERT INTO @MediumRiskAreas
	select 
		max(h.SaffirSimpsonCategory) as MaxSaffirSimpsonCategory, 
		h.CityId as CityId, 
		h.LandFallLocation as CityName, 
		GEOMETRY::STGeomFromText(h.Location.STAsText(), 4326) as CityLocation,
		WoodGroveCustomerCount = (SELECT sum(case when c.BankName = 'Woodgrove' and (c.LoanStatus = 'Defaulting' or c.LoanStatus = 'Ongoing') then 1 else 0 end) FROM [Geo_HurricaneCustomerDetails] c where c.CityID = h.CityId)
	from [Geo_HurricaneDetailsFlorida] h
	where h.Location IS NOT NULL
	group by h.CityID, h.LandFallLocation, h.Location.STAsText()
	having max(h.SaffirSimpsonCategory) < 5 and max(h.SaffirSimpsonCategory) >= 3

	-- insert into temporary table named HighRiskAreas where SaffirSimpsonCategory is greater than equal to 5 
	INSERT INTO @HighRiskAreas
	select 
		max(h.SaffirSimpsonCategory) as MaxSaffirSimpsonCategory, 
		h.CityId as CityId, 
		h.LandFallLocation as CityName, 
		GEOMETRY::STGeomFromText(h.Location.STAsText(), 4326) as CityLocation,
		WoodGroveCustomerCount = (SELECT sum(case when c.BankName = 'Woodgrove' and (c.LoanStatus = 'Defaulting' or c.LoanStatus = 'Ongoing') then 1 else 0 end) FROM [Geo_HurricaneCustomerDetails] c where c.CityID = h.CityId)
	from [Geo_HurricaneDetailsFlorida] h
	where h.Location IS NOT NULL
	group by h.CityID, h.LandFallLocation, h.Location.STAsText()
	having max(h.SaffirSimpsonCategory) >=5

	-- plot state boundary
	select GEOMETRY::STGeomFromText(sp.Border.ToString(),4326) as Location, '' as city_name, '' as woodgrove_customer_count from dbo.Geo_StateProvinces sp
	-- for florida
	where sp.StateProvinceCode = 'FL'

	-- high risk areas
	union all
	SELECT 
		GEOMETRY::STGeomFromText(c.Location.ToString(),4326).STBuffer(0.30) as Location, 
		m.CityName as city_name,
		m.WoodGroveCustomerCount as woodgrove_customer_count 
	FROM @HighRiskAreas m
	inner join dbo.Geo_Cities c
	on m.CityLocation.STIntersects(GEOMETRY::STGeomFromText(c.Location.ToString(),4326)) = 1
	where c.StateProvinceID = 10

	-- medium risk areas
	union all
	SELECT 
		GEOMETRY::STGeomFromText(c.Location.ToString(),4326).STBuffer(0.10) as Location, 
		m.CityName as city_name,
		m.WoodGroveCustomerCount as woodgrove_customer_count 
	FROM @MediumRiskAreas m
	inner join dbo.Geo_Cities c
	on m.CityLocation.STIntersects(GEOMETRY::STGeomFromText(c.Location.ToString(),4326)) = 1
	where c.StateProvinceID = 10

	-- low risk areas
	union all
	SELECT 
		GEOMETRY::STGeomFromText(c.Location.ToString(),4326) as Location, 
		m.CityName as city_name,
		m.WoodGroveCustomerCount as woodgrove_customer_count 
	FROM @LowRiskAreas m
	inner join dbo.Geo_Cities c
	on m.CityLocation.STIntersects(GEOMETRY::STGeomFromText(c.Location.ToString(),4326)) = 1
	where c.StateProvinceID = 10

END
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Numeric ID used for reference to a city within the database' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Geo_Cities', @level2type=N'COLUMN',@level2name=N'CityID'
GO
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Formal name of the city' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Geo_Cities', @level2type=N'COLUMN',@level2name=N'CityName'
GO
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'State or province for this city' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Geo_Cities', @level2type=N'COLUMN',@level2name=N'StateProvinceID'
GO
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Geographic location of the city' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Geo_Cities', @level2type=N'COLUMN',@level2name=N'Location'
GO
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Latest available population for the City' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Geo_Cities', @level2type=N'COLUMN',@level2name=N'LatestRecordedPopulation'
GO
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Cities that are part of any address (including geographic location)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Geo_Cities'
GO
ALTER DATABASE [db-geospatial] SET  READ_WRITE 
GO

