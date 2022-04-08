--∗∗∗∗∗∗∗∗∗∗ Important – Do not use in production, for demonstration purposes only – please review the legal notices before continuing ∗∗∗∗∗--
---TSQL to retrive unique products count by Brands--------

SELECT COUNT(DISTINCT ProductName) NumberOfUniqueProduct, B.BrandName,B.EntityCode
FROM ProductsList P
INNER JOIN BrandsList B ON p.EntityCode=B.EntityCode
GROUP BY B.BrandName,B.EntityCode

------------------------------------------------------
--SELECT  TOP (100) * FROM 
-- No value WideWorldImporters            [WWImporterContosoRetailLakeDB].[dbo].[Customer] where EntityCode='WideWorldImporters'

SELECT  TOP (100) * FROM WWImporterContosoCustomers where EntityCode='WideWorldImporters'
SELECT  TOP (100) * FROM WWImporterContosoCustomers where EntityCode='Contoso'


--SELECT  TOP (100) * FROM 
--CustomerGender table doesn't exist [WWImporterContosoRetailLakeDB].[dbo].[CustomerGender] where EntityCode='Contoso'

--SELECT  TOP (100) * FROM 
--CustomerGender table doesn't exist  [WWIRetailLakeDB].[dbo].[CustomerEmail] where EntityCode='WideWorldImporters'
                        
--SELECT  TOP (100) * FROM 
 --                       [WWImporterContosoRetailLakeDB].[dbo].[CustomerEmail] where EntityCode='Contoso'

-------------------------Product---------------------------------------
SELECT TOP (100) * FROM BrandsList where EntityCode='WideWorldImporters'
SELECT TOP (100) * FROM BrandsList where EntityCode='Contoso'

SELECT TOP (100) * FROM ProductsList where EntityCode='WideWorldImporters'
SELECT TOP (100) * FROM ProductsList where EntityCode='Contoso'

SELECT TOP (100) * FROM WWImportersContosoOrder where EntityCode='WideWorldImporters'
SELECT TOP (100) * FROM WWImportersContosoOrder where EntityCode='Contoso'

                        
