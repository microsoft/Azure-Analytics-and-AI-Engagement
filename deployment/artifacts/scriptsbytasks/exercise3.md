## Task 3.2

``` 
from pyspark.sql import SparkSession
from pyspark.sql.utils import AnalysisException

\# Initialize Spark session with Delta support.
spark = SparkSession.builder \
    .appName("FabricOneLakeRead") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()

\# Enable schema auto-merge
spark.conf.set("spark.databricks.delta.schema.autoMerge.enabled", "true")
\# Enable division expression conversion rule to reduce rounding error propagation
spark.conf.set("spark.advise.divisionExprConvertRule.enable", "true")

\# Define OneLake paths using ABFS
source_salesdata_path = "abfss://Fabcon@onelake.dfs.fabric.microsoft.com/Lakehouse_Bronze.Lakehouse/Tables/dbo/dim_salesdata"
source_customer_path = "abfss://Fabcon@onelake.dfs.fabric.microsoft.com/Lakehouse_Bronze.Lakehouse/Tables/dbo/dimcustomer"
destination_lakehouse_table = "abfss://Fabcon@onelake.dfs.fabric.microsoft.com/Lakehouse_Bronze.Lakehouse/Tables/dbo/SalesMetricsTable"

\# Step 1: Read data from the source lakehouse
try:
    df_salesdata = spark.read.format("delta").load(source_salesdata_path)
    df_salesdata.createOrReplaceTempView("dim_salesdata")
    
    df_customer = spark.read.format("delta").load(source_customer_path)
    df_customer.createOrReplaceTempView("dim_customer")
except Exception as e:
    print(f"Error reading from source: {e}")
    df_salesdata = None
    df_customer = None

if df_salesdata is not None and df_customer is not None:
    sales_metrics_query = """
SELECT 
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    ROUND(SUM(s.NetRevenue), 2) AS TotalSalesRevenue,
    ROUND(SUM(s.GrossRevenue), 2) AS TotalGrossRevenue,
    ROUND(SUM(s.GrossProfit), 2) AS TotalGrossProfit,
    ROUND(SUM(s.NetRevenue) - SUM(s.COGS), 2) AS NetProfit,
    ROUND(SUM(s.NetRevenue) / COUNT(DISTINCT s.CustomerId), 2) AS AverageOrderValue,
    ROUND(SUM(s.NetRevenue) / COUNT(DISTINCT s.ProductId), 2) AS RevenuePerProduct,
    ROUND(SUM(s.Quantity), 2) AS TotalQuantitySold,
    ROUND(SUM(s.Discount) / SUM(s.GrossRevenue), 2) AS DiscountRate,
    ROUND(SUM(s.Discount) / COUNT(DISTINCT s.CustomerId), 2) AS AverageDiscountPerOrder,
    ROUND(SUM(s.COGS), 2) AS TotalCOGS,
    ROUND((SUM(s.GrossProfit) / SUM(s.GrossRevenue)) * 100, 2) AS GrossProfitMargin,
    ROUND(((SUM(s.NetRevenue) - SUM(s.COGS)) / SUM(s.NetRevenue)) * 100, 2) AS NetProfitMargin,
    ROUND(SUM(s.TaxAmount), 2) AS TotalTaxAmount,
    ROUND(SUM(s.NetRevenue), 2) AS CustomerLifetimeValue,
    ROUND(AVG(s.NetRevenue), 2) AS SalesPerCustomer,
    ROUND(SUM(s.NetRevenue) / SUM(s.Quantity), 2) AS AverageUnitPrice,
    ROUND(SUM(s.COGS) / SUM(s.Quantity), 2) AS COGSPerUnit,
    ROUND(SUM(s.TaxAmount) / SUM(s.TotalIncludingTax), 2) AS TaxRate
FROM dim_salesdata s
JOIN dimcustomer c ON s.CustomerId = c.CustomerKey
GROUP BY c.FirstName, c.LastName
    """
    
    df_metrics = spark.sql(sales_metrics_query)

\# Step 3: Check if the destination table exists in lakehouse.
    try:
        spark.read.format("delta").load(destination_lakehouse_table)
        table_exists = True
    except AnalysisException:
        table_exists = False

if not table_exists:
    print(f"Table {destination_lakehouse_table} does not exist. Creating table and writing data.")
    df_metrics.write.format("delta") \
        .option("mergeSchema", "true") \
        .option("overwriteSchema", "true") \
        .mode("overwrite") \
        .save(destination_lakehouse_table)
    print(f"Table {destination_lakehouse_table} created and data written.")
else:
    print(f"Table {destination_lakehouse_table} exists. Overwriting data and updating schema.")
    df_metrics.write.format("delta") \
        .option("mergeSchema", "true") \
        .option("overwriteSchema", "true") \
        .mode("overwrite") \
        .save(destination_lakehouse_table)
    print(f"Data overwritten in table {destination_lakehouse_table}.") 

```