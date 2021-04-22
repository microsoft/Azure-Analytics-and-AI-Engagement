/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md
/* Querying Operational Data with Sample Covid 19 data from knowledge center*/
SELECT WeekNum
,BedsOccupied2020
--,BedOccupied2019
,ConfirmedCases
FROM
(
    SELECT C4 as WeekNum
    ,SUM(C5) as BedsOccupied2020
    FROM 
    OPENROWSET(
        BULK 'https://#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/operational-data/bedoccupancy.csv',
        FORMAT='CSV',
        FIRSTROW = 2,
		PARSER_VERSION='2.0'
    )as r
WHERE DATEPART(yy, cast(C1 as date))='2020'
    group by C4
    )AS [result1]
JOIN
(
    SELECT 
    DATEPART(WK,cast(Updated as date)) AS CovidWeek
    ,SUM(cast(confirmed_change as bigint)) AS ConfirmedCases
    FROM
    OPENROWSET(
        BULK 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/bing_covid-19_data/latest/bing_covid-19_data.parquet',
        FORMAT='parquet'
    ) AS [result]
    WHERE country_region='United States' AND Iso_subdivision IN('US-TX','US_CA') AND DATEPART(yy, cast(Updated as date))='2020'
        GROUP BY DATEPART(WK,cast(Updated as date))
) AS Covid
ON result1.WeekNum=Covid.CovidWeek
order by WeekNum