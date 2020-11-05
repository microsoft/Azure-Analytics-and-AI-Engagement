IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[Reset_ML_Environment]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[Reset_ML_Environment]
GO

CREATE PROC [dbo].[Reset_ML_Environment] AS
BEGIN

delete from FinanceSales;
delete from Customer_SalesLatest;

COPY INTO FinanceSales
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/FinanceSales.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)

COPY INTO Customer_SalesLatest
FROM 'https://asaexpdatalakecdpu.blob.core.windows.net/customcsv/Retail Scenario Dataset/Customer_SalesLatest.csv'
WITH (
	FILE_TYPE = 'CSV',
	FIRSTROW = 2 
)

END
GO

IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[Delete_SelfReferencing_Product_Recommendations]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[Delete_SelfReferencing_Product_Recommendations]
GO

CREATE PROC [dbo].[Delete_SelfReferencing_Product_Recommendations] AS
BEGIN
Delete from ProductRecommendations_Sparkv2 where ProductId = RecommendedProductId
END
GO
