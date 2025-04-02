## Task 2.1

``` SELECT * FROM dimcustomer```

``` SELECT TOP(10) ```

## Task 2.2

```
SELECT d.CalendarYear, SUM(f.SalesAmount) AS TotalSalesAmount
FROM dbo.factinternetsales f
JOIN dbo.dimdate d ON f.OrderDateKey = d.DateKey
GROUP BY d.CalYear
ORDER BY d.CalendarYear;

```

