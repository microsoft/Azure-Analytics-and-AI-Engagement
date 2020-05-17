EXECUTE AS USER = 'asa.sql.highperf'

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash_Projection2]', N'U') IS NOT NULL   
DROP TABLE [wwi_perf].[Sale_Hash_Projection2] 

CREATE TABLE [wwi_perf].[Sale_Hash_Projection2]
WITH
(
	DISTRIBUTION = HASH ( [CustomerId] ),
	CLUSTERED COLUMNSTORE INDEX
)
AS
SELECT
	[CustomerId]
	,[ProductId]
	,[Quantity]
FROM
	[wwi_perf].[Sale_Heap]
OPTION  (LABEL  = 'CTAS : Sale_Hash_Projection2')