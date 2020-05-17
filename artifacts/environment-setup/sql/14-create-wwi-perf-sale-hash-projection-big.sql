EXECUTE AS USER = 'asa.sql.highperf'

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash_Projection_Big]', N'U') IS NOT NULL   
DROP TABLE [wwi_perf].[Sale_Hash_Projection_Big] 

CREATE TABLE [wwi_perf].[Sale_Hash_Projection_Big]
WITH
(
	DISTRIBUTION = HASH ( [CustomerId] ),
	HEAP
)
AS
SELECT
	[CustomerId]
	,CAST([ProductId] as bigint) as [ProductId]
	,CAST([Quantity] as bigint) as [Quantity]
FROM
	[wwi_perf].[Sale_Heap]
OPTION  (LABEL  = 'CTAS : Sale_Hash_Projection_Big')