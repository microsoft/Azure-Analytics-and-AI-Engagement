select  Top 100 * from Campaign_Analytics Where City!='Null'


SELECT Name as [User] FROM sys.sysusers WHERE name IN (N'VPGlobalOperations',N'CareManagerMiami')


GRANT SELECT ON Campaign_Analytics ([Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State]) TO CareManagerMiami;


EXECUTE AS USER ='CareManagerMiami'
select * from Campaign_Analytics

EXECUTE AS USER ='CareManagerMiami'
select [Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State] from Campaign_Analytics


Revert;
GRANT SELECT ON Campaign_Analytics TO VPGlobalOperations;  


EXECUTE AS USER ='VPGlobalOperations'
select * from Campaign_Analytics


Revert;