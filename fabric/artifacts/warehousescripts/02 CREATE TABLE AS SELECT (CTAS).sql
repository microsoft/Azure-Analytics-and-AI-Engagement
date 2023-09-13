/*CREATE TABLE AS SELECT (CTAS) 
CTAS is a parallel operation that creates a new table based on the output of a SELECT statement.  
CTAS is the simplest and fastest way to create and insert data into a table with a single command.***/ 

 
 
--------Drop Table FactSales_new if exists
DROP Table  IF EXISTS [dbo].[FactSales_new] 
SELECT top 100 * 
INTO    [dbo].[FactSales_new] 
FROM    [dbo].[FactSales] 