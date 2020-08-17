/*  Column-level security feature in Azure Synapse simplifies the design and coding of security in application. 
    It ensures column level security by restricting column access to protect sensitive data. */

--Step 1: Let us see how this feature in Azure Synapse works. Before that let us have a look at the Campaign table. 
select  Top 100 * from Campaign_Analytics

/*  Consider a scenario where there are two users. 
    A InventoryManager, who is an authorized  personnel with access to all the information in the database 
    and a Data Analyst, to whom only required information should be presented.*/

-- Step:2 We look for the names “InventoryManager” and “SalesStaff” present in the Datawarehouse. 
SELECT Name as [User1] FROM sys.sysusers WHERE name = N'InventoryManager'
SELECT Name as [User2] FROM sys.sysusers WHERE name = N'SalesStaff'


-- Step:3 Now let us enforcing column level security for the SalesStaff. 
/*  Let us see how.
    The Campaign_Analytics table in the warehouse has information like Region, Country, Product_Category, Campaign_Name, Revenue_Target , and Revenue.
    Of all the information, Revenue generated from every campaign is a classified one and should be hidden from SalesStaff.
    To conceal this information, we execute the following query: */

GRANT SELECT ON Campaign_Analytics ([Region],[Country],[Product_Category],[Campaign_Name],[Revenue_Target],[City],[State]) TO SalesStaff;
-- This provides SalesStaff access to all the columns of the Campaign_Analytics table but Revenue.
-- Step:4 Then, to check if the security has been enforced, we execute the following query with current User As 'SalesStaff'
EXECUTE AS USER ='SalesStaff'
select * from Campaign_Analytics
---
EXECUTE AS USER ='SalesStaff'
select [Region],[Country],[Product_Category],[Campaign_Name],[Revenue_Target] from Campaign_Analytics

/*  And look at that, when the user logged in as SalesStaff tries to view all the columns from the Campaign_Analytics table, 
    he is prompted with a ‘permission denied error’ on Revenue column.*/

-- Step:5 Whereas, the InventoryManager of the company should be authorized with all the information present in the warehouse.To do so, we execute the following query.
Revert;
GRANT SELECT ON Campaign_Analytics TO InventoryManager;  --Full access to all columns.

-- Step:6 Let us check if our InventoryManager user can see all the information that is present. Assign Current User As 'InventoryManager' and the execute the query
EXECUTE AS USER ='InventoryManager'
select * from Campaign_Analytics

-------------------------------------------------------------
Revert;