# Lab Artifacts Documentation

## Lab 01

Lab 01 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`asacosmosdbNNNNNN` | Cosmos DB account |
`CustomerProfile` | Cosmos DB database |
`OnlineUserProfile01` | Cosmos DB database collection | Contains 100000 documents.
`asadatalakeNNNNNN` | Linked service (ADLS Gen2) |
`asadatalakeNNNNNN` | ADLS Gen2 storage account |
`wwi-02` | ADLS Gen2 file system in `asadatalakeNNNNNN` |
`wwi-02\sale-small` | Folder path in `asadatalakeNNNNNN` |
`wwi-02\online-user-profiles-02` | Folder path in `asadatalakeNNNNNN` |
`wwi-02\sale-small\Year=2016\Quarter=Q4\Month=12\Day=20161231\sale-small-20161231-snappy.parquet` | File path in `asadatalakeNNNNNN`
`wwi-02\sale-small\Year=2019` | Folder path in `asadatalakeNNNNNN` |
`wwi-02\campaign-analytics\dailycounts.txt` | File path in `asadatalakeNNNNNN` |
`wwi-02\campaign-analytics\sale-20161230-snappy.parquet` | File path in `asadatalakeNNNNNN` |
`SQLPool01` | SQL pool |
`sqlpool_import01` | Linked service (Azure Synapse Analytics) | Uses the `asa.sql.import01` user.
`SparkPool01` | Spark pool |

Lab 01 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`asacosmosdb01` | Cosmos DB Linked service |
`asal400_customerprofile_cosmosdb` | Dataset (Cosmos DB) |
`asal400_sales_adlsgen2` | Dataset (ADLS Gen2, Parquet) |
`asal400_ecommerce_userprofiles_source` | Dataset (ADSL Gen2, JSON) |
`asal400_december_sales` | Dataset (ADLS Gen2, Parquet) |
`asal400_saleheap_asa` | Dataset (Azure Synapse Analytics) |
`wwi_staging` | SQL pool schema |
`wwi_external` | SQL Pool schema |
`wwi_staging.SaleHeap` | SQL pool table |
`wwi_staging.Sale` | SQL pool table |
`wwi_staging.DailySalesCounts` | SQL Pool table |
`wwi_external.Sales` | SQL Pool external table |
`wwi_external.DailySalesCounts` | SQL Pool external table |
`ABSS` | SQL pool external data source |
`ParquetFormat` | SQL pool external file format |
`csv_dailysales` | SQL pool external file format |
`BigDataLoad` | SQL pool workload group |
`HeavyLoader` | SQL pool workload classifier |
`ASAL400 - Copy December Sales` | Pipeline |

## Lab 02

Lab 02 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`SQLPool01` | SQL pool |
`SparkPool01` | Spark pool |
`wwi` | SQL pool schema |
`wwi-02\campaign-analytics\campaignanalytics.csv` | Filepath in `asadatalakeNNNNNN` |
`sqlpool01` | Linked service (Azure Synapse Analytics)
`wwi-02\online-user-profiles-02` | Folder path in `asadatalakeNNNNNN` |
`asadatalakeNNNNNN` | Linked service (ADLS Gen2) |
`asadatalakeNNNNNN` | ADLS Gen2 storage account |
`wwi-02` | ADLS Gen2 file system in `asadatalakeNNNNNN` |

Lab 02 depends on the following artifacts created by previous labs:

Artifact Name | Artifact Type | Created by | Notes
--- | --- | --- | ---
`asal400_ecommerce_userprofiles_source` | Dataset (ADLS Gen2, JSON) | Lab 01 |
`asal400_customerprofile_cosmosdb` | Dataset (Cosmos DB) | Lab 01 |

> UPDATE: There is now an optional step in Lab 02 that walks users through creating these two datasets if they were unable to complete Exercise 1 in Lab 01.

Lab 02 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`AzureLargeComputeOptimizedIntegrationRuntime` | Integration runtime |
`wwi.CampaignAnalytics` | SQL pool table |
`wwi.Sale` | SQL pool table |
`wwi.UserProductReviews` | SQL pool table |
`wwi.UserTopProductPurchases` | SQL pool table |
`asal400_campaign_analytics_source` | Dataset (ADLS Gen2, Delimited text) |
`asal400_wwi_campaign_analytics_asa` | Dataset (Azure Synapse Analytics) |
`asal400_wwi_userproductreviews_asa` | Dataset (Azure Synapse Analytics) |
`asal400_wwi_usertopproductpurchases_asa` | Dataset (Azure Synapse Analytics) |
`ASAL400 - Lab 2 - Write Campaign Analytics to ASA` | Data flow |
`ASAL400 - Lab 2 - Write User Profile Data to ASA` | Data flow |
`ASAL400 - Lab 2 - Write Campaign Analytics to ASA` | Pipeline |
`ASAL400 - Lab 2 - Write User Profile Data to ASA` | Pipeline |

## Lab 03

Lab 03 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`SQLPool01` | SQL pool |
`wwi_perf` | SQL pool schema |
`wwi_perf.Sale_Heap` | SQL pool table | Contains 339507246 records.
`wwi_perf.Sale_Partition01` | SQL pool table | Contains 339507246 records.
`wwi_perf.Sale_Partition02` | SQL pool table | Contains 339507246 records.
`wwi.Date` | SQL pool table | Contains 3652 records.
`wwi_perf.Sale_Index` | SQL pool table | Contains 339507246 records.
`wwi_perf.Sale_Hash_Ordered` | SQL pool table | Contains 339507246 records.

