---------------

Create or Alter PROCEDURE Top10_MostValuableCustomer 
as 

    With resultdata as( 
    Select  
        coalesce(DC.FirstName,DC.MiddleName,DC.LastName) CustomerName, 
        DC.Occupation, 
        DP.ProductName, 
        Sum(Cast(FS.SalesAmount as decimal(18,2))) TotalSalesAmount 
        ,DENSE_RANK()  OVER (ORDER BY Sum(Cast(FS.SalesAmount as decimal(18,2))) desc) as  RankCol 
        From FactOnlineSales FS  
        Inner Join 
        DimProduct DP on DP.ProductKey=FS.ProductKey 
        Inner Join 
        DimCustomer DC on DC.CustomerKey=FS.CustomerKey 
        Where DC.Occupation!='' 
        Group BY coalesce(DC.FirstName,DC.MiddleName,DC.LastName), 
        DC.Occupation, 
        DP.ProductName 
        ) 
    Select  
    CustomerName,Occupation,ProductName,TotalSalesAmount,RankCol 
	From resultdata r 
	where r.RankCol between 1 and 10 
    Order by RankCol 

go   


----- View results 

Exec Top10_MostValuableCustomer