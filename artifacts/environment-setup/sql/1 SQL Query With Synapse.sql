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

