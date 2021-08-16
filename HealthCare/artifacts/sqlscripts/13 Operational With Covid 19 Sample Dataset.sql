/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md

/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

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