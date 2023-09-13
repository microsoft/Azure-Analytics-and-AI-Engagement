----------Create Table in Data Warehouse using the COPY INTO command  
COPY INTO dbo.FactCampaignData  
FROM 'https://#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/data-source/Campaign Data/campaign-data2.csv' WITH  
(  
    FILE_TYPE = 'CSV'  
,CREDENTIAL = ( IDENTITY = 'Shared Access Signature', SECRET = '#STORAGE_ACCOUNT_SAS_TOKEN#')
    ,FIRSTROW = 2
)  
GO  

------Query the data from table 'CampaignData'

Select * From dbo.FactCampaignData 