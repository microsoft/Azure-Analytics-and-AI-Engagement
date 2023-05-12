/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer

/*  Column-level security feature in Azure Synapse simplifies the design and coding of security in application. 
    It ensures column level security by restricting column access to protect sensitive data. */

--Step 1: Let us see how this feature in Azure Synapse works. Before that let us have a look at the Campaign_Analytics table. 
select  Top 100 * from Campaign_Analytics Where City!='Null'

/*  Consider a scenario where there are two users. 
    A VPGlobalOperations, who is an authorized  personnel with access to all the information in the database 
    and a CareManager, to whom only required information should be presented.*/

-- Step:2 We look for the names “VPGlobalOperations” and “CareManagerMiami” present in the Datawarehouse. 
SELECT Name as [User] FROM sys.sysusers WHERE name IN (N'VPGlobalOperations',N'CareManagerMiami')

-- Step:3 Now let us enforcing column level security for the CareManagerMiami. 
/*  Let us see how.
    The Campaign_Analytics table in the warehouse has information like Region, Country,Campaign_Name, Revenue_Target , and Revenue.
    Of all the information, Revenue generated from every Campaign_Analytics is a classified one and should be hidden from CareManagerMiami.
    To conceal this information, we execute the following query: */

GRANT SELECT ON Campaign_Analytics ([Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State]) TO CareManagerMiami;
-- This provides CareManagerMiami access to all the columns of the Campaign_Analytics table but Revenue.
-- Step:4 Then, to check if the security has been enforced, we execute the following query with current User As 'CareManagerMiami'
EXECUTE AS USER ='CareManagerMiami'
select * from Campaign_Analytics
---
EXECUTE AS USER ='CareManagerMiami'
select [Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State] from Campaign_Analytics

/*  And look at that, when the user logged in as CareManagerMiami tries to view all the columns from the Campaign_Analytics table, 
    he is prompted with a ‘permission denied error’ on Revenue column.*/

-- Step:5 Whereas, the VPGlobalOperations of the company should be authorized with all the information present in the warehouse.To do so, we execute the following query.
Revert;
GRANT SELECT ON Campaign_Analytics TO VPGlobalOperations;  --Full access to all columns.

-- Step:6 Let us check if our VPGlobalOperations user can see all the information that is present. Assign Current User As 'VPGlobalOperations' and the execute the query
EXECUTE AS USER ='VPGlobalOperations'
select * from Campaign_Analytics

-------------------------------------------------------------
Revert;