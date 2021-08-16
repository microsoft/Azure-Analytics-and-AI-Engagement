/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

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

