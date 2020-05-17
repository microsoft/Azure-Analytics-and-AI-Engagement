EXECUTE AS USER = 'asa.sql.highperf'

IF OBJECT_ID(N'[wwi_perf].[Sale_Heap]', N'U') IS NOT NULL   
DROP TABLE [wwi_perf].[Sale_Heap]  

CREATE TABLE [wwi_perf].[Sale_Heap]
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
AS
SELECT
	*
FROM	
	[wwi].[SaleSmall]
WHERE
	TransactionDateId >= 20190101
OPTION  (LABEL  = 'CTAS : Sale_Heap')