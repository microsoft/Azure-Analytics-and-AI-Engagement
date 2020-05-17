EXECUTE AS USER = 'asa.sql.highperf'

IF OBJECT_ID(N'[wwi_perf].[Sale_Hash_Ordered]', N'U') IS NOT NULL   
DROP TABLE [wwi_perf].[Sale_Hash_Ordered] 

CREATE TABLE [wwi_perf].[Sale_Hash_Ordered]
WITH
(
    DISTRIBUTION = HASH ( [CustomerId] ),
    CLUSTERED COLUMNSTORE INDEX ORDER( [CustomerId] )
)
AS
SELECT
    *
FROM	
    [wwi_perf].[Sale_Heap]
OPTION  (LABEL  = 'CTAS : Sale_Hash_Ordered', MAXDOP 1)