/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */


SELECT COUNT_BIG(1) as TotalCount  FROM dbo.Sales(nolock)


-- #ROW_NUMBER_COUNT# 
--let's execute the below query 
-- We have Data from SALES,Products,MillennialCustomers and Twitter.

select CustKey, UserName, Emailstatus, Department, [Twitter Sentiment], cast(round(TotalSale/10000,0) as int) as Revenue
from (SELECT P.Department, TA.Sentiment AS [Twitter Sentiment],
        sum(S.TotalAmount) as TotalSale,
        M.UserName, M.Emailstatus, M.CustKey
    FROM dbo.Sales as S
        inner join dbo.Products as P on P.Products_ID= S.ProductId inner join [dbo].[Dim_Customer] DC
        left outer join dbo.[TwitterAnalytics] TA on TA.[username]=DC.[userName] on DC.[id]=S.[Customerid]
        inner join dbo.[MillennialCustomers] as M on M.CustKey = S.Customerid
    where DC.[FullName]!='N/A'
    group by DC.[FullName],P.Department,TA.Sentiment,M.UserName,M.CustKey,M.Emailstatus)
  as result

