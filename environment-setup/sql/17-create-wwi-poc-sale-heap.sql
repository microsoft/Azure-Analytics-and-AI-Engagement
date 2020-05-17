EXECUTE AS USER = 'asa.sql.highperf'

IF OBJECT_ID(N'[wwi_poc].[Sale]', N'U') IS NOT NULL   
DROP TABLE [wwi_poc].[Sale]  

CREATE TABLE [wwi_poc].[Sale]
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
    TransactionDateId < 20170501
    AND TransactionDateId >= 20140101
OPTION  (LABEL  = 'CTAS : wwi_poc.Sale')
