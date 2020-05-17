EXECUTE AS USER = 'asa.sql.highperf'

IF OBJECT_ID(N'[wwi_perf].[Sale_Index]', N'U') IS NOT NULL   
DROP TABLE [wwi_perf].[Sale_Index] 

CREATE TABLE [wwi_perf].[Sale_Index]
WITH
(
	DISTRIBUTION = HASH ( [CustomerId] ),
	CLUSTERED INDEX (CustomerId)
)
AS
SELECT
	*
FROM	
	[wwi_perf].[Sale_Heap]
OPTION  (LABEL  = 'CTAS : Sale_Index')
