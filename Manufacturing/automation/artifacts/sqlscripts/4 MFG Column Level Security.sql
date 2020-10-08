 
select  Top 100 * from Campaign_Analytics
 
SELECT Name as [User1] FROM sys.sysusers WHERE name = N'InventoryManager'
SELECT Name as [User2] FROM sys.sysusers WHERE name = N'SalesStaff'

GRANT SELECT ON Campaign_Analytics ([Region],[Country],[Product_Category],[Campaign_Name],[Revenue_Target],[City],[State]) TO SalesStaff;

EXECUTE AS USER ='SalesStaff'
select * from Campaign_Analytics

EXECUTE AS USER ='SalesStaff'
select [Region],[Country],[Product_Category],[Campaign_Name],[Revenue_Target] from Campaign_Analytics


Revert;
GRANT SELECT ON Campaign_Analytics TO InventoryManager; 

EXECUTE AS USER ='InventoryManager'
select * from Campaign_Analytics

Revert;