-- DROP VIEWS

IF OBJECT_ID(N'[wwi_perf].[mvCustomerSales]') IS NOT NULL
drop view [wwi_perf].[mvCustomerSales]

IF OBJECT_ID(N'[wwi_perf].[vTableSizes]') IS NOT NULL
drop view [wwi_perf].[vTableSizes]

IF OBJECT_ID(N'[wwi_perf].[vColumnStoreRowGroupStats]') IS NOT NULL
drop view [wwi_perf].[vColumnStoreRowGroupStats]

IF OBJECT_ID(N'[dbo].[mvTransactionItemsCounts]') IS NOT NULL
drop view dbo.mvTransactionItemsCounts

-- DROP STATISTICS
IF EXISTS(select * from sys.stats where name = 'Sale_Hash_CustomerId')
DROP STATISTICS wwi_perf.Sale_Hash.Sale_Hash_CustomerId

-- DROP INDEXES

IF EXISTS(select * from sys.indexes where name = 'Store_Index')
drop index Store_Index on [wwi_perf].[Sale_Index]

-- DROP TABLES

IF OBJECT_ID(N'[wwi_staging].[SaleHeap]') IS NOT NULL   
DROP TABLE [wwi_staging].[SaleHeap]

IF OBJECT_ID(N'[wwi_staging].[Sale]') IS NOT NULL  
drop table wwi_staging.Sale

IF OBJECT_ID(N'[wwi_staging].[DailySalesCounts]') IS NOT NULL  
drop table wwi_staging.DailySalesCounts

IF OBJECT_ID(N'[wwi].[CampaignAnalytics]') IS NOT NULL  
drop table wwi.CampaignAnalytics

IF OBJECT_ID(N'[wwi].[UserProductReviews]') IS NOT NULL 
drop table wwi.UserProductReviews

IF OBJECT_ID(N'[wwi].[UserTopProductPurchases]') IS NOT NULL 
drop table wwi.UserTopProductPurchases

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash]') IS NOT NULL 
drop table [wwi_perf].[Sale_Hash]

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash_Projection]') IS NOT NULL 
drop table [wwi_perf].[Sale_Hash_Projection]

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash_Projection2]') IS NOT NULL 
drop table [wwi_perf].[Sale_Hash_Projection2]

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash_Projection_Big]') IS NOT NULL 
drop table [wwi_perf].[Sale_Hash_Projection_Big]

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash_Projection_Big2]') IS NOT NULL 
drop table [wwi_perf].[Sale_Hash_Projection_Big2]

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash_v2]') IS NOT NULL 
drop table [wwi_perf].[Sale_Hash_v2]

IF OBJECT_ID(N'[wwi_ml].[ProductPCA]') IS NOT NULL 
drop table wwi_ml.ProductPCA

IF OBJECT_ID(N'[wwi].[Recommendations]') IS NOT NULL 
drop table wwi.Recommendations

IF OBJECT_ID(N'[wwi_external].[DailySalesCounts]') IS NOT NULL 
drop external table [wwi_external].DailySalesCounts

IF OBJECT_ID(N'[wwi_external].[Sales]') IS NOT NULL 
drop external table [wwi_external].Sales

IF OBJECT_ID(N'[external].[DailySalesCounts]') IS NOT NULL 
drop external table [external].DailySalesCounts

IF OBJECT_ID(N'[external].[Sales]') IS NOT NULL 
drop external table [external].Sales

IF OBJECT_ID(N'[wwi_ml].[MLModel]') IS NOT NULL 
truncate table [wwi_ml].[MLModel]

-- DROP SCHEMAS

IF EXISTS (select * from sys.schemas where name = 'wwi_external')
DROP SCHEMA [wwi_external]

IF EXISTS (select * from sys.schemas where name = 'external')
DROP SCHEMA [external]

IF EXISTS (select * from sys.schemas where name = 'wwi_staging')
DROP SCHEMA [wwi_staging]

-- DROP EXTERNAL FILE FORMATS

IF EXISTS(select * from sys.external_file_formats where name = 'csv_dailysales')
drop external file format csv_dailysales

IF EXISTS(select * from sys.external_file_formats where name = 'ParquetFormat')
drop external file format ParquetFormat

-- DROP EXTERNAL DATA SOURCES

IF EXISTS(select * from sys.external_data_sources where name = 'ABSS')
drop external data source ABSS

-- DROP WORKLOAD CLASSIFIERS

IF EXISTS (SELECT * FROM sys.workload_management_workload_classifiers WHERE name = 'CEO')
DROP WORKLOAD CLASSIFIER CEO;

IF EXISTS (SELECT * FROM sys.workload_management_workload_classifiers where name = 'CEODreamDemo')
DROP WORKLOAD CLASSIFIER CEODreamDemo

IF EXISTS (SELECT * FROM sys.workload_management_workload_classifiers where name = 'HeavyLoader')
DROP WORKLOAD Classifier HeavyLoader

-- DROP WORKLOAD GROUPS

IF EXISTS (SELECT * FROM sys.workload_management_workload_groups where name = 'BigDataLoad')
DROP WORKLOAD GROUP BigDataLoad

IF EXISTS (SELECT * FROM sys.workload_management_workload_groups where name = 'CEODemo')
DROP WORKLOAD GROUP CEODemo

-- DROP SECURITY POLICIES

IF EXISTS (select * from sys.security_policies where name = 'SalesFilter')
BEGIN
    ALTER SECURITY POLICY SalesFilter  
    WITH (STATE = OFF);

    DROP SECURITY POLICY SalesFilter;
END

-- DROP FUNCTIONS

IF EXISTS (select * from sys.sql_modules M join sys.objects O on M.object_id = O.object_id where name = 'fn_securitypredicate')
DROP FUNCTION wwi_security.fn_securitypredicate

-- DROP MASKED COLUMNS 

IF EXISTS (
    select 
        *
    from 
        sys.masked_columns MC
        join sys.tables T ON
            MC.object_id = T.object_id
        join sys.schemas S ON
            T.schema_id = S.schema_id
    WHERE
        MC.is_masked = 1
        AND S.name = 'wwi_security'
        AND T.name = 'CustomerInfo'
        AND MC.name = 'CreditCard'
)
BEGIN
    ALTER TABLE wwi_security.CustomerInfo
    ALTER COLUMN [CreditCard] DROP MASKED;
END

IF EXISTS (
    select 
        *
    from 
        sys.masked_columns MC
        join sys.tables T ON
            MC.object_id = T.object_id
        join sys.schemas S ON
            T.schema_id = S.schema_id
    WHERE
        MC.is_masked = 1
        AND S.name = 'wwi_security'
        AND T.name = 'CustomerInfo'
        AND MC.name = 'Email'
)
BEGIN
    ALTER TABLE wwi_security.CustomerInfo
    ALTER COLUMN [Email] DROP MASKED;
END