-- Lets check sales table record counts.
SELECT FORMAT(COUNT_BIG(1),'#,0') as [Sales Records Count]  FROM dbo.Sales WITH (NOLOCK)

--It's in billion, lets run some complex query on billions record table.

	SELECT  
					PP.Name,Summary.ProductId,Summary.QuantitySold,Summary.ProducedQty,Summary.[Status] 
			FROM	(
			SELECT	M.ProductId,S.QuantitySold,M.ProducedQty,
					CASE WHEN S.QuantitySold > M.ProducedQty THEN 'Shortage'
					ELSE 'Over Produced' END  AS Status 
			FROM (
					SELECT SaleData.QuantitySold,SaleData.ProductId FROM (
					SELECT Sum(quantity) AS QuantitySold,SUM(GrossProfit)AS GrossProfit,
					ProductId FROM Sales WHERE  [Date]>='03/01/2019'
					GROUP BY ProductId) AS SaleData) AS S 
					INNER JOIN Vw_Mfg_batchSummary AS M ON S.ProductId= M.ProductId) AS Summary 
					INNER JOIN Product AS PP ON Summary.ProductId = PP.ProductId 