Lab 03 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`wwi_perf.Sale_Hash` | SQL pool table |
`wwi_perf.mvCustomerSales` | SQL pool materialized view |
`RESULT_SET_CACHING ON` | SQL pool setting | Reset with `ALTER DATABASE [<sql_pool>] SET RESULT_SET_CACHING OFF`.
`Sale_Hash_Customer_Id` | SQL pool statistics on `wwi_perf.Sale_Hash (CustomerId)` | Reset with `DROP STATISTICS Sale_Hash_Customer_Id`.
`Store_Index` | SQL pool index on `wwi_perf.Sale_Index (StoreId)` |

## Lab 04

Lab 04 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`SQLPool01` | SQL pool |
`wwi_perf` | SQL pool schema |
`wwi_perf.Sale_Heap` | SQL pool table | Contains 339507246 records.
`wwi_perf.Sale_Partition01` | SQL pool table | Contains 339507246 records.
`wwi_perf.Sale_Partition02` | SQL pool table | Contains 339507246 records.
`wwi_perf.Sale_Index` | SQL pool table | Contains 339507246 records.
`wwi_perf.Sale_Hash_Ordered` | SQL pool table | Contains 339507246 records.

Lab 04 depends on the following artifacts created by previous labs:

Artifact Name | Artifact Type | Created by | Notes
--- | --- | --- | ---
`wwi_perf.Sale_Hash` | SQL pool table | Lab 03 |

Lab 04 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`wwi_perf.vTableSizes` | SQL pool view |
`wwi_perf.vColumnStoreRowGroupStats` | SQL pool view |
`wwi_perf.Sale_Hash_Projection` | SQL pool table |
`wwi_perf.Sale_Hash_Projectio2` | SQL pool table |
`wwi_perf.Sale_Hash_Projection_Big` | SQL pool table |
`wwi_perf.Sale_Hash_Projection_Big2` | SQL pool table |
`wwi_perf.mvTransactionItemsCounts` | SQL pool materialized view |
`wwi_perf.Sale_Hash_v2` | SQL pool table |

## Lab 05

Lab 05 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`asakeyvaultNNNNNN` | Azure Key Vault |
`asakeyvaultNNNNNN` | Linked service |
`SQLPool01` | SQL pool |
`Lab 05 - Exercise 3 - Column Level Security` | SQL script |
`Lab 05 - Exercise 3 - Row Level Security` | SQL script |
`Lab 05 - Exercise 3 - Dynamic Data Masking` | SQL script |
`wwi_security` | SQL pool schema |
`wwi_security.Sale` | SQL pool table | Contains 52 records.
`wwi_security.CustomerInfo` | SQL pool table | Contains 110 records.
`CEO` | SQL pool user |
`DataAnalystMiami` | SQL pool user |
`DataAnalystSanDiego` | SQL pool user |

Lab 05 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`PipelineSecret` | Azure Key Vault secret |
`wwi_security.fn_securitypredicate` | SQL pool function |
`SalesFilter` | SQL pool security policy |
`MASKED` on `wwi_perf.CustomerInfo.CreditCard` | SQL pool data mask |
`MASKED` on `wwi_perf.CustomerInfo.Email` | SQL pool data mask |

## Lab 06

Lab 06 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`asadatalakeNNNNNN` | ADLS Gen2 storage account |
`wwi-02` | ADLS Gen2 file system in `asadatalakeNNNNNN` |
`Lab 06 - Machine Learning` | Spark notebook |
`SQLPool01` | SQL pool |
`SparkPool01` | Spark pool |
`wwi` | SQL pool schema |
`wwi_ml` | SQL pool schema |
`wwi.SaleSmall` | SQL pool table | Contains 1863080489 records.
`wwi.Product` | SQL pool table | Contains 5000 records.
`StorageCredential` | SQL pool database scoped credential |
`ModelStorage` | SQL pool external data source |
`csv` | SQL pool external file format |
`wwi_ml.MLModelExt` | SQL pool external table | Contains 1 record.
`wwi_ml.MLModel` | SQL pool table | Contains 0 records.

Lab 06 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`wwi_ml.ProductPCA` | SQL pool table |

## Lab 07

Lab 07 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`Lab 07 - Spark ML` | Spark notebook |
`SQLPool01` | SQL pool |
`SparkPool01` | Spark pool |
`wwi.SaleSmall` | SQL pool table | Contains 1863080489 rows.

Lab 07 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`wwi.Recommendations` | SQL pool table |

## Lab 08

Lab 08 depends on the following artifacts that must exist in the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ---
`SQLPool01` | SQL pool |
`asa.sql.workload01` | SQL pool user |
`asa.sql.workload02` | SQL pool user |
`Lab 08 - Execute Data Analyst and CEO Queries` | Pipeline |

Lab 08 creates the following artifacts that must be deleted when cleaning up the environment:

Artifact Name | Artifact Type | Notes
--- | --- | ----
`CEO` | SQL pool workload classifier |
`CEODemo` | SQL pool workload group |
`CEODreamDemo` | SQL pool workload classifier |
