---/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/*

SELECT FORMAT(COUNT_BIG(1), '#,0') as [Records Count] FROM dbo.Fact_Airqualitydetails WITH(NOLOCK)

----------Complex Query
DECLARE @TimeInterval AS INT
SET @TimeInterval= 60
SELECT Top 100
DATEADD(mi,DATEPART(hh,[readingDateTimeLocal])*60+
(DATEPART(mi,[readingDateTimeLocal])/@TimeInterval) * @TimeInterval, CONVERT(Datetime, CONVERT(varchar,[readingDateTimeLocal],102))) [Time],
[latitude] as Latitude, [longitude] as Longitude,
(SELECT top 1 aqi FROM [Fact_Airqualitydetails] WHERE [readingDateTimeLocal] = MIN(t.[readingDateTimeLocal])) [Open],
MAX(aqi) [High],
MIN(aqi) [Low],
(SELECT top 1 aqi FROM [Fact_Airqualitydetails] WHERE [readingDateTimeLocal] = MAX(t.[readingDateTimeLocal])) [Close]
FROM
[Fact_Airqualitydetails] t

where 
year([readingDateTimeLocal])=2020 
AND Month([readingDateTimeLocal])=12 
and DAY([readingDateTimeLocal])=31
and msrDeviceNbr in (2129,2087)
GROUP BY
[latitude], [longitude],
DATEADD(mi,DATEPART(hh,[readingDateTimeLocal])*60+
(DATEPART(mi,[readingDateTimeLocal])/@TimeInterval) * @TimeInterval, CONVERT(Datetime, CONVERT(varchar,[readingDateTimeLocal],102)))