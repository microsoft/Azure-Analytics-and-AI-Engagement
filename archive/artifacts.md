**Pipelines**

* SAP HANA TO ADLS pipeline 
    * Source data sets; SourceDataset_d89, DelimitedText1
    * select * from "DEMODB"."FactInternetSalesS";
    * Sink dataset DestinationDataset_d89, AzureSynapseAnalyticsTable9, AzureSynapseAnalyticsTable8
    * AzureDataLakeStorage5 is used.
* MarketingDBMigration pipeline used.
    * 	Source dataset TeradataMarketingDB, MarketingDB_Stage
    * 	Sink MarketingDB_Stage, Synapse
    * 	Notebook 3 Campaings Analytics Data Prep
* SalesDBMigration pipeline 
    * 	Source dataset OracleSalesDB
    * 	Sink Synapse
* TwitterDataMigration
    * 	Source dataset Parquet1, Parquet2, Parquet3
    * 	Sink AzureSynapseAnalyticsTable1, Parquet3
    * 	Storage Account cdpvisionworksapce-WorksapceDefaultStorage

**Additional storage accounts used;**
* daidemosynapsestorageforgen2 (specifically twitterdata is used)

**SQL Scripts Used**
- 8 External Data to Synapse Via Copy Into
    - AzureSynapseDW Database : Tables : dbo.Twitter
- 1 SQL Query with Synapse
    - AzureSynapseDW Database : Tables : dbo.Sales, dbo.Products, [dbo].[Dim_Customer], dbo.[TwitterAnalytics], dbo.[MillennialCustomers]
- 2 JSON Extractor
    - AzureSynapseDW Database : Tables : dbo.[TwitterRawData] 

**Notebooks Used**
- 1 Product Recommendations
    - Spark Pool : CDP DreamPool
    - AzureSynapseDW.dbo.Customer_SalesLatest
- 2 AutoML Customer Forecasting
    - AzureSynapseDW.dbo.department_visit_customer

**Power BI**
- 1.CDP Vision Demo
- 2.Billion Rows Demo

We do not have access to the PBIX files yet. Below are assumptions based on database schema comparison with the database **AzureSynapseDW**.

| Database Table Name    | Power BI Collection Name |
|------------------------|--------------------------|
| BookConsumption        | =                        |
| BookList               | =                        |
| Books                  | =                        |
| BrandAwareness         | =                        |
| Campaign_Analytics     | =                        |
| CampaignNew4           | =                        |
| Campaigns              | =                        |
| Category               | =                        |
| ConflictofInterest     | =                        |
| Country                | =                        |
| CustomerVisitF         | =                        |
| DimDate                | =                        |
| EmailAnalytics         | =                        |
| FinalRevenue           | =                        |
| FinanceSales           | =                        |
| FPA                    | =                        |
| LocationAnalytics      | =                        |
| OperatingExpenses      | =                        |
| Popularity             | =                        |
| ProdChamp              | =                        |
| ProductLink            | ProductLinks             |
| ProductLink2           | ProductLink22            |
| ProductRecommendations | =                        |
| Products               | =                        |
| Sales                  | =                        |
| SalesMaster            | =                        |
| SalesVsExpense         | =                        |
| SalesTransactions      | wwi Sales                |
| SiteSecurity           | =                        |
| WebsiteSocialAnalytics | =                        |

