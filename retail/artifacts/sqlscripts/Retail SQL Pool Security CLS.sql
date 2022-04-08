select  Top 100 * from Campaign_Analytics where City is not null and state is not null

SELECT Name as [User1] FROM sys.sysusers WHERE name = N'CEO'
SELECT Name as [User2] FROM sys.sysusers WHERE name = N'DataAnalystMiami'

GRANT SELECT ON Campaign_Analytics([Region],[Country],[Product_Category],[Campaign_Name],[Revenue_Target],
[City],[State]) TO DataAnalystMiami


EXECUTE AS USER ='DataAnalystMiami'
select * from Campaign_Analytics

EXECUTE AS USER ='DataAnalystMiami'
select [Region],[Country],[Product_Category],[Campaign_Name],[Revenue_Target],
[City],[state] from Campaign_Analytics

REVERT;
GRANT SELECT ON Campaign_Analytics TO CEO

EXECUTE AS USER ='CEO'
SELECT * FROM Campaign_Analytics


