---TSQL to retrive unique products count by Brands--------

SELECT COUNT(DISTINCT ProductName) NumberOfUniqueProduct, B.BrandName,B.EntityCode
FROM WWImportersContosoProduct P
INNER JOIN WWImportersContosoBrands B ON p.EntityCode=B.EntityCode
GROUP BY B.BrandName,B.EntityCode

------------------------------------------------------
SELECT  TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[Customer] where EntityCode='WideWorldImporters'
SELECT  TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[Customer] where EntityCode='Contoso'

SELECT  TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[CustomerGender] where EntityCode='WideWorldImporters'

SELECT  TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[CustomerGender] where EntityCode='Contoso'

SELECT  TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[CustomerEmail] where EntityCode='WideWorldImporters'
                        
SELECT  TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[CustomerEmail] where EntityCode='Contoso'

-------------------------Product---------------------------------------
SELECT TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[Brand] where EntityCode='WideWorldImporters'
SELECT TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[Brand] where EntityCode='Contoso'

SELECT TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[Product] where EntityCode='WideWorldImporters'
SELECT TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[Product] where EntityCode='Contoso'

                        
SELECT TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[Order]  where EntityCode='WideWorldImporters'
 SELECT TOP (100) * FROM 
                        [WWIRetailLakeDB].[dbo].[Order] where EntityCode='Contoso'

                        
