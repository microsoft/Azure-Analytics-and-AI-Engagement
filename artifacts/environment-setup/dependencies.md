Exercise 1 
	Task 2
	"SAP HANA TO ADLS" Pipeline
		DataSet as its source."Sourcedataset_d89
		Sink "DestinationDataset_d89
		Staging linked service : "AzureDataLakeStorage5"
		
	Task 3
	"MarketingDBMigration" Pipeline
		Source data set "TeradataMarketingDB"
		"3 Campaign Analytics Data Prep" Notebook
	
	Task 4
	"SalesDBMigration" Pipeline
		"OracleSalesDB" dataset
		"Synapse" sink
		
	Task 5
	"TwitterDataMigration" pipeline
	
	Task 6
	"daidemosynapsestorageforgen2" storage account
		"twitterdata" container
			Parquet files in it.
	"AzureSynapseDW" SQL Pool
	
	Task 7
	"8 External Data to Synapse Via Copy Into" Script Script
		"Twitter" table in "AzureSynapseDW" SQL Pool
	
Exercise 2
	Task 1
	"1 SQL Query with Synapse" script
		"Sales" table with 30 billion records "AzureSynapseDW" SQL Pool
		
	Task 2
    "2 JSON Extractor" script
        "TwitterRawData" table from "AzureSynapseDW" SQL Pool

    Task 3
    "1. Product Recommendations" Notebook
        "CDPDreamPool" SQL Pool

    Task 4
    "2 AutoML Customer Forecasting"

Exercise 3
    Task 1
    "1. CDP Vision Demo" PowerBI Report

    Task 2
    "2. Billion Rows Demo" PowerBI Report
        wwi Sales Table
        ProdChamp Table
        Products Table