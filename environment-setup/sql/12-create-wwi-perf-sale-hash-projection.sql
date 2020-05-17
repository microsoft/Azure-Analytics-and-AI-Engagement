EXECUTE AS USER = 'asa.sql.highperf'

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash_Projection]', N'U') IS NOT NULL   
DROP TABLE [wwi_perf].[Sale_Hash_Projection]


CREATE TABLE [wwi_perf].[Sale_Hash_Projection]
WITH
(
	DISTRIBUTION = HASH ( [CustomerId] ),
	HEAP
)
AS
SELECT
	[CustomerId]
	,[ProductId]
	,[Quantity]
FROM
	[wwi_perf].[Sale_Heap]
OPTION  (LABEL  = 'CTAS : Sale_Hash_Projection')