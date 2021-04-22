/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md
/* Reading Multiple Parquet files from ADLS Gen2 using non provisioned pool*/
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK 'https://#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/iomt-data/*.parquet',
        FORMAT='PARQUET'
    ) AS [result]
