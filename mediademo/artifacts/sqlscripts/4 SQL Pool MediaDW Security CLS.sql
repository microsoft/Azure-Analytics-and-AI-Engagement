/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/*

select  Top 100 * from Campaign_Analytics Where City!='Null'

SELECT Name as [User] FROM sys.sysusers WHERE name IN (N'MediaAdministrator',N'ReporterMiami')

GRANT SELECT ON Campaign_Analytics ([Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State]) TO ReporterMiami;

EXECUTE AS USER ='ReporterMiami'
select * from Campaign_Analytics

EXECUTE AS USER ='ReporterMiami'
select [Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State] from Campaign_Analytics

Revert;
GRANT SELECT ON Campaign_Analytics TO MediaAdministrator; 

EXECUTE AS USER ='MediaAdministrator'
select * from Campaign_Analytics

Revert;