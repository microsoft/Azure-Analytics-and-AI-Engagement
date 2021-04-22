Create VIEW vwCovidDataParquet
AS
    SELECT WeekNum
,BedsOccupied2020
,BedsOccupied2019
,ConfirmedCases
,State
FROM
(
    SELECT C4 as WeekNum
    ,SUM(C5) as BedsOccupied2020
    FROM 
    OPENROWSET(
        BULK    'https://#STORAGE_ACCOUNT#.dfs.core.windows.net/operational-data/bedoccupancy_latest1.csv',
        FORMAT  =  'CSV',
        FIRSTROW = 2,
PARSER_VERSION='2.0'
    )as r
WHERE DATEPART(yy, cast(C1 as date))='2020'
    group by C4
    )AS [result1]
JOIN
(
    SELECT 
    DATEPART(WK,cast(Date as date)) AS CovidWeek
    ,SUM(cast(Positive as bigint)) AS ConfirmedCases
    ,State
    FROM
    OPENROWSET(
        BULK  'https://#STORAGE_ACCOUNT#.dfs.core.windows.net/operational-data/covid_tracking.parquet',
        FORMAT  =  'parquet'
    ) AS [result]
    WHERE Iso_country='US' AND DATEPART(yy, cast(Date as date))='2020'
        GROUP BY DATEPART(WK,cast(Date as date)),State
) AS Covid
ON result1.WeekNum=Covid.CovidWeek
JOIN
(
SELECT C4 as WeekNum1
    ,SUM(C5) as BedsOccupied2019
    FROM 
    OPENROWSET(
        BULK  'https://#STORAGE_ACCOUNT#.dfs.core.windows.net/operational-data/bedoccupancy_latest2.csv',
        FORMAT='CSV',
        FIRSTROW = 2,
PARSER_VERSION='2.0'
    )as r
WHERE DATEPART(yy, cast(C1 as date))='2019'
     group by C4
    )AS [result2]
ON result2.WeekNum1=Covid.CovidWeek