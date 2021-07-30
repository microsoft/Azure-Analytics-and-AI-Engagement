
select  Top 100 * from Campaign_Analytics;

SELECT Name as [User] FROM sys.sysusers WHERE name IN (N'HeadOfFinancialIntelligence',N'MarketingOfficerMiami')

GRANT SELECT ON Campaign_Analytics ([Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State]) TO MarketingOfficerMiami;

EXECUTE AS USER ='MarketingOfficerMiami'
select * from Campaign_Analytics

EXECUTE AS USER ='MarketingOfficerMiami'
select [Region],[Country],[Campaign_Name],[Revenue_Target],[City],[State] from Campaign_Analytics

Revert;
GRANT SELECT ON Campaign_Analytics TO HeadOfFinancialIntelligence;  --Full access to all columns.

EXECUTE AS USER ='HeadOfFinancialIntelligence'
select * from Campaign_Analytics

Revert;