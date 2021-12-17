/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/
-- Step 1: Query parquet data in data lake
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK 'https://stfintaxdemoprod.dfs.core.windows.net/invoice-tax/fintax/',
        FORMAT='PARQUET'
    ) AS [result]

-- Step 2: Describe Result Set
EXEC sp_describe_first_result_set N'
	SELECT
        *
	FROM 
		OPENROWSET(
			BULK ''https://stfintaxdemoprod.dfs.core.windows.net/invoice-tax/fintax/'',
			FORMAT=''PARQUET''
	) AS scores';

-- Step 3: Create External Table
    -- Create External File Format
    -- Create External Data Source
    -- Create External Table

IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseParquetFormat') 
	CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat] 
	WITH ( FORMAT_TYPE = PARQUET)
GO

IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'invoice-tax_stfintaxdemoprod_dfs_core_windows_net') 
	CREATE EXTERNAL DATA SOURCE [invoice-tax_stfintaxdemoprod_dfs_core_windows_net] 
	WITH (
		LOCATION   = 'https://stfintaxdemoprod.dfs.core.windows.net/invoice-tax', 
	)
Go

IF NOT EXISTS (SELECT * FROM sys.external_tables WHERE name = 'FactTaxDetails')
CREATE EXTERNAL TABLE FactTaxDetails (
	[InvoiceNumber] varchar(8000),
	[InvoiceDate] varchar(8000),
	[TaxpayerID] varchar(8000),
	[SoldToState] varchar(8000),
	[TaxableAmount] numeric(19,4),
	[TaxAmount] numeric(19,4),
	[SKUNumber] varchar(8000),
	[Sector] varchar(8000)
	)
	WITH (
	LOCATION = 'fintax/',
	DATA_SOURCE = [invoice-tax_stfintaxdemoprod_dfs_core_windows_net],
	FILE_FORMAT = [SynapseParquetFormat]
	)
GO

-- Step 4: Query External Table
SELECT TOP 100 * FROM dbo.FactTaxDetails